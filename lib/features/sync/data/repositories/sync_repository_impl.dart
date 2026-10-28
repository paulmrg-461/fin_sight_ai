import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/sync/sync_operation.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/app_env.dart';
import '../../../../core/utils/clock.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../budgets/data/datasources/budget_local_data_source.dart';
import '../../../categories/data/datasources/category_local_data_source.dart';
import '../../../categories/data/models/category_model.dart';
import '../../../budgets/data/models/budget_model.dart';
import '../../../debts/data/datasources/debt_local_data_source.dart';
import '../../../debts/data/models/debt_model.dart';
import '../../../ocr/data/datasources/receipt_local_data_source.dart';
import '../../../ocr/data/models/receipt_model.dart';
import '../../../receivables/data/datasources/receivable_local_data_source.dart';
import '../../../receivables/data/models/receivable_model.dart';
import '../../../savings/data/datasources/savings_local_data_source.dart';
import '../../../savings/data/models/savings_goal_model.dart';
import '../../../scheduled_payments/data/datasources/scheduled_payment_local_data_source.dart';
import '../../../scheduled_payments/data/models/scheduled_payment_model.dart';
import '../../../transactions/data/datasources/transaction_local_data_source.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../wallets/data/datasources/wallet_local_data_source.dart';
import '../../../wallets/data/models/wallet_model.dart';
import '../../domain/entities/sync_entities.dart';
import '../../domain/repositories/sync_repository.dart';
import '../datasources/sync_local_data_source.dart';
import '../datasources/sync_remote_data_source.dart';

/// Pushes queued changes, pulls remote updates, and resolves conflicts.
@LazySingleton(as: SyncRepository)
class SyncRepositoryImpl implements SyncRepository {
  const SyncRepositoryImpl(
    this._localDataSource,
    this._remoteDataSource,
    this._transactionLocalDataSource,
    this._debtLocalDataSource,
    this._budgetLocalDataSource,
    this._receivableLocalDataSource,
    this._categoryLocalDataSource,
    this._scheduledPaymentLocalDataSource,
    this._walletLocalDataSource,
    this._savingsGoalLocalDataSource,
    this._receiptLocalDataSource,
    this._env,
    this._auth, {
    this.clock = const Clock(),
  });

  static final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(
    0,
    isUtc: true,
  );

  final SyncLocalDataSource _localDataSource;
  final SyncRemoteDataSource _remoteDataSource;
  final TransactionLocalDataSource _transactionLocalDataSource;
  final DebtLocalDataSource _debtLocalDataSource;
  final BudgetLocalDataSource _budgetLocalDataSource;
  final ReceivableLocalDataSource _receivableLocalDataSource;
  final CategoryLocalDataSource _categoryLocalDataSource;
  final ScheduledPaymentLocalDataSource _scheduledPaymentLocalDataSource;
  final WalletLocalDataSource _walletLocalDataSource;
  final SavingsLocalDataSource _savingsGoalLocalDataSource;
  final ReceiptLocalDataSource _receiptLocalDataSource;
  final AppEnv _env;
  final AuthRepository _auth;
  final Clock clock;

