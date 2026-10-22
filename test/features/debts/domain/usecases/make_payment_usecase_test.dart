import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/utils/clock.dart';
import 'package:fin_sight_ai/features/debts/domain/entities/debt_entity.dart';
import 'package:fin_sight_ai/features/debts/domain/repositories/debt_repository.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/make_payment_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockDebtRepository extends Mock implements DebtRepository {}

class FixedClock extends Clock {
  const FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

void main() {
  final now = DateTime.utc(2026, 10, 22);

  late MockDebtRepository repository;
  late MakePaymentUseCase useCase;

  DebtEntity buildDebt({
    double remaining = 600,
    DebtStatus status = DebtStatus.active,
  }) {
    return DebtEntity(
      id: 'debt-1',
      creditorName: 'Bank',
      totalAmount: 1000,
      remainingAmount: remaining,
      interestRate: 12,
      minimumPayment: 100,
      dueDate: DateTime.utc(2026, 12, 1),
      status: status,
    );
  }

  setUpAll(() {
    registerFallbackValue(buildDebt());
  });

  setUp(() {
    repository = MockDebtRepository();
    useCase = MakePaymentUseCase(repository, clock: FixedClock(now));
    when(() => repository.updateDebt(any())).thenAnswer((invocation) async {
      return Right(invocation.positionalArguments.first as DebtEntity);
    });
  });

  group('MakePaymentUseCase', () {
    test('applies a partial payment and records history', () async {
      when(() => repository.getDebts())
          .thenAnswer((_) async => Right([buildDebt()]));

      final result = await useCase(
        const MakePaymentParams(debtId: 'debt-1', amount: 100),
      );

      final updated = result.getOrElse(
        (failure) => fail('Expected an updated debt'),
      );
      expect(updated.remainingAmount, 500);
      expect(updated.status, DebtStatus.active);
      expect(updated.paymentHistory, hasLength(1));
      expect(updated.paymentHistory.single.amount, 100);
      expect(updated.paymentHistory.single.paidAt, now);
    });

    test('clamps an overpayment to zero and marks the debt paid', () async {
      when(() => repository.getDebts())
          .thenAnswer((_) async => Right([buildDebt()]));

      final result = await useCase(
        const MakePaymentParams(debtId: 'debt-1', amount: 1000),
      );

      final updated = result.getOrElse(
        (failure) => fail('Expected an updated debt'),
      );
      expect(updated.remainingAmount, 0);
      expect(updated.status, DebtStatus.paid);
      expect(updated.paymentHistory.single.amount, 600);
    });

    test('rejects zero, negative, and non-finite payments', () async {
      final zero = await useCase(
        const MakePaymentParams(debtId: 'debt-1', amount: 0),
      );
      final negative = await useCase(
        const MakePaymentParams(debtId: 'debt-1', amount: -5),
      );
      final infinite = await useCase(
        MakePaymentParams(debtId: 'debt-1', amount: double.infinity),
      );

      expect(zero.getLeft().toNullable()?.code, 'invalid_payment');
      expect(negative.getLeft().toNullable()?.code, 'invalid_payment');
      expect(infinite.getLeft().toNullable()?.code, 'invalid_payment');
      verifyNever(() => repository.getDebts());
    });

    test('rejects an unknown debt', () async {
      when(() => repository.getDebts())
          .thenAnswer((_) async => Right([buildDebt()]));

      final result = await useCase(
        const MakePaymentParams(debtId: 'missing', amount: 100),
      );

      expect(result.getLeft().toNullable()?.code, 'debt_not_found');
    });

    test('rejects a debt that is already paid', () async {
      when(() => repository.getDebts()).thenAnswer(
        (_) async => Right([buildDebt(remaining: 0, status: DebtStatus.paid)]),
      );

      final result = await useCase(
        const MakePaymentParams(debtId: 'debt-1', amount: 100),
      );

      expect(result.getLeft().toNullable()?.code, 'debt_already_paid');
    });

    test('propagates failures while loading debts', () async {
      const failure = CacheFailure('Store down.');
      when(() => repository.getDebts())
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase(
        const MakePaymentParams(debtId: 'debt-1', amount: 100),
      );

      expect(result.getLeft().toNullable(), failure);
    });

    test('propagates failures while updating the debt', () async {
      const failure = CacheFailure('Write failed.');
      when(() => repository.getDebts())
          .thenAnswer((_) async => Right([buildDebt()]));
      when(() => repository.updateDebt(any()))
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase(
        const MakePaymentParams(debtId: 'debt-1', amount: 100),
      );

      expect(result.getLeft().toNullable(), failure);
    });
  });
}
