import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/core/sync/sync_operation.dart';
import 'package:fin_sight_ai/core/utils/clock.dart';
import 'package:fin_sight_ai/features/transactions/data/datasources/transaction_local_data_source.dart';
import 'package:fin_sight_ai/features/transactions/data/models/transaction_model.dart';
import 'package:fin_sight_ai/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionLocalDataSource extends Mock
    implements TransactionLocalDataSource {}

class MockSyncQueue extends Mock implements SyncQueue {}

class FixedClock extends Clock {
  const FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

TransactionModel buildModel({
  String id = 'tx-1',
  double amount = 10,
  DateTime? date,
  String category = 'Coffee',
}) {
  return TransactionModel(
    id: id,
    amount: amount,
    type: TransactionType.expense,
    category: category,
    description: 'Morning',
    date: date ?? DateTime.utc(2026, 10, 20, 12),
  );
}

TransactionEntity buildEntity({
  String id = 'tx-1',
  String category = 'Coffee',
}) {
  return TransactionEntity(
    id: id,
    amount: 10,
    type: TransactionType.expense,
    category: category,
    description: 'Morning',
    date: DateTime.utc(2026, 10, 20, 12),
  );
}

void main() {
  late MockTransactionLocalDataSource localDataSource;
  late TransactionRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(buildModel());
    registerFallbackValue(
      SyncOperation.delete(
        entityType: SyncEntityType.transaction,
        entityId: 'fallback',
        queuedAt: DateTime.utc(2026),
      ),
    );
  });

  setUp(() {
    localDataSource = MockTransactionLocalDataSource();
    repository = TransactionRepositoryImpl(localDataSource);
  });

  group('TransactionRepositoryImpl.addTransaction', () {
    test('persists the model and returns the entity', () async {
      when(() => localDataSource.saveTransaction(any()))
          .thenAnswer((_) async {});

      final result = await repository.addTransaction(buildEntity());

      final saved = result.getOrElse((_) => fail('Expected saved entity'));
      expect(saved.id, 'tx-1');
      final captured =
          verify(() => localDataSource.saveTransaction(captureAny()))
                  .captured
                  .single
              as TransactionModel;
      expect(captured.id, 'tx-1');
    });

    test('maps CacheException to CacheFailure', () async {
      when(() => localDataSource.saveTransaction(any())).thenThrow(
        const CacheException('Disk full.', code: 'cache_write_failed'),
      );

      final result = await repository.addTransaction(buildEntity());

      final failure = result.getLeft().toNullable();
      expect(failure, isA<CacheFailure>());
      expect(failure?.code, 'cache_write_failed');
    });

    test('maps unexpected errors to a generic CacheFailure', () async {
      when(() => localDataSource.saveTransaction(any()))
          .thenThrow(StateError('boom'));

      final result = await repository.addTransaction(buildEntity());

      expect(result.getLeft().toNullable()?.code, 'cache_write_failed');
    });
  });

  group('TransactionRepositoryImpl.updateTransaction', () {
    test('updates an existing transaction in place', () async {
      when(() => localDataSource.getTransactions())
          .thenAnswer((_) async => [buildModel()]);
      when(() => localDataSource.saveTransaction(any()))
          .thenAnswer((_) async {});

      final result = await repository.updateTransaction(
        TransactionEntity(
          id: 'tx-1',
          amount: 99,
          type: TransactionType.income,
          category: 'Salary',
          description: 'Raise',
          date: DateTime.utc(2026, 10, 20, 12),
          walletId: 'wallet-bank',
        ),
      );

      final updated = result.getOrElse((_) => fail('Expected update'));
      expect(updated.id, 'tx-1');
      expect(updated.amount, 99);
      expect(updated.category, 'Salary');
      expect(updated.walletId, 'wallet-bank');
      final saved =
          verify(() => localDataSource.saveTransaction(captureAny()))
                  .captured
                  .single
              as TransactionModel;
      expect(saved.id, 'tx-1');
      expect(saved.amount, 99);
    });

    test('reports a missing transaction', () async {
      when(() => localDataSource.getTransactions()).thenAnswer((_) async => []);

      final result = await repository.updateTransaction(buildEntity());

      expect(
        result.fold((failure) => failure.code, (_) => null),
        'transaction_not_found',
      );
      verifyNever(() => localDataSource.saveTransaction(any()));
    });
  });

  group('TransactionRepositoryImpl.getTransactions', () {
    test('maps stored models to entities', () async {
      when(() => localDataSource.getTransactions())
          .thenAnswer((_) async => [buildModel(id: 'a'), buildModel(id: 'b')]);

      final result = await repository.getTransactions();

      final transactions = result.getOrElse(
        (_) => fail('Expected transactions'),
      );
      expect(transactions.map((t) => t.id), ['a', 'b']);
      expect(transactions, everyElement(isA<TransactionEntity>()));
    });

    test('maps CacheException to CacheFailure', () async {
      when(
        () => localDataSource.getTransactions(),
      ).thenThrow(const CacheException('Corrupt.', code: 'cache_read_failed'));

      final result = await repository.getTransactions();

      expect(result.getLeft().toNullable()?.code, 'cache_read_failed');
    });

    test('maps unexpected errors to a generic CacheFailure', () async {
      when(() => localDataSource.getTransactions())
          .thenThrow(StateError('boom'));

      final result = await repository.getTransactions();

      expect(result.getLeft().toNullable()?.code, 'cache_read_failed');
    });
  });

  group('TransactionRepositoryImpl.deleteTransaction', () {
    test('writes a tombstone instead of hard-deleting', () async {
      when(() => localDataSource.getTransactions())
          .thenAnswer((_) async => [buildModel()]);
      when(() => localDataSource.saveTransaction(any()))
          .thenAnswer((_) async {});

      final result = await repository.deleteTransaction('tx-1');

      expect(result.isRight(), isTrue);
      final saved =
          verify(() => localDataSource.saveTransaction(captureAny()))
                  .captured
                  .single
              as TransactionModel;
      expect(saved.isDeleted, isTrue);
      expect(saved.isSynced, isFalse);
      verifyNever(() => localDataSource.deleteTransaction(any()));
    });

    test('ignores missing records', () async {
      when(() => localDataSource.getTransactions()).thenAnswer((_) async => []);

      final result = await repository.deleteTransaction('missing');

      expect(result.isRight(), isTrue);
      verifyNever(() => localDataSource.saveTransaction(any()));
    });

    test('maps CacheException to CacheFailure', () async {
      when(() => localDataSource.getTransactions()).thenThrow(
        const CacheException('Missing.', code: 'cache_delete_failed'),
      );

      final result = await repository.deleteTransaction('tx-1');

      expect(result.getLeft().toNullable()?.code, 'cache_delete_failed');
    });
  });

  group('TransactionRepositoryImpl.renameCategory', () {
    test('renames only matching, non-deleted transactions', () async {
      when(() => localDataSource.getAllTransactions()).thenAnswer(
        (_) async => [
          buildModel(),
          buildModel(id: 'tx-2'),
          buildModel(id: 'tx-3', category: 'Salary'),
        ],
      );
      when(() => localDataSource.saveTransaction(any()))
          .thenAnswer((_) async {});

      final result = await repository.renameCategory(
        from: 'Coffee',
        to: 'Dining',
      );

      expect(result.fold((_) => -1, (count) => count), 2);
      final saved = verify(() => localDataSource.saveTransaction(captureAny()))
          .captured
          .cast<TransactionModel>();
      expect(saved.map((model) => model.category), everyElement('Dining'));
    });

    test('is a no-op when the names are equal', () async {
      final result = await repository.renameCategory(
        from: 'Coffee',
        to: 'Coffee',
      );

      expect(result.fold((_) => -1, (count) => count), 0);
      verifyNever(() => localDataSource.getAllTransactions());
    });
  });

  group('TransactionRepositoryImpl.getTransactionsByDateRange', () {
    final start = DateTime.utc(2026, 10, 1);
    final end = DateTime.utc(2026, 10, 31);

    test('queries the data source with the range and maps results', () async {
      when(
        () =>
            localDataSource.getTransactionsByDateRange(start: start, end: end),
      ).thenAnswer((_) async => [buildModel(id: 'in-range')]);

      final result = await repository.getTransactionsByDateRange(
        start: start,
        end: end,
      );

      final transactions = result.getOrElse(
        (_) => fail('Expected transactions'),
      );
      expect(transactions.single.id, 'in-range');
    });

    test('maps CacheException to CacheFailure', () async {
      when(
        () => localDataSource.getTransactionsByDateRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).thenThrow(const CacheException('Corrupt.'));

      final result = await repository.getTransactionsByDateRange(
        start: start,
        end: end,
      );

      expect(result.getLeft().toNullable()?.code, isNull);
      expect(result.getLeft().toNullable(), isA<CacheFailure>());
    });
  });

  group('sync queue integration', () {
    final now = DateTime.utc(2026, 10, 22, 15);
    late MockSyncQueue queue;

    setUp(() {
      queue = MockSyncQueue();
      when(() => queue.enqueue(any())).thenAnswer((_) async {});
    });

    test('enqueues an upsert with sync metadata', () async {
      when(() => localDataSource.saveTransaction(any()))
          .thenAnswer((_) async {});
      final repository = TransactionRepositoryImpl(
        localDataSource,
        syncQueue: queue,
        clock: FixedClock(now),
      );

      await repository.addTransaction(buildEntity());

      final operation =
          verify(() => queue.enqueue(captureAny())).captured.single
              as SyncOperation;
      expect(operation.entityType, SyncEntityType.transaction);
      expect(operation.operationType, SyncOperationType.upsert);
      expect(operation.entityId, 'tx-1');
      expect(operation.payload['isSynced'], isFalse);
      expect(operation.payload['updatedAt'], now.toUtc().toIso8601String());
    });

    test('enqueues a tombstone upsert', () async {
      when(() => localDataSource.getTransactions())
          .thenAnswer((_) async => [buildModel()]);
      when(() => localDataSource.saveTransaction(any()))
          .thenAnswer((_) async {});
      final repository = TransactionRepositoryImpl(
        localDataSource,
        syncQueue: queue,
        clock: FixedClock(now),
      );

      await repository.deleteTransaction('tx-1');

      final operation =
          verify(() => queue.enqueue(captureAny())).captured.single
              as SyncOperation;
      expect(operation.operationType, SyncOperationType.upsert);
      expect(operation.entityId, 'tx-1');
      expect(operation.payload['deletedAt'], isNotNull);
    });

    test('a queue failure does not fail the local write', () async {
      when(() => localDataSource.saveTransaction(any()))
          .thenAnswer((_) async {});
      when(() => queue.enqueue(any())).thenThrow(Exception('queue down'));
      final repository = TransactionRepositoryImpl(
        localDataSource,
        syncQueue: queue,
        clock: FixedClock(now),
      );

      final result = await repository.addTransaction(buildEntity());

      expect(result.isRight(), isTrue);
    });
  });
}
