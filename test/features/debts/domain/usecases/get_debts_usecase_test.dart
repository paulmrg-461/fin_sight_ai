import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/features/debts/domain/entities/debt_entity.dart';
import 'package:fin_sight_ai/features/debts/domain/repositories/debt_repository.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/get_debts_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockDebtRepository extends Mock implements DebtRepository {}

void main() {
  late MockDebtRepository repository;
  late GetDebtsUseCase useCase;

  final debt = DebtEntity(
    id: 'debt-1',
    creditorName: 'Bank',
    totalAmount: 1000,
    remainingAmount: 600,
    interestRate: 12,
    minimumPayment: 100,
    dueDate: DateTime.utc(2026, 12, 1),
  );

  setUp(() {
    repository = MockDebtRepository();
    useCase = GetDebtsUseCase(repository);
  });

  group('GetDebtsUseCase', () {
    test('returns repository debts', () async {
      when(() => repository.getDebts()).thenAnswer((_) async => Right([debt]));

      final result = await useCase(const NoParams());

      expect(result.getOrElse((_) => const <DebtEntity>[]), [debt]);
    });

    test('propagates repository failures', () async {
      const failure = CacheFailure('Store down.');
      when(() => repository.getDebts())
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase(const NoParams());

      expect(result.getLeft().toNullable(), failure);
    });
  });
}
