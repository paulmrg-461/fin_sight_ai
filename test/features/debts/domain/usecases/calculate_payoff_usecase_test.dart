import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/features/debts/domain/entities/debt_entity.dart';
import 'package:fin_sight_ai/features/debts/domain/repositories/debt_repository.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/calculate_payoff_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockDebtRepository extends Mock implements DebtRepository {}

void main() {
  late MockDebtRepository repository;
  late CalculatePayoffUseCase useCase;

  final debt = DebtEntity(
    id: 'debt-1',
    creditorName: 'Bank',
    totalAmount: 1000,
    remainingAmount: 600,
    interestRate: 12,
    minimumPayment: 100,
    dueDate: DateTime.utc(2026, 12, 1),
  );
  final payoffDate = DateTime.utc(2027, 6, 1);

  setUpAll(() {
    registerFallbackValue(debt);
  });

  setUp(() {
    repository = MockDebtRepository();
    useCase = CalculatePayoffUseCase(repository);
  });

  group('CalculatePayoffUseCase', () {
    test('delegates to the repository with the override payment', () async {
      when(() => repository.calculatePayoffDate(debt, monthlyPayment: 150))
          .thenAnswer((_) async => Right(payoffDate));

      final result = await useCase(
        CalculatePayoffParams(debt: debt, monthlyPayment: 150),
      );

      expect(result.getOrElse((_) => null), payoffDate);
    });

    test('uses the minimum payment when no override is provided', () async {
      when(() => repository.calculatePayoffDate(debt, monthlyPayment: null))
          .thenAnswer((_) async => Right(payoffDate));

      final result = await useCase(CalculatePayoffParams(debt: debt));

      expect(result.getOrElse((_) => null), payoffDate);
      verify(() => repository.calculatePayoffDate(debt, monthlyPayment: null))
          .called(1);
    });

    test('returns null when the debt is not payable', () async {
      when(() => repository.calculatePayoffDate(debt, monthlyPayment: 5))
          .thenAnswer((_) async => const Right(null));

      final result = await useCase(
        CalculatePayoffParams(debt: debt, monthlyPayment: 5),
      );

      expect(result.getOrElse((_) => DateTime(2000)), isNull);
    });

    test('rejects a non-positive override payment', () async {
      final zero = await useCase(
        CalculatePayoffParams(debt: debt, monthlyPayment: 0),
      );
      final negative = await useCase(
        CalculatePayoffParams(debt: debt, monthlyPayment: -1),
      );

      expect(zero.getLeft().toNullable(), isA<ValidationFailure>());
      expect(zero.getLeft().toNullable()?.code, 'invalid_payment');
      expect(negative.getLeft().toNullable()?.code, 'invalid_payment');
      verifyNever(
        () => repository.calculatePayoffDate(
          any(),
          monthlyPayment: any(named: 'monthlyPayment'),
        ),
      );
    });

    test('propagates repository failures', () async {
      const failure = CacheFailure('Store down.');
      when(() => repository.calculatePayoffDate(debt, monthlyPayment: null))
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase(CalculatePayoffParams(debt: debt));

      expect(result.getLeft().toNullable(), failure);
    });
  });
}
