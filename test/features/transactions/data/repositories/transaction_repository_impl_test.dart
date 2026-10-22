import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/features/transactions/data/datasources/transaction_local_data_source.dart';
import 'package:fin_sight_ai/features/transactions/data/models/transaction_model.dart';
import 'package:fin_sight_ai/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionLocalDataSource extends Mock
    implements TransactionLocalDataSource {}

TransactionModel buildModel({
  String id = 'tx-1',
  double amount = 10,
  DateTime? date,
}) {
  return TransactionModel(
    id: id,
    amount: amount,
    type: TransactionType.expense,
    category: 'Coffee',
    description: 'Morning',
    date: date ?? DateTime.utc(2026, 10, 20, 12),
  );
}

TransactionEntity buildEntity({String id = 'tx-1'}) {
  return TransactionEntity(
    id: id,
    amount: 10,
    type: TransactionType.expense,
    category: 'Coffee',
    description: 'Morning',
    date: DateTime.utc(2026, 10, 20, 12),
  );
}

void main() {
  late MockTransactionLocalDataSource localDataSource;
  late TransactionRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(buildModel());
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
    test('deletes through the data source', () async {
      when(() => localDataSource.deleteTransaction('tx-1'))
          .thenAnswer((_) async {});

      final result = await repository.deleteTransaction('tx-1');

      expect(result.isRight(), isTrue);
      verify(() => localDataSource.deleteTransaction('tx-1')).called(1);
    });

    test('maps CacheException to CacheFailure', () async {
      when(() => localDataSource.deleteTransaction(any())).thenThrow(
        const CacheException('Missing.', code: 'cache_delete_failed'),
      );

      final result = await repository.deleteTransaction('tx-1');

      expect(result.getLeft().toNullable()?.code, 'cache_delete_failed');
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
}
