import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/features/debts/domain/repositories/debt_repository.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/delete_debt_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockDebtRepository extends Mock implements DebtRepository {}

void main() {
  late MockDebtRepository repository;
  late DeleteDebtUseCase useCase;

  setUp(() {
    repository = MockDebtRepository();
    useCase = DeleteDebtUseCase(repository);
  });

  group('DeleteDebtUseCase', () {
    test('deletes through the repository', () async {
      when(() => repository.deleteDebt('debt-1'))
          .thenAnswer((_) async => const Right(null));

      final result = await useCase('debt-1');

      expect(result.isRight(), isTrue);
      verify(() => repository.deleteDebt('debt-1')).called(1);
    });

    test('rejects a blank id', () async {
      final result = await useCase('   ');

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      expect(result.getLeft().toNullable()?.code, 'missing_id');
      verifyNever(() => repository.deleteDebt(any()));
    });

    test('propagates repository failures', () async {
      const failure = CacheFailure('Delete failed.');
      when(() => repository.deleteDebt('debt-1'))
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase('debt-1');

      expect(result.getLeft().toNullable(), failure);
    });
  });
}
