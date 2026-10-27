import 'package:fin_sight_ai/features/debts/domain/services/debt_payment_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final date = DateTime.utc(2026, 11, 15);

  DebtInstallment installment({int period = 1, double remaining = 400}) {
    return DebtInstallment(
      period: period,
      date: date,
      payment: 200,
      interest: 10,
      principal: 190,
      remaining: remaining,
    );
  }

  test('installments compare by value and expose their fields', () {
    expect(installment(), installment());
    expect(installment().hashCode, installment().hashCode);
    expect(installment(), isNot(installment(period: 2)));
    expect(installment(), isNot(installment(remaining: 0)));
    expect(installment().toString(), contains('200.0'));
  });

  test('plans compare by value', () {
    final plan = DebtPaymentPlan(
      installments: [installment(), installment(period: 2, remaining: 0)],
      totalInterest: 20,
      totalPaid: 400,
      payoffDate: DateTime.utc(2026, 12, 15),
    );

    expect(plan.months, 2);
    expect(
      plan,
      DebtPaymentPlan(
        installments: [installment(), installment(period: 2, remaining: 0)],
        totalInterest: 20,
        totalPaid: 400,
        payoffDate: DateTime.utc(2026, 12, 15),
      ),
    );
    expect(plan.hashCode, isNonZero);
    expect(plan.toString(), contains('2 months'));
    expect(
      plan,
      isNot(
        DebtPaymentPlan(
          installments: [installment()],
          totalInterest: 20,
          totalPaid: 400,
          payoffDate: DateTime.utc(2026, 12, 15),
        ),
      ),
    );
    expect(plan, isNot(Object()));
  });

  test('an empty plan reports zero months', () {
    final plan = DebtPaymentPlan(
      installments: const [],
      totalInterest: 0,
      totalPaid: 0,
      payoffDate: date,
    );

    expect(plan.months, 0);
  });
}
