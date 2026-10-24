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
import '../../../budgets/data/models/budget_model.dart';
import '../../../debts/data/datasources/debt_local_data_source.dart';
import '../../../debts/data/models/debt_model.dart';
import '../../../receivables/data/datasources/receivable_local_data_source.dart';
import '../../../receivables/data/models/receivable_model.dart';
import '../../../transactions/data/datasources/transaction_local_data_source.dart';
import '../../../transactions/data/models/transaction_model.dart';
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

      for (final operation in pending) {
        try {
          final conflict = await _push(operation);
          await _localDataSource.remove(operation.id);
          if (conflict) {
            conflicts++;
          } else {
            pushed++;
          }
        } on ServerException {
          await _requeue(operation);
          rethrow;
        }
      }

      final pulled = await _pull();
      await _purgeTombstones();
      await _localDataSource.setLastSyncedAt(clock.now());

      return Right(
        SyncReport(
          pushed: pushed,
          pulled: pulled,
          conflictsResolved: conflicts,
          pendingOperations: await _localDataSource.pendingCount(),
          isConfigured: true,
          isAuthenticated: true,
          completedAt: clock.now(),
        ),
      );
    } on ServerException catch (exception) {
      return Left(
        ServerFailure(
          'Synchronization failed. Pending changes were kept.',
          code: exception.code,
        ),
      );
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
      SyncEntityType.transaction => _pushTransaction(operation),
      SyncEntityType.debt => _pushDebt(operation),
      SyncEntityType.budget => _pushBudget(operation),
      SyncEntityType.receivable => _pushReceivable(operation),
    };
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

  Future<int> _pull() async {
    final lastSyncedAt = await _localDataSource.lastSyncedAt();
    var pulled = 0;

    final transactions = await _remoteDataSource.fetchTransactions(
      updatedAfter: lastSyncedAt,
    );
    pulled += await _mergeTransactions(transactions);

    final debts = await _remoteDataSource.fetchDebts(
      updatedAfter: lastSyncedAt,
    );
    pulled += await _mergeDebts(debts);

    final budgets = await _remoteDataSource.fetchBudgets(
      updatedAfter: lastSyncedAt,
    );
    pulled += await _mergeBudgets(budgets);

    final receivables = await _remoteDataSource.fetchReceivables(
      updatedAfter: lastSyncedAt,
    );
    pulled += await _mergeReceivables(receivables);

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