  @override
  ResultFuture<SyncStatusEntity> getStatus() async {
    try {
      return Right(
        SyncStatusEntity(
          pendingCount: await _localDataSource.pendingCount(),
          isConfigured: _env.hasSupabase,
          isAuthenticated: _auth.isAuthenticated,
          lastSyncedAt: await _localDataSource.lastSyncedAt(),
        ),
      );
    } on CacheException catch (exception) {
      return Left(_cacheFailure(exception));
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to read synchronization status.',
          code: 'sync_status_failed',
        ),
      );
    }
  }

  @override
  ResultFuture<SyncReport> syncNow() async {
    try {
      final allPending = await _localDataSource.pending();
      final now = clock.now();
      final pending = allPending
          .where(
            (operation) =>
                operation.nextAttemptAt == null ||
                !operation.nextAttemptAt!.isAfter(now),
          )
          .toList(growable: false);

      if (_env.hasSupabase && !_auth.isAuthenticated) {
        await _auth.restoreSession();
      }

      if (!_env.hasSupabase || !_auth.isAuthenticated) {
        return Right(
          SyncReport(
            pushed: 0,
            pulled: 0,
            conflictsResolved: 0,
            pendingOperations: allPending.length,
            isConfigured: _env.hasSupabase,
            isAuthenticated: _auth.isAuthenticated,
            completedAt: now,
          ),
        );
      }

      var pushed = 0;
      var conflicts = 0;
      var failed = 0;
      var discarded = 0;
      final failures = <SyncEntityFailure>[];

      for (final operation in pending) {
        try {
          final conflict = await _push(operation);
          await _localDataSource.remove(operation.id);
          if (conflict) {
            conflicts++;
          } else {
            pushed++;
          }
        } on ServerException catch (exception) {
          await _requeue(operation);
          failed++;
          failures.add(
            SyncEntityFailure(
              entityType: operation.entityType,
              code: exception.code ?? 'sync_push_failed',
              message: exception.message,
            ),
          );
        } on FormatException {
          // Irrecoverable payload: remove it so it cannot poison every pass.
          await _localDataSource.remove(operation.id);
          discarded++;
        }
      }

      final pull = await _pull();
      await _purgeTombstones();
      final watermark = pull.watermark;
      if (watermark != null) {
        await _localDataSource.setLastSyncedAt(watermark);
      }

      return Right(
        SyncReport(
          pushed: pushed,
          pulled: pull.merged,
          conflictsResolved: conflicts,
          pendingOperations: await _localDataSource.pendingCount(),
          failed: failed,
          discarded: discarded,
          failures: [...failures, ...pull.failures],
          isConfigured: true,
          isAuthenticated: true,
          completedAt: clock.now(),
        ),
      );
    } on ServerException catch (exception) {
      final message = switch (exception.code) {
        'supabase_http_404' => 'The cloud schema is out of date. Apply the latest Supabase migrations and retry.',
        'supabase_http_401' || 'supabase_http_403' =>
          'The cloud rejected this session. Sign in again and retry.',
        _ => 'Synchronization failed. Pending changes were kept.',
      };
      return Left(ServerFailure(message, code: exception.code));
    } on CacheException catch (exception) {
      return Left(_cacheFailure(exception));
    } on FormatException {
      return const Left(
        ServerFailure(
          'Synchronization received invalid data.',
          code: 'sync_invalid_payload',
        ),
      );
    } catch (_) {
      return const Left(
        ServerFailure('Synchronization failed.', code: 'sync_failed'),
      );
    }
  }

  Future<bool> _push(SyncOperation operation) {
    return switch (operation.entityType) {
      SyncEntityType.category => _pushCategory(operation),
      SyncEntityType.scheduledPayment => _pushScheduledPayment(operation),
      SyncEntityType.wallet => _pushWallet(operation),
      SyncEntityType.walletTransfer => _pushWalletTransfer(operation),
      SyncEntityType.savingsGoal => _pushSavingsGoal(operation),
      SyncEntityType.transaction => _pushTransaction(operation),
      SyncEntityType.debt => _pushDebt(operation),
      SyncEntityType.budget => _pushBudget(operation),
      SyncEntityType.receivable => _pushReceivable(operation),
      SyncEntityType.receipt => _pushReceipt(operation),
    };
  }

  Future<bool> _pushCategory(SyncOperation operation) async {
    if (operation.operationType == SyncOperationType.delete) {
      return false;
    }

    final remoteRow = await _remoteDataSource.fetchCategory(operation.entityId);
    if (remoteRow != null) {
      final remote = CategoryModel.fromJson(remoteRow);
      if (remote.lastModified.isAfter(_payloadUpdatedAt(operation.payload))) {
        await _categoryLocalDataSource.saveCategory(
          CategoryModel.fromEntity(remote.copyWith(isSynced: true)),
        );
        return true;
      }
    }

    await _remoteDataSource.upsertCategory(operation.payload);
    final local = CategoryModel.fromJson(operation.payload);
    await _categoryLocalDataSource.saveCategory(
      CategoryModel.fromEntity(local.copyWith(isSynced: true)),
    );
    return false;
  }

  Future<bool> _pushScheduledPayment(SyncOperation operation) async {
    if (operation.operationType == SyncOperationType.delete) {
      return false;
    }

    final remoteRow = await _remoteDataSource.fetchScheduledPayment(
      operation.entityId,
    );
    if (remoteRow != null) {
      final remote = ScheduledPaymentModel.fromJson(remoteRow);
      if (remote.lastModified.isAfter(_payloadUpdatedAt(operation.payload))) {
        await _scheduledPaymentLocalDataSource.savePayment(
          ScheduledPaymentModel.fromEntity(remote.copyWith(isSynced: true)),
        );
        return true;
      }
    }

    await _remoteDataSource.upsertScheduledPayment(operation.payload);
    final local = ScheduledPaymentModel.fromJson(operation.payload);
    await _scheduledPaymentLocalDataSource.savePayment(
      ScheduledPaymentModel.fromEntity(local.copyWith(isSynced: true)),
    );
    return false;
  }

  Future<bool> _pushWallet(SyncOperation operation) async {
    if (operation.operationType == SyncOperationType.delete) {
      return false;
    }

    final remoteRow = await _remoteDataSource.fetchWallet(operation.entityId);
    if (remoteRow != null) {
      final remote = WalletModel.fromJson(remoteRow);
      if (remote.lastModified.isAfter(_payloadUpdatedAt(operation.payload))) {
        await _walletLocalDataSource.saveWallet(
          WalletModel.fromEntity(remote.copyWith(isSynced: true)),
        );
        return true;
      }
    }

    await _remoteDataSource.upsertWallet(operation.payload);
    final local = WalletModel.fromJson(operation.payload);
    await _walletLocalDataSource.saveWallet(
      WalletModel.fromEntity(local.copyWith(isSynced: true)),
    );
    return false;
  }

  Future<bool> _pushWalletTransfer(SyncOperation operation) async {
    if (operation.operationType == SyncOperationType.delete) {
      return false;
    }

    final remoteRow = await _remoteDataSource.fetchWalletTransfer(
      operation.entityId,
    );
    if (remoteRow != null) {
      final remote = WalletTransferModel.fromJson(remoteRow);
      if (remote.lastModified.isAfter(_payloadUpdatedAt(operation.payload))) {
        await _walletLocalDataSource.saveTransfer(
          WalletTransferModel.fromEntity(remote.copyWith(isSynced: true)),
        );
        return true;
      }
    }

    await _remoteDataSource.upsertWalletTransfer(operation.payload);
    final local = WalletTransferModel.fromJson(operation.payload);
    await _walletLocalDataSource.saveTransfer(
      WalletTransferModel.fromEntity(local.copyWith(isSynced: true)),
    );
    return false;
  }

  Future<bool> _pushSavingsGoal(SyncOperation operation) async {
    if (operation.operationType == SyncOperationType.delete) {
      return false;
    }

    final remoteRow = await _remoteDataSource.fetchSavingsGoal(
      operation.entityId,
    );
    if (remoteRow != null) {
      final remote = SavingsGoalModel.fromJson(remoteRow);
      if (remote.lastModified.isAfter(_payloadUpdatedAt(operation.payload))) {
        await _savingsGoalLocalDataSource.saveGoal(
          SavingsGoalModel.fromEntity(remote.copyWith(isSynced: true)),
        );
        return true;
      }
    }

    await _remoteDataSource.upsertSavingsGoal(operation.payload);
    final local = SavingsGoalModel.fromJson(operation.payload);
    await _savingsGoalLocalDataSource.saveGoal(
      SavingsGoalModel.fromEntity(local.copyWith(isSynced: true)),
    );
    return false;
  }

  Future<bool> _pushTransaction(SyncOperation operation) async {
    if (operation.operationType == SyncOperationType.delete) {
      await _remoteDataSource.deleteTransaction(operation.entityId);
      return false;
    }

    final remoteRow = await _remoteDataSource.fetchTransaction(
      operation.entityId,
    );
    if (remoteRow != null) {
      final remote = TransactionModel.fromJson(remoteRow);
      if (remote.lastModified.isAfter(_payloadUpdatedAt(operation.payload))) {
        await _transactionLocalDataSource.saveTransaction(
          TransactionModel.fromEntity(remote.copyWith(isSynced: true)),
        );
        return true;
      }
    }

    await _remoteDataSource.upsertTransaction(operation.payload);
    final local = TransactionModel.fromJson(operation.payload);
    await _transactionLocalDataSource.saveTransaction(
      TransactionModel.fromEntity(local.copyWith(isSynced: true)),
    );
    return false;
  }

  Future<bool> _pushDebt(SyncOperation operation) async {
    if (operation.operationType == SyncOperationType.delete) {
      await _remoteDataSource.deleteDebt(operation.entityId);
      return false;
    }

    final remoteRow = await _remoteDataSource.fetchDebt(operation.entityId);
    if (remoteRow != null) {
      final remote = DebtModel.fromJson(remoteRow);
      if (remote.lastModified.isAfter(_payloadUpdatedAt(operation.payload))) {
        await _debtLocalDataSource.saveDebt(
          DebtModel.fromEntity(remote.copyWith(isSynced: true)),
        );
        return true;
      }
    }

    await _remoteDataSource.upsertDebt(operation.payload);
    final local = DebtModel.fromJson(operation.payload);
    await _debtLocalDataSource.saveDebt(
      DebtModel.fromEntity(local.copyWith(isSynced: true)),
    );
    return false;
  }

  Future<bool> _pushBudget(SyncOperation operation) async {
    if (operation.operationType == SyncOperationType.delete) {
      await _remoteDataSource.deleteBudget(operation.entityId);
      return false;
    }

    final remoteRow = await _remoteDataSource.fetchBudget(operation.entityId);
    if (remoteRow != null) {
      final remote = BudgetModel.fromJson(remoteRow);
      if (remote.lastModified.isAfter(_payloadUpdatedAt(operation.payload))) {
        await _budgetLocalDataSource.saveBudget(
          BudgetModel.fromEntity(remote.copyWith(isSynced: true)),
        );
        return true;
      }
    }

    await _remoteDataSource.upsertBudget(operation.payload);
    final local = BudgetModel.fromJson(operation.payload);
    await _budgetLocalDataSource.saveBudget(
      BudgetModel.fromEntity(local.copyWith(isSynced: true)),
    );
    return false;
  }

  Future<bool> _pushReceivable(SyncOperation operation) async {
    if (operation.operationType == SyncOperationType.delete) {
      await _remoteDataSource.deleteReceivable(operation.entityId);
      return false;
    }

    final remoteRow = await _remoteDataSource.fetchReceivable(
      operation.entityId,
    );
    if (remoteRow != null) {
      final remote = ReceivableModel.fromJson(remoteRow);
      if (remote.lastModified.isAfter(_payloadUpdatedAt(operation.payload))) {
        await _receivableLocalDataSource.saveReceivable(
          ReceivableModel.fromEntity(remote.copyWith(isSynced: true)),
        );
        return true;
      }
    }

    await _remoteDataSource.upsertReceivable(operation.payload);
    final local = ReceivableModel.fromJson(operation.payload);
    await _receivableLocalDataSource.saveReceivable(
      ReceivableModel.fromEntity(local.copyWith(isSynced: true)),
    );
    return false;
  }

  Future<bool> _pushReceipt(SyncOperation operation) async {
    if (operation.operationType == SyncOperationType.delete) {
      return false;
    }

    final remoteRow = await _remoteDataSource.fetchReceipt(operation.entityId);
    if (remoteRow != null) {
      final remote = ReceiptModel.fromJson(remoteRow);
      if (remote.lastModified.isAfter(_payloadUpdatedAt(operation.payload))) {
        await _receiptLocalDataSource.saveReceipt(
          ReceiptModel.fromEntity(remote.copyWith(isSynced: true)),
        );
        return true;
      }
    }

    await _remoteDataSource.upsertReceipt(operation.payload);
    final local = ReceiptModel.fromJson(operation.payload);
    await _receiptLocalDataSource.saveReceipt(
      ReceiptModel.fromEntity(local.copyWith(isSynced: true)),
    );
    return false;
  }

  Future<_PullResult> _pull() async {
    final lastSyncedAt = await _localDataSource.lastSyncedAt();
    var pulled = 0;
    DateTime? watermark;
    final failures = <SyncEntityFailure>[];

    // Each entity is isolated: a missing table or bad payload must not stop the
    // rest of the pass. Definitions still come before the ledger.
    Future<void> pullEntity({
      required SyncEntityType entityType,
      required Future<List<Map<String, dynamic>>> Function(int, int) fetch,
      required Future<int> Function(List<Map<String, dynamic>>) merge,
    }) async {
      try {
        final rows = await _fetchAll(fetch);
        pulled += await merge(rows);
        watermark = _maxUpdatedAt(rows, watermark);
      } on ServerException catch (exception) {
        failures.add(
          SyncEntityFailure(
            entityType: entityType,
            code: exception.code ?? 'sync_pull_failed',
            message: exception.message,
          ),
        );
      } on CacheException catch (exception) {
        failures.add(
          SyncEntityFailure(
            entityType: entityType,
            code: exception.code ?? 'cache_error',
            message: exception.message,
          ),
        );
      } on FormatException {
        failures.add(
          SyncEntityFailure(
            entityType: entityType,
            code: 'invalid_payload',
            message: 'The server returned an invalid row.',
          ),
        );
      }
    }

    await pullEntity(
      entityType: SyncEntityType.category,
      fetch: (limit, offset) => _remoteDataSource.fetchCategories(
        updatedAfter: lastSyncedAt,
        limit: limit,
        offset: offset,
      ),
      merge: _mergeCategories,
    );
    await pullEntity(
      entityType: SyncEntityType.scheduledPayment,
      fetch: (limit, offset) => _remoteDataSource.fetchScheduledPayments(
        updatedAfter: lastSyncedAt,
        limit: limit,
        offset: offset,
      ),
      merge: _mergeScheduledPayments,
    );
    await pullEntity(
      entityType: SyncEntityType.wallet,
      fetch: (limit, offset) => _remoteDataSource.fetchWallets(
        updatedAfter: lastSyncedAt,
        limit: limit,
        offset: offset,
      ),
      merge: _mergeWallets,
    );
    await pullEntity(
      entityType: SyncEntityType.walletTransfer,
      fetch: (limit, offset) => _remoteDataSource.fetchWalletTransfers(
        updatedAfter: lastSyncedAt,
        limit: limit,
        offset: offset,
      ),
      merge: _mergeWalletTransfers,
    );
    await pullEntity(
      entityType: SyncEntityType.savingsGoal,
      fetch: (limit, offset) => _remoteDataSource.fetchSavingsGoals(
        updatedAfter: lastSyncedAt,
        limit: limit,
        offset: offset,
      ),
      merge: _mergeSavingsGoals,
    );
    await pullEntity(
      entityType: SyncEntityType.transaction,
      fetch: (limit, offset) => _remoteDataSource.fetchTransactions(
        updatedAfter: lastSyncedAt,
        limit: limit,
        offset: offset,
      ),
      merge: _mergeTransactions,
    );
    await pullEntity(
      entityType: SyncEntityType.debt,
      fetch: (limit, offset) => _remoteDataSource.fetchDebts(
        updatedAfter: lastSyncedAt,
        limit: limit,
        offset: offset,
      ),
      merge: _mergeDebts,
    );
    await pullEntity(
      entityType: SyncEntityType.budget,
      fetch: (limit, offset) => _remoteDataSource.fetchBudgets(
        updatedAfter: lastSyncedAt,
        limit: limit,
        offset: offset,
      ),
      merge: _mergeBudgets,
    );
    await pullEntity(
      entityType: SyncEntityType.receivable,
      fetch: (limit, offset) => _remoteDataSource.fetchReceivables(
        updatedAfter: lastSyncedAt,
        limit: limit,
        offset: offset,
      ),
      merge: _mergeReceivables,
    );
    await pullEntity(
      entityType: SyncEntityType.receipt,
      fetch: (limit, offset) => _remoteDataSource.fetchReceipts(
        updatedAfter: lastSyncedAt,
        limit: limit,
        offset: offset,
      ),
      merge: _mergeReceipts,
    );

    return _PullResult(
      merged: pulled,
      watermark: watermark,
      failures: failures,
    );
  }

  static const int _pageSize = 500;
  static const int _maxPagesPerEntity = 100;

  Future<List<Map<String, dynamic>>> _fetchAll(
    Future<List<Map<String, dynamic>>> Function(int limit, int offset) fetch,
  ) async {
    final rows = <Map<String, dynamic>>[];
    var offset = 0;
    for (var page = 0; page < _maxPagesPerEntity; page++) {
      final pageRows = await fetch(_pageSize, offset);
      rows.addAll(pageRows);
      if (pageRows.length < _pageSize) {
        break;
      }
      offset += _pageSize;
    }
    return rows;
  }

  DateTime? _maxUpdatedAt(List<Map<String, dynamic>> rows, DateTime? current) {
    var max = current;
    for (final row in rows) {
      final raw = row['updatedAt'];
      if (raw is! String) {
        continue;
      }
      final parsed = DateTime.tryParse(raw);
      if (parsed != null && (max == null || parsed.isAfter(max))) {
        max = parsed;
      }
    }
    return max;
  }

  Future<int> _mergeCategories(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) {
      return 0;
    }

    final localModels = await _categoryLocalDataSource.getAllCategories();
    final byId = <String, CategoryModel>{
      for (final model in localModels) model.id: model,
    };
    var pulled = 0;

    for (final row in rows) {
      final remote = CategoryModel.fromJson(row);
      final local = byId[remote.id];
      if (local == null || remote.lastModified.isAfter(local.lastModified)) {
        await _categoryLocalDataSource.saveCategory(
          CategoryModel.fromEntity(remote.copyWith(isSynced: true)),
        );
        pulled++;
      }
    }
    return pulled;
  }

  Future<int> _mergeScheduledPayments(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) {
      return 0;
    }

    final localModels = await _scheduledPaymentLocalDataSource.getAllPayments();
    final byId = <String, ScheduledPaymentModel>{
      for (final model in localModels) model.id: model,
    };
    var pulled = 0;

    for (final row in rows) {
      final remote = ScheduledPaymentModel.fromJson(row);
      final local = byId[remote.id];
      if (local == null || remote.lastModified.isAfter(local.lastModified)) {
        await _scheduledPaymentLocalDataSource.savePayment(
          ScheduledPaymentModel.fromEntity(remote.copyWith(isSynced: true)),
        );
        pulled++;
      }
    }
    return pulled;
  }

  Future<int> _mergeWallets(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) {
      return 0;
    }

    final localModels = await _walletLocalDataSource.getAllWallets();
    final byId = <String, WalletModel>{
      for (final model in localModels) model.id: model,
    };
    var pulled = 0;

    for (final row in rows) {
      final remote = WalletModel.fromJson(row);
      final local = byId[remote.id];
      if (local == null || remote.lastModified.isAfter(local.lastModified)) {
        await _walletLocalDataSource.saveWallet(
          WalletModel.fromEntity(remote.copyWith(isSynced: true)),
        );
        pulled++;
      }
    }
    return pulled;
  }

  Future<int> _mergeWalletTransfers(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) {
      return 0;
    }

    final localModels = await _walletLocalDataSource.getAllTransfers();
    final byId = <String, WalletTransferModel>{
      for (final model in localModels) model.id: model,
    };
    var pulled = 0;

    for (final row in rows) {
      final remote = WalletTransferModel.fromJson(row);
      final local = byId[remote.id];
      if (local == null || remote.lastModified.isAfter(local.lastModified)) {
        await _walletLocalDataSource.saveTransfer(
          WalletTransferModel.fromEntity(remote.copyWith(isSynced: true)),
        );
        pulled++;
      }
    }
    return pulled;
  }

  Future<int> _mergeSavingsGoals(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) {
      return 0;
    }

    final localModels = await _savingsGoalLocalDataSource.getAllGoals();
    final byId = <String, SavingsGoalModel>{
      for (final model in localModels) model.id: model,
    };
    var pulled = 0;

    for (final row in rows) {
      final remote = SavingsGoalModel.fromJson(row);
      final local = byId[remote.id];
      if (local == null || remote.lastModified.isAfter(local.lastModified)) {
        await _savingsGoalLocalDataSource.saveGoal(
          SavingsGoalModel.fromEntity(remote.copyWith(isSynced: true)),
        );
        pulled++;
      }
    }
    return pulled;
  }

  Future<int> _mergeTransactions(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) {
      return 0;
    }

    final localModels = await _transactionLocalDataSource.getAllTransactions();
    final byId = <String, TransactionModel>{
      for (final model in localModels) model.id: model,
    };
    var pulled = 0;

    for (final row in rows) {
      final remote = TransactionModel.fromJson(row);
      final local = byId[remote.id];
      if (local == null || remote.lastModified.isAfter(local.lastModified)) {
        await _transactionLocalDataSource.saveTransaction(
          TransactionModel.fromEntity(remote.copyWith(isSynced: true)),
        );
        pulled++;
      }
    }
    return pulled;
  }

  Future<int> _mergeDebts(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) {
      return 0;
    }

    final localModels = await _debtLocalDataSource.getAllDebts();
    final byId = <String, DebtModel>{
      for (final model in localModels) model.id: model,
    };
    var pulled = 0;

    for (final row in rows) {
      final remote = DebtModel.fromJson(row);
      final local = byId[remote.id];
      if (local == null || remote.lastModified.isAfter(local.lastModified)) {
        await _debtLocalDataSource.saveDebt(
          DebtModel.fromEntity(remote.copyWith(isSynced: true)),
        );
        pulled++;
      }
    }
    return pulled;
  }

  Future<int> _mergeBudgets(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) {
      return 0;
    }

    final localModels = await _budgetLocalDataSource
        .getAllBudgetsIncludingDeleted();
    final byId = <String, BudgetModel>{
      for (final model in localModels) model.id: model,
    };
    var pulled = 0;

    for (final row in rows) {
      final remote = BudgetModel.fromJson(row);
      final local = byId[remote.id];
      if (local == null || remote.lastModified.isAfter(local.lastModified)) {
        await _budgetLocalDataSource.saveBudget(
          BudgetModel.fromEntity(remote.copyWith(isSynced: true)),
        );
        pulled++;
      }
    }
    return pulled;
  }

  Future<int> _mergeReceivables(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) {
      return 0;
    }

    final localModels = await _receivableLocalDataSource.getReceivables();
    final byId = <String, ReceivableModel>{
      for (final model in localModels) model.id: model,
    };
    var pulled = 0;

    for (final row in rows) {
      final remote = ReceivableModel.fromJson(row);
      final local = byId[remote.id];
      if (local == null || remote.lastModified.isAfter(local.lastModified)) {
        await _receivableLocalDataSource.saveReceivable(
          ReceivableModel.fromEntity(remote.copyWith(isSynced: true)),
        );
        pulled++;
      }
    }
    return pulled;
  }

  Future<int> _mergeReceipts(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) {
      return 0;
    }

    final localModels = await _receiptLocalDataSource.getReceipts();
    final byId = <String, ReceiptModel>{
      for (final model in localModels) model.id: model,
    };
    var pulled = 0;

    for (final row in rows) {
      final remote = ReceiptModel.fromJson(row);
      final local = byId[remote.id];
      if (local == null || remote.lastModified.isAfter(local.lastModified)) {
        await _receiptLocalDataSource.saveReceipt(
          ReceiptModel.fromEntity(remote.copyWith(isSynced: true)),
        );
        pulled++;
      }
    }
    return pulled;
  }

  DateTime _payloadUpdatedAt(Map<String, dynamic> payload) {
    final raw = payload['updatedAt'];
    if (raw is String) {
      return DateTime.tryParse(raw) ?? _epoch;
    }
    return _epoch;
  }

  Future<void> _purgeTombstones() async {
    final cutoff = clock.now().subtract(const Duration(days: 30));
    try {
      await _categoryLocalDataSource.purgeTombstones(cutoff);
      await _scheduledPaymentLocalDataSource.purgeTombstones(cutoff);
      await _walletLocalDataSource.purgeTombstones(cutoff);
      await _savingsGoalLocalDataSource.purgeTombstones(cutoff);
      await _transactionLocalDataSource.purgeTombstones(cutoff);
      await _debtLocalDataSource.purgeTombstones(cutoff);
      await _budgetLocalDataSource.purgeTombstones(cutoff);
      await _receivableLocalDataSource.purgeTombstones(cutoff);
    } catch (_) {
      // Cleanup is best effort and must not fail the sync pass.
    }
  }

  Future<void> _requeue(SyncOperation operation) async {
    try {
      final attempts = operation.attempts + 1;
      final backoffSeconds = (1 << attempts.clamp(0, 10)).clamp(1, 3600);
      await _localDataSource.enqueue(
        operation.copyWith(
          attempts: attempts,
          nextAttemptAt: clock.now().add(Duration(seconds: backoffSeconds)),
        ),
      );
    } catch (_) {
      // Keep the original queued operation if the counter cannot be updated.
    }
  }

  CacheFailure _cacheFailure(CacheException exception) =>
      CacheFailure(exception.message, code: exception.code);
}

class _PullResult {
  const _PullResult({
    required this.merged,
    this.watermark,
    this.failures = const [],
  });

  final int merged;
  final DateTime? watermark;
  final List<SyncEntityFailure> failures;
}
