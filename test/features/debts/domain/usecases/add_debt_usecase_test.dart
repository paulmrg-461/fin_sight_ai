import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/features/debts/domain/entities/debt_entity.dart';
import 'package:fin_sight_ai/features/debts/domain/repositories/debt_repository.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/add_debt_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class MockDebtRepository extends Mock implements DebtRepository {}

void main() {
  final dueDate = DateTime.utc(2026, 12, 1);

  late MockDebtRepository repository;
  late AddDebtUseCase useCase;

  setUpAll(() {
    registerFallbackValue(
      DebtEntity(
        id: 'fallback',
        creditorName: 'fallback',
        totalAmount: 1,
        remainingAmount: 1,
        interestRate: 0,
        minimumPayment: 1,
        dueDate: DateTime.utc(2026),
      ),
    );
  });

  setUp(() {
    repository = MockDebtRepository();
    useCase = AddDebtUseCase(repository);
    when(() => repository.addDebt(any())).thenAnswer((invocation) async {
      return Right(invocation.positionalArguments.first as DebtEntity);
    });
  });

  AddDebtParams params({
    String creditor = '  Bank  ',
    double total = 1000,
    double? remaining,
    double interestRate = 12.5,
    double minimumPayment = 100,
  }) {
    return AddDebtParams(
      creditorName: creditor,
      totalAmount: total,
      remainingAmount: remaining ?? total,
      interestRate: interestRate,
      minimumPayment: minimumPayment,
      dueDate: dueDate,
    );
  }

  group('AddDebtUseCase', () {
    test('normalizes input and generates an id', () async {
      final result = await useCase(
        params(creditor: '  Bank  ', total: 1000.006),
      );

      final debt = result.getOrElse((failure) => fail('Expected a debt'));
      expect(Uuid.isValidUUID(fromString: debt.id), isTrue);
      expect(debt.creditorName, 'Bank');
      expect(debt.totalAmount, 1000.01);
      expect(debt.remainingAmount, 1000.01);
      expect(debt.interestRate, 12.5);
      expect(debt.status, DebtStatus.active);
    });

    test('marks a fully settled debt as paid', () async {
      final result = await useCase(params(remaining: 0));

      expect(
        result.getOrElse((failure) => fail('Expected a debt')).status,
        DebtStatus.paid,
      );
    });

    test('rejects a blank creditor', () async {
      final result = await useCase(params(creditor: '  '));

      expect(result.getLeft().toNullable()?.code, 'invalid_creditor');
      verifyNever(() => repository.addDebt(any()));
    });

    test('rejects a non-positive total', () async {
      final zero = await useCase(params(total: 0, remaining: 0));
      final negative = await useCase(params(total: -10, remaining: 0));

      expect(zero.getLeft().toNullable()?.code, 'invalid_total');
      expect(negative.getLeft().toNullable()?.code, 'invalid_total');
    });

    test('rejects a remaining amount outside the total', () async {
      final negative = await useCase(params(total: 100, remaining: -1));
      final above = await useCase(params(total: 100, remaining: 101));

      expect(negative.getLeft().toNullable()?.code, 'invalid_remaining');
      expect(above.getLeft().toNullable()?.code, 'invalid_remaining');
    });

    test('rejects an out-of-range interest rate', () async {
      final negative = await useCase(params(interestRate: -1));
      final tooHigh = await useCase(params(interestRate: 101));

      expect(negative.getLeft().toNullable()?.code, 'invalid_interest_rate');
      expect(tooHigh.getLeft().toNullable()?.code, 'invalid_interest_rate');
    });

    test('rejects a non-positive minimum payment', () async {
      final result = await useCase(params(minimumPayment: 0));

      expect(result.getLeft().toNullable()?.code, 'invalid_minimum_payment');
    });

    test('rejects non-finite numbers', () async {
      final total = await useCase(params(total: double.nan, remaining: 0));
      final payment = await useCase(params(minimumPayment: double.infinity));

      expect(total.getLeft().toNullable()?.code, 'invalid_total');
      expect(payment.getLeft().toNullable()?.code, 'invalid_minimum_payment');
    });

    test('propagates repository failures', () async {
      const failure = CacheFailure('Store down.');
      when(() => repository.addDebt(any()))
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase(params());

      expect(result.getLeft().toNullable(), failure);
    });
  });
}
