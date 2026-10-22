import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
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

  final transaction = TransactionEntity(
    id: 'tx-1',
    amount: 10,
    type: TransactionType.expense,
    category: 'Coffee',
    description: '',
    date: DateTime.utc(2026, 10, 20),
  );

  group('GetTransactionsUseCase', () {
    test('returns repository transactions', () async {
      when(() => repository.getTransactions())
          .thenAnswer((_) async => Right([transaction]));

      final result = await useCase(const NoParams());

      expect(result.getOrElse((_) => const <TransactionEntity>[]), [
        transaction,
      ]);
    });

    test('propagates repository failures', () async {
      const failure = CacheFailure('Store down.');
      when(() => repository.getTransactions())
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase(const NoParams());

      expect(result.getLeft().toNullable(), failure);
    });
  });
}
