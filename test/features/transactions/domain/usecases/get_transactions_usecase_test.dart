import 'package:fin_sight_ai/core/error/failures.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction.dart';
import 'package:fin_sight_ai/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late MockTransactionRepository repository;
  late GetTransactionsUseCase useCase;

  setUp(() {
    repository = MockTransactionRepository();
    useCase = GetTransactionsUseCase(repository);
  });

  group('GetTransactionsUseCase', () {
    test('returns the repository transactions on success', () async {
      // Arrange
      final transactions = <Transaction>[
        Transaction(
          id: 'tx-1',
          amount: 10,
          date: DateTime.utc(2026, 10, 20),
          category: 'Coffee',
          type: TransactionType.expense,
        ),
      ];
      when(() => repository.getTransactions())
          .thenAnswer((_) async => Right(transactions));

      // Act
      final result = await useCase(const NoParams());

      // Assert
      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => const <Transaction>[]), transactions);
    });

    test('propagates a repository failure unchanged', () async {
      // Arrange
      const failure = CacheFailure('Store unavailable.', code: 'cache_down');
      when(() => repository.getTransactions())
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(const NoParams());

      // Assert
      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), failure);
    });
  });
}
