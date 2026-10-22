import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/core/error/failures.dart';
import 'package:fin_sight_ai/features/transactions/data/datasources/transaction_local_data_source.dart';
import 'package:fin_sight_ai/features/transactions/data/datasources/transaction_remote_data_source.dart';
import 'package:fin_sight_ai/features/transactions/data/models/transaction_model.dart';
import 'package:fin_sight_ai/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionLocalDataSource extends Mock
    implements TransactionLocalDataSource {}

class MockTransactionRemoteDataSource extends Mock
    implements TransactionRemoteDataSource {}

TransactionModel buildModel({
  String id = 'tx-1',
  double amount = 10,
  DateTime? date,
  bool isSynced = false,
}) {
  return TransactionModel(
    id: id,
    amount: amount,
    date: date ?? DateTime.utc(2026, 10, 20, 12),
    category: 'Coffee',
    type: TransactionType.expense,
    note: 'Morning',
    isSynced: isSynced,
  );
}

Transaction buildEntity({String id = 'tx-1', DateTime? date}) {
  return Transaction(
    id: id,
    amount: 10,
    date: date ?? DateTime.utc(2026, 10, 20, 12),
    category: 'Coffee',
    type: TransactionType.expense,
    note: 'Morning',
  );
}

void main() {
  late MockTransactionLocalDataSource localDataSource;
  late MockTransactionRemoteDataSource remoteDataSource;
  late TransactionRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(buildModel());
  });

  setUp(() {
    localDataSource = MockTransactionLocalDataSource();
    remoteDataSource = MockTransactionRemoteDataSource();
    repository = TransactionRepositoryImpl(localDataSource, remoteDataSource);
  });

  group('TransactionRepositoryImpl.getTransactions', () {
    test('sorts transactions newest first', () async {
      // Arrange
      final older = buildModel(id: 'older', date: DateTime.utc(2026, 10, 1));
      final newer = buildModel(id: 'newer', date: DateTime.utc(2026, 10, 20));
      when(() => localDataSource.getTransactions())
          .thenAnswer((_) async => [older, newer]);

      // Act
      final result = await repository.getTransactions();

      // Assert
      final transactions = result.getOrElse(
        (failure) => fail('Expected transactions, got $failure'),
      );
      expect(transactions.map((transaction) => transaction.id), [
        'newer',
        'older',
      ]);
    });

    test('returns an empty list when the store is empty', () async {
      // Arrange
      when(() => localDataSource.getTransactions()).thenAnswer((_) async => []);

      // Act
      final result = await repository.getTransactions();

      // Assert
      expect(result.getOrElse((_) => const <Transaction>[]), isEmpty);
    });

    test('maps CacheException onto CacheFailure', () async {
      // Arrange
      when(() => localDataSource.getTransactions()).thenThrow(
        const CacheException(
          'The local store is corrupted.',
          code: 'cache_corrupted',
        ),
      );

      // Act
      final result = await repository.getTransactions();

      // Assert
      final failure = result.getLeft().toNullable();
      expect(failure, isA<CacheFailure>());
      expect(failure?.message, 'The local store is corrupted.');
      expect(failure?.code, 'cache_corrupted');
    });

    test('maps unexpected errors onto a generic CacheFailure', () async {
      // Arrange
      when(() => localDataSource.getTransactions())
          .thenThrow(StateError('unexpected'));

      // Act
      final result = await repository.getTransactions();

      // Assert
      final failure = result.getLeft().toNullable();
      expect(failure, isA<CacheFailure>());
      expect(failure?.code, 'cache_read_failed');
    });
  });

  group('TransactionRepositoryImpl.addTransaction', () {
    test('persists locally and marks the record synced after upload', () async {
      // Arrange
      when(() => localDataSource.saveTransaction(any()))
          .thenAnswer((_) async {});
      when(() => remoteDataSource.uploadTransaction(any()))
          .thenAnswer((_) async => true);

      // Act
      final result = await repository.addTransaction(buildEntity());

      // Assert
      final saved = result.getOrElse(
        (failure) => fail('Expected a transaction, got $failure'),
      );
      expect(saved.isSynced, isTrue);

      final savedModels = verify(
        () => localDataSource.saveTransaction(captureAny()),
      ).captured.cast<TransactionModel>();
      expect(savedModels, hasLength(2));
      expect(savedModels.first.isSynced, isFalse);
      expect(savedModels.last.isSynced, isTrue);
    });

    test('keeps the record pending when the backend rejects it', () async {
      // Arrange
      when(() => localDataSource.saveTransaction(any()))
          .thenAnswer((_) async {});
      when(() => remoteDataSource.uploadTransaction(any()))
          .thenAnswer((_) async => false);

      // Act
      final result = await repository.addTransaction(buildEntity());

      // Assert
      final saved = result.getOrElse(
        (failure) => fail('Expected a transaction, got $failure'),
      );
      expect(saved.isSynced, isFalse);
      verify(() => localDataSource.saveTransaction(any())).called(1);
    });

    test('keeps the local write when the remote call throws', () async {
      // Arrange
      when(() => localDataSource.saveTransaction(any()))
          .thenAnswer((_) async {});
      when(() => remoteDataSource.uploadTransaction(any()))
          .thenThrow(const ServerException('Network down.'));

      // Act
      final result = await repository.addTransaction(buildEntity());

      // Assert
      final saved = result.getOrElse(
        (failure) => fail('Expected a transaction, got $failure'),
      );
      expect(saved.isSynced, isFalse);
      verify(() => localDataSource.saveTransaction(any())).called(1);
    });

    test('uploads the pending record, not a pre-synced one', () async {
      // Arrange
      when(() => localDataSource.saveTransaction(any()))
          .thenAnswer((_) async {});
      when(() => remoteDataSource.uploadTransaction(any()))
          .thenAnswer((_) async => false);

      // Act
      await repository.addTransaction(buildEntity());

      // Assert
      final uploaded =
          verify(() => remoteDataSource.uploadTransaction(captureAny()))
                  .captured
                  .single
              as TransactionModel;
      expect(uploaded.isSynced, isFalse);
    });

    test(
      'returns CacheFailure and skips upload when the local write fails',
      () async {
        // Arrange
        when(() => localDataSource.saveTransaction(any())).thenThrow(
          const CacheException('Disk full.', code: 'cache_write_failed'),
        );

        // Act
        final result = await repository.addTransaction(buildEntity());

        // Assert
        final failure = result.getLeft().toNullable();
        expect(failure, isA<CacheFailure>());
        expect(failure?.code, 'cache_write_failed');
        verifyNever(() => remoteDataSource.uploadTransaction(any()));
      },
    );

    test('maps unexpected local errors onto a generic CacheFailure', () async {
      // Arrange
      when(() => localDataSource.saveTransaction(any()))
          .thenThrow(StateError('unexpected'));

      // Act
      final result = await repository.addTransaction(buildEntity());

      // Assert
      expect(result.getLeft().toNullable()?.code, 'cache_write_failed');
    });

    test('returns the pending record when marking it synced fails', () async {
      // Arrange
      var saves = 0;
      when(() => localDataSource.saveTransaction(any())).thenAnswer((_) async {
        saves += 1;
        if (saves == 2) {
          throw const CacheException('Disk full.');
        }
      });
      when(() => remoteDataSource.uploadTransaction(any()))
          .thenAnswer((_) async => true);

      // Act
      final result = await repository.addTransaction(buildEntity());

      // Assert
      final saved = result.getOrElse(
        (failure) => fail('Expected a transaction, got $failure'),
      );
      expect(saved.isSynced, isFalse);
    });
  });
}
