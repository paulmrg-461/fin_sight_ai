import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/core/sync/sync_operation.dart';
import 'package:fin_sight_ai/core/utils/app_env.dart';
import 'package:fin_sight_ai/core/utils/clock.dart';
import 'package:fpdart/fpdart.dart';
import 'package:fin_sight_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:fin_sight_ai/features/budgets/data/datasources/budget_local_data_source.dart';
import 'package:fin_sight_ai/features/categories/data/datasources/category_local_data_source.dart';
import 'package:fin_sight_ai/features/categories/data/models/category_model.dart';
import 'package:fin_sight_ai/features/budgets/data/models/budget_model.dart';
import 'package:fin_sight_ai/features/debts/data/datasources/debt_local_data_source.dart';
import 'package:fin_sight_ai/features/debts/data/models/debt_model.dart';
import 'package:fin_sight_ai/features/receivables/data/datasources/receivable_local_data_source.dart';
import 'package:fin_sight_ai/features/receivables/data/models/receivable_model.dart';
import 'package:fin_sight_ai/features/scheduled_payments/data/datasources/scheduled_payment_local_data_source.dart';
import 'package:fin_sight_ai/features/scheduled_payments/data/models/scheduled_payment_model.dart';
import 'package:fin_sight_ai/features/scheduled_payments/domain/entities/scheduled_payment_entity.dart';
import 'package:fin_sight_ai/features/receivables/domain/entities/receivable_entity.dart';
import 'package:fin_sight_ai/features/sync/data/datasources/sync_local_data_source.dart';
import 'package:fin_sight_ai/features/sync/data/datasources/sync_remote_data_source.dart';
import 'package:fin_sight_ai/features/sync/data/repositories/sync_repository_impl.dart';
import 'package:fin_sight_ai/features/transactions/data/datasources/transaction_local_data_source.dart';
import 'package:fin_sight_ai/features/transactions/data/models/transaction_model.dart';
import 'package:fin_sight_ai/features/wallets/data/datasources/wallet_local_data_source.dart';
import 'package:fin_sight_ai/features/wallets/data/models/wallet_model.dart';
import 'package:fin_sight_ai/features/wallets/domain/entities/wallet_entity.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncLocalDataSource extends Mock implements SyncLocalDataSource {}

class MockSyncRemoteDataSource extends Mock implements SyncRemoteDataSource {}

class MockTransactionLocalDataSource extends Mock
    implements TransactionLocalDataSource {}

class MockDebtLocalDataSource extends Mock implements DebtLocalDataSource {}

class MockBudgetLocalDataSource extends Mock implements BudgetLocalDataSource {}

class MockReceivableLocalDataSource extends Mock
    implements ReceivableLocalDataSource {}

class MockCategoryLocalDataSource extends Mock
    implements CategoryLocalDataSource {}

class MockScheduledPaymentLocalDataSource extends Mock
    implements ScheduledPaymentLocalDataSource {}

class MockWalletLocalDataSource extends Mock implements WalletLocalDataSource {}

class MockAuthRepository extends Mock implements AuthRepository {}

