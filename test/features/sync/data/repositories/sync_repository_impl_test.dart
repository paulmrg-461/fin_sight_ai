import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/core/sync/sync_operation.dart';
import 'package:fin_sight_ai/core/utils/app_env.dart';
import 'package:fin_sight_ai/core/utils/clock.dart';
import 'package:fin_sight_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:fin_sight_ai/features/debts/data/datasources/debt_local_data_source.dart';
import 'package:fin_sight_ai/features/debts/data/models/debt_model.dart';
import 'package:fin_sight_ai/features/sync/data/datasources/sync_local_data_source.dart';
import 'package:fin_sight_ai/features/sync/data/datasources/sync_remote_data_source.dart';
import 'package:fin_sight_ai/features/sync/data/repositories/sync_repository_impl.dart';
import 'package:fin_sight_ai/features/transactions/data/datasources/transaction_local_data_source.dart';
import 'package:fin_sight_ai/features/transactions/data/models/transaction_model.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncLocalDataSource extends Mock implements SyncLocalDataSource {}

class MockSyncRemoteDataSource extends Mock implements SyncRemoteDataSource {}

class MockTransactionLocalDataSource extends Mock
    implements TransactionLocalDataSource {}

class MockDebtLocalDataSource extends Mock implements DebtLocalDataSource {}

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

void main() {
  final now = DateTime.utc(2026, 10, 22, 15);

  late MockSyncLocalDataSource local;
  late MockSyncRemoteDataSource remote;
  late MockTransactionLocalDataSource transactionLocal;
  late MockDebtLocalDataSource debtLocal;
  late MockAuthRepository auth;

  SyncRepositoryImpl buildRepository({
    AppEnv env = emptyEnv,
    bool authenticated = true,
  }) {
    when(() => auth.isAuthenticated).thenReturn(authenticated);
    when(() => auth.accessToken).thenReturn(authenticated ? 'token' : null);
    return SyncRepositoryImpl(
      local,
      remote,
      transactionLocal,
      debtLocal,
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
    registerFallbackValue(DateTime.utc(2026));
  });

  setUp(() {
    local = MockSyncLocalDataSource();
    remote = MockSyncRemoteDataSource();
    transactionLocal = MockTransactionLocalDataSource();
    debtLocal = MockDebtLocalDataSource();
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
    when(() => debtLocal.saveDebt(any())).thenAnswer((_) async {});
    when(() => debtLocal.getDebts()).thenAnswer((_) async => []);
    when(
      () => remote.fetchTransactions(updatedAfter: any(named: 'updatedAfter')),
    ).thenAnswer((_) async => []);
    when(() => remote.fetchDebts(updatedAfter: any(named: 'updatedAfter')))
        .thenAnswer((_) async => []);
    when(() => remote.upsertTransaction(any())).thenAnswer((_) async {});
    when(() => remote.upsertDebt(any())).thenAnswer((_) async {});
    when(() => remote.deleteTransaction(any())).thenAnswer((_) async {});
    when(() => remote.deleteDebt(any())).thenAnswer((_) async {});
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
      verify(() => local.setLastSyncedAt(now)).called(1);
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
      when(() => remote.fetchTransaction('tx-1')).thenAnswer((_) async => null);
      when(() => remote.upsertTransaction(any()))
          .thenThrow(const ServerException('Down.', code: 'supabase_http_500'));

      final result = await buildRepository(env: configuredEnv()).syncNow();

      expect(result.getLeft().toNullable()?.code, 'supabase_http_500');
      verifyNever(() => local.remove(any()));
      final requeued =
          verify(() => local.enqueue(captureAny())).captured.single
              as SyncOperation;
      expect(requeued.attempts, 1);
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

      expect(result.getLeft().toNullable()?.code, 'sync_invalid_payload');
    });
  });
}
