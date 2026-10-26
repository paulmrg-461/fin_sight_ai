import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/features/debts/domain/entities/debt_entity.dart';
import 'package:fin_sight_ai/features/debts/domain/repositories/debt_repository.dart';
import 'package:fin_sight_ai/features/scheduled_payments/domain/entities/committed_cashflow.dart';
import 'package:fin_sight_ai/features/scheduled_payments/domain/entities/scheduled_payment_entity.dart';
import 'package:fin_sight_ai/features/scheduled_payments/domain/repositories/scheduled_payment_repository.dart';
import 'package:fin_sight_ai/features/scheduled_payments/domain/usecases/committed_cashflow_usecase.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockScheduledPaymentRepository extends Mock
    implements ScheduledPaymentRepository {}

class MockDebtRepository extends Mock implements DebtRepository {}

void main() {
  late MockScheduledPaymentRepository payments;
  late MockDebtRepository debts;
  late GetCommittedCashflowUseCase useCase;

  final from = DateTime(2026, 10, 1);

  ScheduledPaymentEntity schedule({
    String id = 'pay-1',
    String name = 'Rent',
    double amount = 800,
    DateTime? nextDueDate,
    PaymentFrequency frequency = PaymentFrequency.monthly,
    int dayOfMonth = 15,
    bool active = true,
    TransactionType type = TransactionType.expense,
    String category = 'Rent',
  }) {
    return ScheduledPaymentEntity(
      id: id,
      name: name,
      amount: amount,
      type: type,
      category: category,
      frequency: frequency,
      nextDueDate: nextDueDate ?? DateTime(2026, 10, 15),
      dayOfMonth: dayOfMonth,
      isActive: active,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  DebtEntity debt({
    String id = 'debt-1',
    DateTime? dueDate,
    double minimumPayment = 120,
    DebtStatus status = DebtStatus.active,
  }) {
    return DebtEntity(
      id: id,
      creditorName: 'Bank',
      totalAmount: 1000,
      remainingAmount: 600,
      interestRate: 10,
      minimumPayment: minimumPayment,
      dueDate: dueDate ?? DateTime(2026, 10, 20),
      status: status,
    );
  }

  setUp(() {
    payments = MockScheduledPaymentRepository();
    debts = MockDebtRepository();
    useCase = GetCommittedCashflowUseCase(payments, debts);
    when(() => payments.getPayments()).thenAnswer((_) async => const Right([]));
    when(() => debts.getDebts()).thenAnswer((_) async => const Right([]));
  });

  Future<CommittedCashflow> project({int days = 30, DateTime? start}) async {
    final result = await useCase(
      CommittedCashflowParams(from: start ?? from, days: days),
    );
    return result.getOrElse((failure) => fail(failure.message));
  }

  test('expands a monthly schedule across the window', () async {
    when(() => payments.getPayments())
        .thenAnswer((_) async => Right([schedule()]));

    final projection = await project(days: 60);

    expect(projection.payments.map((payment) => payment.date), [
      DateTime(2026, 10, 15),
      DateTime(2026, 11, 15),
    ]);
    expect(projection.total, 1600);
    expect(projection.payments.first.source, CommittedSource.scheduledPayment);
  });

  test('includes a yearly schedule once', () async {
    when(() => payments.getPayments()).thenAnswer(
      (_) async => Right([
        schedule(
          frequency: PaymentFrequency.yearly,
          nextDueDate: DateTime(2026, 12, 1),
          dayOfMonth: 1,
        ),
      ]),
    );

    final projection = await project(days: 90);

    expect(projection.payments.single.date, DateTime(2026, 12, 1));
    expect(projection.total, 800);
  });

  test('excludes paused and income schedules', () async {
    when(() => payments.getPayments()).thenAnswer(
      (_) async => Right([
        schedule(id: 'paused', active: false),
        schedule(
          id: 'income',
          type: TransactionType.income,
          category: 'Salary',
        ),
      ]),
    );

    final projection = await project();

    expect(projection.isEmpty, isTrue);
  });

  test('advances an overdue schedule into the window', () async {
    when(() => payments.getPayments()).thenAnswer(
      (_) async => Right([schedule(nextDueDate: DateTime(2026, 8, 15))]),
    );

    final projection = await project(days: 30);

    expect(projection.payments.single.date, DateTime(2026, 10, 15));
  });

  test('adds debt minimums monthly on the debt due day', () async {
    when(() => debts.getDebts()).thenAnswer((_) async => Right([debt()]));

    final projection = await project(days: 60);

    expect(projection.payments.map((payment) => payment.date), [
      DateTime(2026, 10, 20),
      DateTime(2026, 11, 20),
    ]);
    expect(projection.total, 240);
    expect(projection.payments.first.source, CommittedSource.debtMinimum);
    expect(projection.payments.first.name, 'Bank');
  });

  test('advances an overdue debt into the window', () async {
    when(() => debts.getDebts())
        .thenAnswer((_) async => Right([debt(dueDate: DateTime(2026, 7, 20))]));

    final projection = await project(days: 30);

    expect(projection.payments.single.date, DateTime(2026, 10, 20));
  });

  test('excludes paid debts', () async {
    when(() => debts.getDebts())
        .thenAnswer((_) async => Right([debt(status: DebtStatus.paid)]));

    expect((await project()).isEmpty, isTrue);
  });

  test('includes both window boundaries', () async {
    when(() => payments.getPayments()).thenAnswer(
      (_) async => Right([
        schedule(id: 'start', nextDueDate: DateTime(2026, 10, 1)),
        schedule(
          id: 'end',
          nextDueDate: DateTime(2026, 10, 31),
          dayOfMonth: 31,
        ),
      ]),
    );

    final projection = await project(days: 30);

    expect(projection.payments.map((payment) => payment.name), [
      'Rent',
      'Rent',
    ]);
    expect(projection.payments, hasLength(2));
  });

  test('sorts combined commitments by date', () async {
    when(() => payments.getPayments()).thenAnswer(
      (_) async => Right([schedule(nextDueDate: DateTime(2026, 10, 25))]),
    );
    when(() => debts.getDebts()).thenAnswer((_) async => Right([debt()]));

    final projection = await project();

    expect(projection.payments.first.date, DateTime(2026, 10, 20));
    expect(projection.payments.last.date, DateTime(2026, 10, 25));
  });

  test('CommittedCashflowParams compares by value', () {
    expect(
      CommittedCashflowParams(from: from, days: 30),
      CommittedCashflowParams(from: from, days: 30),
    );
    expect(
      CommittedCashflowParams(from: from, days: 30).hashCode,
      CommittedCashflowParams(from: from, days: 30).hashCode,
    );
    expect(
      CommittedCashflowParams(from: from, days: 30),
      isNot(CommittedCashflowParams(from: from, days: 90)),
    );
  });

  test('rejects an invalid window', () async {
    for (final days in [0, 366]) {
      final result = await useCase(
        CommittedCashflowParams(from: from, days: days),
      );
      expect(
        result.fold((failure) => failure.code, (_) => null),
        'invalid_projection_window',
      );
    }
    verifyNever(() => payments.getPayments());
  });

  test('propagates repository failures', () async {
    when(() => payments.getPayments())
        .thenAnswer((_) async => const Left(CacheFailure('Store down.')));

    final result = await useCase(CommittedCashflowParams(from: from, days: 30));

    expect(
      result.fold((failure) => failure.message, (_) => null),
      'Store down.',
    );
  });
}