class FixedClock extends Clock {
  const FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

AppEnv configuredEnv() => const AppEnv(
  supabaseUrl: 'https://demo.supabase.co',
  supabaseAnonKey: 'anon-key',
  groqApiKey: '',
);

const emptyEnv = AppEnv(supabaseUrl: '', supabaseAnonKey: '', groqApiKey: '');

TransactionModel buildTransaction({
  String id = 'tx-1',
  DateTime? updatedAt,
  bool isSynced = false,
  double amount = 10,
}) {
  return TransactionModel(
    id: id,
    amount: amount,
    type: TransactionType.expense,
    category: 'Food',
    description: 'Lunch',
    date: DateTime.utc(2026, 10, 22, 12),
    updatedAt: updatedAt ?? DateTime.utc(2026, 10, 22, 12),
    isSynced: isSynced,
  );
}

DebtModel buildDebt({
  String id = 'debt-1',
  DateTime? updatedAt,
  bool isSynced = false,
}) {
  return DebtModel(
    id: id,
    creditorName: 'Bank',
    totalAmount: 1000,
    remainingAmount: 600,
    interestRate: 12,
    minimumPayment: 100,
    dueDate: DateTime.utc(2026, 12, 1),
    updatedAt: updatedAt ?? DateTime.utc(2026, 10, 22, 12),
    isSynced: isSynced,
  );
}

ReceivableModel buildReceivable({
  String id = 'receivable-1',
  DateTime? updatedAt,
  bool isSynced = false,
  DateTime? deletedAt,
}) {
  return ReceivableModel(
    id: id,
    debtorName: 'Ana',
    totalAmount: 1000,
    remainingAmount: 600,
    dateLent: DateTime.utc(2026, 10, 1),
    status: ReceivableStatus.active,
    createdAt: DateTime.utc(2026, 10, 1),
    updatedAt: updatedAt ?? DateTime.utc(2026, 10, 22, 12),
    isSynced: isSynced,
    deletedAt: deletedAt,
  );
}

CategoryModel buildCategory({
  DateTime? updatedAt,
  DateTime? deletedAt,
  bool isSynced = false,
}) {
  return CategoryModel(
    id: 'cat-1',
    name: 'Coffee',
    createdAt: DateTime.utc(2026, 10, 1),
    updatedAt: updatedAt ?? DateTime.utc(2026, 10, 20),
    deletedAt: deletedAt,
    isSynced: isSynced,
  );
}

ScheduledPaymentModel buildSchedule({
  DateTime? deletedAt,
  DateTime? updatedAt,
}) {
  return ScheduledPaymentModel(
    id: 'pay-1',
    name: 'Rent',
    amount: 800,
    category: 'Rent',
    frequency: PaymentFrequency.monthly,
    nextDueDate: DateTime.utc(2026, 11, 1),
    dayOfMonth: 1,
    createdAt: DateTime.utc(2026, 10, 1),
    updatedAt: updatedAt ?? DateTime.utc(2026, 10, 20),
    deletedAt: deletedAt,
  );
}

void main() {
  final now = DateTime.utc(2026, 10, 22, 15);

  late MockSyncLocalDataSource local;
  late MockSyncRemoteDataSource remote;
  late MockTransactionLocalDataSource transactionLocal;
  late MockDebtLocalDataSource debtLocal;
  late MockBudgetLocalDataSource budgetLocal;
  late MockReceivableLocalDataSource receivableLocal;
  late MockCategoryLocalDataSource categoryLocal;
  late MockScheduledPaymentLocalDataSource scheduledPaymentLocal;
  late MockWalletLocalDataSource walletLocal;
  late MockAuthRepository auth;

  SyncRepositoryImpl buildRepository({
    AppEnv env = emptyEnv,
    bool authenticated = true,
  }) {
    when(() => auth.isAuthenticated).thenReturn(authenticated);
    when(() => auth.accessToken).thenReturn(authenticated ? 'token' : null);
    when(() => auth.restoreSession())
        .thenAnswer((_) async => const Right(null));
    return SyncRepositoryImpl(
      local,
      remote,
      transactionLocal,
      debtLocal,
      budgetLocal,
      receivableLocal,
      categoryLocal,
      scheduledPaymentLocal,
      walletLocal,
      env,
      auth,
      clock: FixedClock(now),
    );
  }

  setUpAll(() {
    registerFallbackValue(
      SyncOperation.delete(
        entityType: SyncEntityType.transaction,
        entityId: 'fallback',
        queuedAt: DateTime.utc(2026),
      ),
    );
    registerFallbackValue(buildTransaction());
    registerFallbackValue(buildDebt());
    registerFallbackValue(buildReceivable());
    registerFallbackValue(
      BudgetModel(
        id: 'fallback',
        category: 'fallback',
        monthlyLimit: 1,
        month: DateTime.utc(2026, 10),
      ),
    );
    registerFallbackValue(DateTime.utc(2026));
    registerFallbackValue(buildCategory());
    registerFallbackValue(buildSchedule());
    registerFallbackValue(
      WalletModel(
        id: 'wallet-bank',
        name: 'Bank',
        type: WalletType.bank,
        openingBalance: 0,
      ),
    );
    registerFallbackValue(
      WalletTransferModel(
        id: 't-1',
        fromWalletId: 'wallet-bank',
        toWalletId: 'wallet-cash',
        amount: 1,
        date: DateTime.utc(2026),
      ),
    );
  });

  setUp(() {
    local = MockSyncLocalDataSource();
    remote = MockSyncRemoteDataSource();
    transactionLocal = MockTransactionLocalDataSource();
    debtLocal = MockDebtLocalDataSource();
    budgetLocal = MockBudgetLocalDataSource();
    receivableLocal = MockReceivableLocalDataSource();
    categoryLocal = MockCategoryLocalDataSource();
    scheduledPaymentLocal = MockScheduledPaymentLocalDataSource();
    walletLocal = MockWalletLocalDataSource();

    when(() => categoryLocal.getAllCategories()).thenAnswer((_) async => []);
    when(() => scheduledPaymentLocal.getAllPayments())
        .thenAnswer((_) async => []);
    when(() => walletLocal.getAllWallets()).thenAnswer((_) async => []);
    when(() => walletLocal.getAllTransfers()).thenAnswer((_) async => []);
    when(() => categoryLocal.purgeTombstones(any())).thenAnswer((_) async => 0);
    when(() => scheduledPaymentLocal.purgeTombstones(any()))
        .thenAnswer((_) async => 0);
    when(() => walletLocal.purgeTombstones(any())).thenAnswer((_) async => 0);
    when(() => categoryLocal.saveCategory(any())).thenAnswer((_) async {});
    when(() => remote.upsertCategory(any())).thenAnswer((_) async {});
    when(() => remote.upsertScheduledPayment(any())).thenAnswer((_) async {});
    when(() => remote.upsertWallet(any())).thenAnswer((_) async {});
    when(() => remote.upsertWalletTransfer(any())).thenAnswer((_) async {});
    when(() => remote.fetchCategory(any())).thenAnswer((_) async => null);
    when(() => remote.fetchScheduledPayment(any()))
        .thenAnswer((_) async => null);
    when(() => remote.fetchWallet(any())).thenAnswer((_) async => null);
    when(() => remote.fetchWalletTransfer(any())).thenAnswer((_) async => null);
    when(() => scheduledPaymentLocal.savePayment(any()))
        .thenAnswer((_) async {});
    when(() => walletLocal.saveWallet(any())).thenAnswer((_) async {});
    when(() => walletLocal.saveTransfer(any())).thenAnswer((_) async {});
    when(
      () => remote.fetchCategories(
        updatedAfter: any(named: 'updatedAfter'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => const []);
    when(
      () => remote.fetchScheduledPayments(
        updatedAfter: any(named: 'updatedAfter'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => const []);
    when(
      () => remote.fetchWallets(
        updatedAfter: any(named: 'updatedAfter'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => const []);
    when(
      () => remote.fetchWalletTransfers(
        updatedAfter: any(named: 'updatedAfter'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => const []);
    auth = MockAuthRepository();

    when(() => local.pending()).thenAnswer((_) async => const []);
    when(() => local.pendingCount()).thenAnswer((_) async => 0);
    when(() => local.lastSyncedAt()).thenAnswer((_) async => null);
    when(() => local.remove(any())).thenAnswer((_) async {});
    when(() => local.enqueue(any())).thenAnswer((_) async {});
    when(() => local.setLastSyncedAt(any())).thenAnswer((_) async {});
    when(() => transactionLocal.saveTransaction(any()))
        .thenAnswer((_) async {});
    when(() => transactionLocal.getTransactions()).thenAnswer((_) async => []);
    when(() => transactionLocal.getAllTransactions())
        .thenAnswer((_) async => []);
    when(() => transactionLocal.purgeTombstones(any()))
        .thenAnswer((_) async => 0);
    when(() => debtLocal.saveDebt(any())).thenAnswer((_) async {});
    when(() => debtLocal.getDebts()).thenAnswer((_) async => []);
    when(() => debtLocal.getAllDebts()).thenAnswer((_) async => []);
    when(() => debtLocal.purgeTombstones(any())).thenAnswer((_) async => 0);
    when(
      () => remote.fetchTransactions(updatedAfter: any(named: 'updatedAfter')),
    ).thenAnswer((_) async => []);
    when(() => remote.fetchDebts(updatedAfter: any(named: 'updatedAfter')))
        .thenAnswer((_) async => []);
    when(() => remote.upsertTransaction(any())).thenAnswer((_) async {});
    when(() => remote.upsertDebt(any())).thenAnswer((_) async {});
    when(() => remote.deleteTransaction(any())).thenAnswer((_) async {});
    when(() => remote.deleteDebt(any())).thenAnswer((_) async {});
    when(() => budgetLocal.getAllBudgets()).thenAnswer((_) async => []);
    when(() => budgetLocal.getAllBudgetsIncludingDeleted())
        .thenAnswer((_) async => []);
    when(() => budgetLocal.saveBudget(any())).thenAnswer((_) async {});
    when(() => budgetLocal.purgeTombstones(any())).thenAnswer((_) async => 0);
    when(() => remote.fetchBudgets(updatedAfter: any(named: 'updatedAfter')))
        .thenAnswer((_) async => []);
    when(() => remote.upsertBudget(any())).thenAnswer((_) async {});
    when(() => remote.deleteBudget(any())).thenAnswer((_) async {});
    when(() => receivableLocal.getReceivables()).thenAnswer((_) async => []);
    when(() => receivableLocal.saveReceivable(any())).thenAnswer((_) async {});
    when(() => receivableLocal.purgeTombstones(any()))
        .thenAnswer((_) async => 0);
    when(
      () => remote.fetchReceivables(updatedAfter: any(named: 'updatedAfter')),
    ).thenAnswer((_) async => []);
    when(() => remote.upsertReceivable(any())).thenAnswer((_) async {});
    when(() => remote.deleteReceivable(any())).thenAnswer((_) async {});
  });

  group('SyncRepositoryImpl.getStatus', () {
    test('reports pending count, configuration, and last sync', () async {
      when(() => local.pendingCount()).thenAnswer((_) async => 3);
      when(() => local.lastSyncedAt())
          .thenAnswer((_) async => DateTime.utc(2026, 10, 20));

      final result = await buildRepository(env: configuredEnv()).getStatus();

      final status = result.getOrElse((_) => fail('Expected status'));
      expect(status.pendingCount, 3);
      expect(status.isConfigured, isTrue);
      expect(status.isAuthenticated, isTrue);
      expect(status.lastSyncedAt, DateTime.utc(2026, 10, 20));
    });

    test('maps cache failures', () async {
      when(() => local.pendingCount())
          .thenThrow(const CacheException('Queue unavailable.'));

      final result = await buildRepository().getStatus();

      expect(result.getLeft().toNullable(), isA<CacheFailure>());
    });
  });

  group('SyncRepositoryImpl.syncNow', () {
    test('returns an offline report when Supabase is not configured', () async {
      final operation = SyncOperation.upsert(
        entityType: SyncEntityType.transaction,
        entityId: 'tx-1',
        payload: buildTransaction().toJson(),
        queuedAt: now,
      );
      when(() => local.pending()).thenAnswer((_) async => [operation]);

      final result = await buildRepository(authenticated: false).syncNow();

      final report = result.getOrElse((_) => fail('Expected report'));
      expect(report.isConfigured, isFalse);
      expect(report.isAuthenticated, isFalse);
      expect(report.pendingOperations, 1);
      expect(report.pushed, 0);
      verifyNever(() => remote.upsertTransaction(any()));
    });

    test('keeps the queue when the user is not authenticated', () async {
      final operation = SyncOperation.upsert(
        entityType: SyncEntityType.transaction,
        entityId: 'tx-1',
        payload: buildTransaction().toJson(),
        queuedAt: now,
      );
      when(() => local.pending()).thenAnswer((_) async => [operation]);

      final result = await buildRepository(
        env: configuredEnv(),
        authenticated: false,
      ).syncNow();

      final report = result.getOrElse((_) => fail('Expected report'));
      expect(report.isConfigured, isTrue);
      expect(report.isAuthenticated, isFalse);
      expect(report.pendingOperations, 1);
      verifyNever(() => remote.upsertTransaction(any()));
    });

    test('skips operations waiting for their retry window', () async {
      final operation = SyncOperation.upsert(
        entityType: SyncEntityType.transaction,
        entityId: 'tx-1',
        payload: buildTransaction().toJson(),
        queuedAt: now,
        nextAttemptAt: now.add(const Duration(minutes: 5)),
      );
      when(() => local.pending()).thenAnswer((_) async => [operation]);
      when(() => local.pendingCount()).thenAnswer((_) async => 1);

      final result = await buildRepository(env: configuredEnv()).syncNow();

      final report = result.getOrElse((_) => fail('Expected report'));
      expect(report.pushed, 0);
      expect(report.pendingOperations, 1);
      verifyNever(() => remote.upsertTransaction(any()));
    });

    test('pushes a new transaction and marks it synced', () async {
      final model = buildTransaction();
      final operation = SyncOperation.upsert(
        entityType: SyncEntityType.transaction,
        entityId: model.id,
        payload: model.toJson(),
        queuedAt: now,
      );
      when(() => local.pending()).thenAnswer((_) async => [operation]);
      when(() => remote.fetchTransaction('tx-1')).thenAnswer((_) async => null);

      final result = await buildRepository(env: configuredEnv()).syncNow();

      final report = result.getOrElse((_) => fail('Expected report'));
      expect(report.pushed, 1);
      expect(report.pulled, 0);
      expect(report.conflictsResolved, 0);
      expect(report.pendingOperations, 0);
      expect(report.isAuthenticated, isTrue);

      verify(() => remote.upsertTransaction(any())).called(1);
      verify(() => local.remove('transaction:tx-1')).called(1);
      final saved =
          verify(() => transactionLocal.saveTransaction(captureAny()))
                  .captured
                  .single
              as TransactionModel;
      expect(saved.isSynced, isTrue);
      verifyNever(() => local.setLastSyncedAt(any()));
      verify(
        () => transactionLocal.purgeTombstones(
          now.subtract(const Duration(days: 30)),
        ),
      ).called(1);
      verify(
        () => debtLocal.purgeTombstones(now.subtract(const Duration(days: 30))),
      ).called(1);
    });

    test('resolves a conflict in favor of a newer remote record', () async {
      final localModel = buildTransaction(
        updatedAt: DateTime.utc(2026, 10, 22, 12),
      );
      final remoteModel = buildTransaction(
        updatedAt: DateTime.utc(2026, 10, 22, 14),
        amount: 99,
        isSynced: true,
      );
      final operation = SyncOperation.upsert(
        entityType: SyncEntityType.transaction,
        entityId: localModel.id,
        payload: localModel.toJson(),
        queuedAt: now,
      );
      when(() => local.pending()).thenAnswer((_) async => [operation]);
      when(() => remote.fetchTransaction('tx-1'))
          .thenAnswer((_) async => remoteModel.toJson());

      final result = await buildRepository(env: configuredEnv()).syncNow();

      final report = result.getOrElse((_) => fail('Expected report'));
      expect(report.conflictsResolved, 1);
      expect(report.pushed, 0);
      verifyNever(() => remote.upsertTransaction(any()));

      final saved =
          verify(() => transactionLocal.saveTransaction(captureAny()))
                  .captured
                  .single
              as TransactionModel;
      expect(saved.amount, 99);
      expect(saved.isSynced, isTrue);
    });

    test('pushes a deletion', () async {
      final operation = SyncOperation.delete(
        entityType: SyncEntityType.transaction,
        entityId: 'tx-1',
        queuedAt: now,
      );
      when(() => local.pending()).thenAnswer((_) async => [operation]);
      when(() => remote.deleteTransaction('tx-1')).thenAnswer((_) async {});

      final result = await buildRepository(env: configuredEnv()).syncNow();

      expect(result.getOrElse((_) => fail('Expected report')).pushed, 1);
      verify(() => remote.deleteTransaction('tx-1')).called(1);
      verifyNever(() => remote.upsertTransaction(any()));
    });

    test('does not resurrect a newer local tombstone', () async {
      final tombstone = TransactionModel.fromEntity(
        buildTransaction(
          updatedAt: DateTime.utc(2026, 10, 22, 14),
        ).copyWith(deletedAt: DateTime.utc(2026, 10, 22, 14), isSynced: false),
      );
      final olderRemote = buildTransaction(
        updatedAt: DateTime.utc(2026, 10, 22, 12),
        isSynced: true,
      );
      when(() => transactionLocal.getAllTransactions())
          .thenAnswer((_) async => [tombstone]);
      when(
        () =>
            remote.fetchTransactions(updatedAfter: any(named: 'updatedAfter')),
      ).thenAnswer((_) async => [olderRemote.toJson()]);

      final result = await buildRepository(env: configuredEnv()).syncNow();

      expect(result.getOrElse((_) => fail('Expected report')).pulled, 0);
      verifyNever(() => transactionLocal.saveTransaction(any()));
    });

    test('pulls newer remote transactions and debts', () async {
      final remoteTransaction = buildTransaction(
        updatedAt: DateTime.utc(2026, 10, 22, 14),
        isSynced: true,
      );
      final remoteDebt = buildDebt(
        updatedAt: DateTime.utc(2026, 10, 22, 14),
        isSynced: true,
      );
      when(() => local.lastSyncedAt())
          .thenAnswer((_) async => DateTime.utc(2026, 10, 1));
      when(
        () =>
            remote.fetchTransactions(updatedAfter: any(named: 'updatedAfter')),
      ).thenAnswer((_) async => [remoteTransaction.toJson()]);
      when(() => remote.fetchDebts(updatedAfter: any(named: 'updatedAfter')))
          .thenAnswer((_) async => [remoteDebt.toJson()]);

      final result = await buildRepository(env: configuredEnv()).syncNow();

      final report = result.getOrElse((_) => fail('Expected report'));
      expect(report.pulled, 2);
      verify(() => transactionLocal.saveTransaction(any())).called(1);
      verify(() => debtLocal.saveDebt(any())).called(1);
    });

    test('keeps the queue and increments attempts on remote failure', () async {
      final model = buildTransaction();
      final operation = SyncOperation.upsert(
        entityType: SyncEntityType.transaction,
        entityId: model.id,
        payload: model.toJson(),
        queuedAt: now,
      );
      when(() => local.pending()).thenAnswer((_) async => [operation]);
      when(() => local.pendingCount()).thenAnswer((_) async => 1);
      when(() => remote.fetchTransaction('tx-1')).thenAnswer((_) async => null);
      when(() => remote.upsertTransaction(any()))
          .thenThrow(const ServerException('Down.', code: 'supabase_http_500'));

      final result = await buildRepository(env: configuredEnv()).syncNow();

      final report = result.getOrElse((_) => fail('Expected report'));
      expect(report.failed, 1);
      expect(report.pendingOperations, 1);
      verifyNever(() => local.remove(any()));
      final requeued =
          verify(() => local.enqueue(captureAny())).captured.single
              as SyncOperation;
      expect(requeued.attempts, 1);
      expect(requeued.nextAttemptAt, isNotNull);
      expect(requeued.nextAttemptAt!.isAfter(now), isTrue);
    });

    test('pushes a budget and marks it synced', () async {
      final model = BudgetModel(
        id: 'budget-1',
        category: 'Food',
        monthlyLimit: 100,
        month: DateTime.utc(2026, 10),
        updatedAt: DateTime.utc(2026, 10, 22, 12),
      );
      final operation = SyncOperation.upsert(
        entityType: SyncEntityType.budget,
        entityId: model.id,
        payload: model.toJson(),
        queuedAt: now,
      );
      when(() => local.pending()).thenAnswer((_) async => [operation]);
      when(() => remote.fetchBudget('budget-1')).thenAnswer((_) async => null);

      final result = await buildRepository(env: configuredEnv()).syncNow();

      final report = result.getOrElse((_) => fail('Expected report'));
      expect(report.pushed, 1);
      verify(() => remote.upsertBudget(any())).called(1);
      final saved =
          verify(() => budgetLocal.saveBudget(captureAny())).captured.single
              as BudgetModel;
      expect(saved.isSynced, isTrue);
    });

    test('pulls newer remote budgets', () async {
      final remoteBudget = BudgetModel(
        id: 'budget-1',
        category: 'Food',
        monthlyLimit: 100,
        month: DateTime.utc(2026, 10),
        updatedAt: DateTime.utc(2026, 10, 22, 14),
        isSynced: true,
      );
      when(() => remote.fetchBudgets(updatedAfter: any(named: 'updatedAfter')))
          .thenAnswer((_) async => [remoteBudget.toJson()]);

      final result = await buildRepository(env: configuredEnv()).syncNow();

      expect(result.getOrElse((_) => fail('Expected report')).pulled, 1);
      verify(() => budgetLocal.saveBudget(any())).called(1);
    });

    test('pushes a receivable and marks it synced', () async {
      final model = buildReceivable();
      final operation = SyncOperation.upsert(
        entityType: SyncEntityType.receivable,
        entityId: model.id,
        payload: model.toJson(),
        queuedAt: now,
      );
      when(() => local.pending()).thenAnswer((_) async => [operation]);
      when(() => remote.fetchReceivable('receivable-1'))
          .thenAnswer((_) async => null);

      final result = await buildRepository(env: configuredEnv()).syncNow();

      expect(result.getOrElse((_) => fail('Expected report')).pushed, 1);
      verify(() => remote.upsertReceivable(any())).called(1);
      final saved =
          verify(() => receivableLocal.saveReceivable(captureAny()))
                  .captured
                  .single
              as ReceivableModel;
      expect(saved.isSynced, isTrue);
    });

    test('pulls newer remote receivables', () async {
      final remoteReceivable = buildReceivable(
        updatedAt: DateTime.utc(2026, 10, 22, 14),
        isSynced: true,
      );
      when(
        () => remote.fetchReceivables(updatedAfter: any(named: 'updatedAfter')),
      ).thenAnswer((_) async => [remoteReceivable.toJson()]);

      final result = await buildRepository(env: configuredEnv()).syncNow();

      expect(result.getOrElse((_) => fail('Expected report')).pulled, 1);
      verify(() => receivableLocal.saveReceivable(any())).called(1);
    });

    test('does not resurrect a newer local receivable tombstone', () async {
      final tombstone = buildReceivable(
        updatedAt: DateTime.utc(2026, 10, 22, 14),
        deletedAt: DateTime.utc(2026, 10, 22, 14),
      );
      final olderRemote = buildReceivable(
        updatedAt: DateTime.utc(2026, 10, 22, 12),
        isSynced: true,
      );
      when(() => receivableLocal.getReceivables())
          .thenAnswer((_) async => [tombstone]);
      when(
        () => remote.fetchReceivables(updatedAfter: any(named: 'updatedAfter')),
      ).thenAnswer((_) async => [olderRemote.toJson()]);

      final result = await buildRepository(env: configuredEnv()).syncNow();

      expect(result.getOrElse((_) => fail('Expected report')).pulled, 0);
      verifyNever(() => receivableLocal.saveReceivable(any()));
    });

    test('rejects invalid queued payloads', () async {
      final operation = SyncOperation.upsert(
        entityType: SyncEntityType.transaction,
        entityId: 'tx-1',
        payload: const {'id': 'tx-1'},
        queuedAt: now,
      );
      when(() => local.pending()).thenAnswer((_) async => [operation]);
      when(() => remote.fetchTransaction('tx-1')).thenAnswer((_) async => null);

      final result = await buildRepository(env: configuredEnv()).syncNow();

      final report = result.getOrElse((_) => fail('Expected report'));
      expect(report.discarded, 1);
      verify(() => local.remove('transaction:tx-1')).called(1);
    });

    test('continues after a discarded payload and pulls', () async {
      final bad = SyncOperation.upsert(
        entityType: SyncEntityType.transaction,
        entityId: 'bad',
        payload: const {'id': 'bad'},
        queuedAt: now,
      );
      final goodBudget = BudgetModel(
        id: 'budget-1',
        category: 'Food',
        monthlyLimit: 100,
        month: DateTime.utc(2026, 10),
        updatedAt: DateTime.utc(2026, 10, 22, 12),
      );
      final good = SyncOperation.upsert(
        entityType: SyncEntityType.budget,
        entityId: goodBudget.id,
        payload: goodBudget.toJson(),
        queuedAt: now,
      );
      when(() => local.pending()).thenAnswer((_) async => [bad, good]);
      when(() => remote.fetchTransaction('bad')).thenAnswer((_) async => null);
      when(() => remote.fetchBudget('budget-1')).thenAnswer((_) async => null);

      final result = await buildRepository(env: configuredEnv()).syncNow();

      final report = result.getOrElse((_) => fail('Expected report'));
      expect(report.discarded, 1);
      expect(report.pushed, 1);
      verify(() => remote.upsertBudget(any())).called(1);
      verify(() => local.remove('transaction:bad')).called(1);
    });

    test('keeps a failed operation and still pushes later ones', () async {
      final badModel = buildTransaction(id: 'bad');
      final bad = SyncOperation.upsert(
        entityType: SyncEntityType.transaction,
        entityId: badModel.id,
        payload: badModel.toJson(),
        queuedAt: now,
      );
      final goodBudget = BudgetModel(
        id: 'budget-1',
        category: 'Food',
        monthlyLimit: 100,
        month: DateTime.utc(2026, 10),
        updatedAt: DateTime.utc(2026, 10, 22, 12),
      );
      final good = SyncOperation.upsert(
        entityType: SyncEntityType.budget,
        entityId: goodBudget.id,
        payload: goodBudget.toJson(),
        queuedAt: now,
      );
      when(() => local.pending()).thenAnswer((_) async => [bad, good]);
      when(() => remote.fetchTransaction('bad')).thenAnswer((_) async => null);
      when(() => remote.fetchBudget('budget-1')).thenAnswer((_) async => null);
      when(() => remote.upsertTransaction(any()))
          .thenThrow(const ServerException('Down.', code: 'supabase_http_500'));

      final result = await buildRepository(env: configuredEnv()).syncNow();

      final report = result.getOrElse((_) => fail('Expected report'));
      expect(report.failed, 1);
      expect(report.pushed, 1);
      verify(() => remote.upsertBudget(any())).called(1);
      verifyNever(() => local.remove('transaction:bad'));
      verify(() => local.remove('budget:budget-1')).called(1);
    });

    test(
      'sets the watermark from received rows, not the local clock',
      () async {
        final remoteTransaction = buildTransaction(
          updatedAt: DateTime.utc(2026, 10, 20, 10),
          isSynced: true,
        );
        when(
          () => remote.fetchTransactions(
            updatedAfter: any(named: 'updatedAfter'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => [remoteTransaction.toJson()]);

        await buildRepository(env: configuredEnv()).syncNow();

        verify(() => local.setLastSyncedAt(DateTime.utc(2026, 10, 20, 10)))
            .called(1);
        verifyNever(() => local.setLastSyncedAt(now));
      },
    );

    test('pages through remote rows until a short page', () async {
      final firstPage = List.generate(
        500,
        (index) => buildTransaction(
          id: 'tx-$index',
          updatedAt: DateTime.utc(2026, 10, 20, 10),
          isSynced: true,
        ).toJson(),
      );
      final secondPage = List.generate(
        3,
        (index) => buildTransaction(
          id: 'tx-${500 + index}',
          updatedAt: DateTime.utc(2026, 10, 20, 11),
          isSynced: true,
        ).toJson(),
      );
      when(
        () => remote.fetchTransactions(
          updatedAfter: any(named: 'updatedAfter'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((invocation) async {
        final offset = invocation.namedArguments[#offset] as int;
        return offset == 0 ? firstPage : secondPage;
      });

      final result = await buildRepository(env: configuredEnv()).syncNow();

      expect(result.getOrElse((_) => fail('Expected report')).pulled, 503);
      verify(
        () => remote.fetchTransactions(
          updatedAfter: any(named: 'updatedAfter'),
          limit: 500,
          offset: 0,
        ),
      ).called(1);
      verify(
        () => remote.fetchTransactions(
          updatedAfter: any(named: 'updatedAfter'),
          limit: 500,
          offset: 500,
        ),
      ).called(1);
    });
  });

  group('definition sync', () {
    test('pushes a category upsert and marks it synced', () async {
      final model = buildCategory();
      final operation = SyncOperation.upsert(
        entityType: SyncEntityType.category,
        entityId: model.id,
        payload: model.toJson(),
        queuedAt: now,
      );
      when(() => local.pending()).thenAnswer((_) async => [operation]);
      when(() => remote.fetchCategory(model.id)).thenAnswer((_) async => null);

      final report = (await buildRepository(
        env: configuredEnv(),
      ).syncNow()).getOrElse((_) => fail('Expected report'));

      expect(report.pushed, 1);
      verify(() => remote.upsertCategory(any())).called(1);
      final saved =
          verify(() => categoryLocal.saveCategory(captureAny())).captured.single
              as CategoryModel;
      expect(saved.isSynced, isTrue);
      expect(saved.name, 'Coffee');
    });

    test('resolves a category conflict when the remote row is newer', () async {
      final model = buildCategory(updatedAt: DateTime.utc(2026, 10, 20));
      final operation = SyncOperation.upsert(
        entityType: SyncEntityType.category,
        entityId: model.id,
        payload: model.toJson(),
        queuedAt: now,
      );
      when(() => local.pending()).thenAnswer((_) async => [operation]);
      when(() => remote.fetchCategory(model.id)).thenAnswer(
        (_) async =>
            buildCategory(updatedAt: DateTime.utc(2026, 10, 21)).toJson(),
      );

      final report = (await buildRepository(
        env: configuredEnv(),
      ).syncNow()).getOrElse((_) => fail('Expected report'));

      expect(report.conflictsResolved, 1);
      verifyNever(() => remote.upsertCategory(any()));
      verify(() => categoryLocal.saveCategory(any())).called(1);
    });

    test('pulls category and schedule tombstones before the ledger', () async {
      final deletedAt = DateTime.utc(2026, 10, 19);
      when(
        () => remote.fetchCategories(
          updatedAfter: any(named: 'updatedAfter'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => [buildCategory(deletedAt: deletedAt).toJson()]);
      when(
        () => remote.fetchScheduledPayments(
          updatedAfter: any(named: 'updatedAfter'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => [buildSchedule(deletedAt: deletedAt).toJson()]);

      final report = (await buildRepository(
        env: configuredEnv(),
      ).syncNow()).getOrElse((_) => fail('Expected report'));

      expect(report.pulled, 2);
      final category =
          verify(() => categoryLocal.saveCategory(captureAny())).captured.single
              as CategoryModel;
      expect(category.isDeleted, isTrue);
      final schedule =
          verify(() => scheduledPaymentLocal.savePayment(captureAny()))
                  .captured
                  .single
              as ScheduledPaymentModel;
      expect(schedule.isDeleted, isTrue);

      verifyInOrder([
        () => remote.fetchCategories(
          updatedAfter: any(named: 'updatedAfter'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
        () => remote.fetchScheduledPayments(
          updatedAfter: any(named: 'updatedAfter'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
        () => remote.fetchWallets(
          updatedAfter: any(named: 'updatedAfter'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
        () => remote.fetchWalletTransfers(
          updatedAfter: any(named: 'updatedAfter'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
        () => remote.fetchTransactions(
          updatedAfter: any(named: 'updatedAfter'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ]);
    });

    test(
      'pushes schedules, wallets, and transfers with conflict resolution',
      () async {
        final schedule = buildSchedule();
        final wallet = WalletModel(
          id: 'wallet-bank',
          name: 'Bank',
          type: WalletType.bank,
          openingBalance: 100,
          updatedAt: DateTime.utc(2026, 10, 20),
        );
        final transfer = WalletTransferModel(
          id: 't-1',
          fromWalletId: 'wallet-bank',
          toWalletId: 'wallet-cash',
          amount: 25,
          date: DateTime.utc(2026, 10, 2),
          createdAt: DateTime.utc(2026, 10, 2),
          updatedAt: DateTime.utc(2026, 10, 20),
        );
        when(() => local.pending()).thenAnswer(
          (_) async => [
            SyncOperation.upsert(
              entityType: SyncEntityType.scheduledPayment,
              entityId: schedule.id,
              payload: schedule.toJson(),
              queuedAt: now,
            ),
            SyncOperation.upsert(
              entityType: SyncEntityType.wallet,
              entityId: wallet.id,
              payload: wallet.toJson(),
              queuedAt: now,
            ),
            SyncOperation.upsert(
              entityType: SyncEntityType.walletTransfer,
              entityId: transfer.id,
              payload: transfer.toJson(),
              queuedAt: now,
            ),
          ],
        );
        when(() => remote.fetchScheduledPayment(schedule.id)).thenAnswer(
          (_) async =>
              buildSchedule(updatedAt: DateTime.utc(2026, 10, 21)).toJson(),
        );
        when(() => remote.fetchWallet(wallet.id)).thenAnswer(
          (_) async => WalletModel(
            id: wallet.id,
            name: 'Bank',
            type: WalletType.bank,
            openingBalance: 120,
            updatedAt: DateTime.utc(2026, 10, 21),
          ).toJson(),
        );
        when(() => remote.fetchWalletTransfer(transfer.id)).thenAnswer(
          (_) async => WalletTransferModel(
            id: transfer.id,
            fromWalletId: 'wallet-bank',
            toWalletId: 'wallet-cash',
            amount: 30,
            date: DateTime.utc(2026, 10, 2),
            createdAt: DateTime.utc(2026, 10, 2),
            updatedAt: DateTime.utc(2026, 10, 21),
          ).toJson(),
        );

        final report = (await buildRepository(
          env: configuredEnv(),
        ).syncNow()).getOrElse((_) => fail('Expected report'));

        expect(report.conflictsResolved, 3);
        verifyNever(() => remote.upsertScheduledPayment(any()));
        verifyNever(() => remote.upsertWallet(any()));
        verifyNever(() => remote.upsertWalletTransfer(any()));
        verify(() => scheduledPaymentLocal.savePayment(any())).called(1);
        verify(() => walletLocal.saveWallet(any())).called(1);
        verify(() => walletLocal.saveTransfer(any())).called(1);
      },
    );

    test('pulls wallet and transfer rows', () async {
      when(
        () => remote.fetchWallets(
          updatedAfter: any(named: 'updatedAfter'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer(
        (_) async => [
          {
            'id': 'wallet-bank',
            'name': 'Bank',
            'type': 'bank',
            'openingBalance': 100,
            'currency': 'COP',
            'updatedAt': '2026-10-20T00:00:00.000Z',
          },
        ],
      );
      when(
        () => remote.fetchWalletTransfers(
          updatedAfter: any(named: 'updatedAfter'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer(
        (_) async => [
          {
            'id': 't-1',
            'fromWalletId': 'wallet-bank',
            'toWalletId': 'wallet-cash',
            'amount': 25,
            'date': '2026-10-02T00:00:00.000Z',
            'createdAt': '2026-10-02T00:00:00.000Z',
            'updatedAt': '2026-10-20T00:00:00.000Z',
          },
        ],
      );

      final report = (await buildRepository(
        env: configuredEnv(),
      ).syncNow()).getOrElse((_) => fail('Expected report'));

      expect(report.pulled, 2);
      final savedWallet =
          verify(() => walletLocal.saveWallet(captureAny())).captured.single
              as WalletModel;
      expect(savedWallet.openingBalance, 100);
      final savedTransfer =
          verify(() => walletLocal.saveTransfer(captureAny())).captured.single
              as WalletTransferModel;
      expect(savedTransfer.amount, 25);
    });

    test('pushes wallet and transfer upserts', () async {
      final wallet = WalletModel(
        id: 'wallet-bank',
        name: 'Bank',
        type: WalletType.bank,
        openingBalance: 100,
        updatedAt: DateTime.utc(2026, 10, 20),
      );
      final transfer = WalletTransferModel(
        id: 't-1',
        fromWalletId: 'wallet-bank',
        toWalletId: 'wallet-cash',
        amount: 25,
        date: DateTime.utc(2026, 10, 2),
        createdAt: DateTime.utc(2026, 10, 2),
        updatedAt: DateTime.utc(2026, 10, 2),
      );
      when(() => local.pending()).thenAnswer(
        (_) async => [
          SyncOperation.upsert(
            entityType: SyncEntityType.wallet,
            entityId: wallet.id,
            payload: wallet.toJson(),
            queuedAt: now,
          ),
          SyncOperation.upsert(
            entityType: SyncEntityType.walletTransfer,
            entityId: transfer.id,
            payload: transfer.toJson(),
            queuedAt: now,
          ),
        ],
      );
      when(() => remote.fetchWallet(wallet.id)).thenAnswer((_) async => null);
      when(() => remote.fetchWalletTransfer(transfer.id))
          .thenAnswer((_) async => null);

      final report = (await buildRepository(
        env: configuredEnv(),
      ).syncNow()).getOrElse((_) => fail('Expected report'));

      expect(report.pushed, 2);
      verify(() => remote.upsertWallet(any())).called(1);
      verify(() => remote.upsertWalletTransfer(any())).called(1);
      verify(() => walletLocal.saveWallet(any())).called(1);
      verify(() => walletLocal.saveTransfer(any())).called(1);
    });
  });
}
