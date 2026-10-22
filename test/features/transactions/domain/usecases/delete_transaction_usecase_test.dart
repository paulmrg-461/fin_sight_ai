import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late MockTransactionRepository repository;
  late DeleteTransactionUseCase useCase;

  setUp(() {
    repository = MockTransactionRepository();
    useCase = DeleteTransactionUseCase(repository);
  });

  group('DeleteTransactionUseCase', () {
    test('deletes through the repository', () async {
      when(() => repository.deleteTransaction('tx-1'))
          .thenAnswer((_) async => const Right(null));

      final result = await useCase('tx-1');

      expect(result.isRight(), isTrue);
      verify(() => repository.deleteTransaction('tx-1')).called(1);
    });

    test('rejects a blank id', () async {
      final result = await useCase('   ');

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      expect(result.getLeft().toNullable()?.code, 'missing_id');
      verifyNever(() => repository.deleteTransaction(any()));
    });

    test('propagates repository failures', () async {
      const failure = CacheFailure('Delete failed.');
      when(() => repository.deleteTransaction('tx-1'))
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase('tx-1');

      expect(result.getLeft().toNullable(), failure);
    });
  });
}
