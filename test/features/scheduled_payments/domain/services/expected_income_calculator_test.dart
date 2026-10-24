import 'package:fin_sight_ai/features/scheduled_payments/domain/entities/scheduled_payment_entity.dart';
import 'package:fin_sight_ai/features/scheduled_payments/domain/services/expected_income_calculator.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ScheduledPaymentEntity schedule({
    String id = 'pay-1',
    double amount = 1000,
    PaymentFrequency frequency = PaymentFrequency.monthly,
    DateTime? nextDueDate,
    TransactionType type = TransactionType.income,
    bool isActive = true,
  }) {
    return ScheduledPaymentEntity(
      id: id,
      name: id,
      amount: amount,
      type: type,
      category: type == TransactionType.income ? 'Salary' : 'Rent',
      frequency: frequency,
      nextDueDate: nextDueDate ?? DateTime(2026, 10, 25),
      dayOfMonth: 25,
      isActive: isActive,
      createdAt: DateTime.utc(2026, 10, 1),
    );
  }

  test('returns an empty summary without income schedules', () {
    final summary = ExpectedIncomeCalculator.calculate([
      schedule(type: TransactionType.expense),
    ]);

    expect(summary.isEmpty, isTrue);
    expect(summary.monthlyAmount, 0);
    expect(summary.count, 0);
    expect(summary.nextIncomeDate, isNull);
  });

  test('sums monthly amounts plus yearly amounts divided by twelve', () {
    final summary = ExpectedIncomeCalculator.calculate([
      schedule(id: 'salary', amount: 3000),
      schedule(id: 'bonus', amount: 1200, frequency: PaymentFrequency.yearly),
    ]);

    expect(summary.monthlyAmount, 3100);
    expect(summary.count, 2);
  });

  test('rounds the monthly total to two decimals', () {
    final summary = ExpectedIncomeCalculator.calculate([
      schedule(id: 'salary', amount: 1000),
      schedule(id: 'bonus', amount: 1000, frequency: PaymentFrequency.yearly),
    ]);

    expect(summary.monthlyAmount, 1083.33);
  });

  test('ignores paused schedules', () {
    final summary = ExpectedIncomeCalculator.calculate([
      schedule(id: 'salary', amount: 3000),
      schedule(id: 'paused', amount: 5000, isActive: false),
    ]);

    expect(summary.monthlyAmount, 3000);
    expect(summary.count, 1);
  });

  test('reports the earliest next income date', () {
    final summary = ExpectedIncomeCalculator.calculate([
      schedule(
        id: 'salary',
        amount: 3000,
        nextDueDate: DateTime(2026, 10, 25, 18),
      ),
      schedule(
        id: 'bonus',
        amount: 1200,
        frequency: PaymentFrequency.yearly,
        nextDueDate: DateTime(2026, 12, 1),
      ),
    ]);

    expect(summary.nextIncomeDate, DateTime(2026, 10, 25));
  });

  test('value objects compare by content', () {
    const first = Summary(monthlyAmount: 3000, count: 1, nextIncomeDate: null);
    const second = Summary(monthlyAmount: 3000, count: 1, nextIncomeDate: null);

    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });
}
