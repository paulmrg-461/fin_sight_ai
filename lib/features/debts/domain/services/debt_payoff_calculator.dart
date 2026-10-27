import 'debt_payment_plan.dart';

/// Deterministic debt payoff projection.
abstract final class DebtPayoffCalculator {
  /// Returns the projected payoff date, or `null` when the debt cannot be
  /// repaid with [monthlyPayment] (payment does not cover monthly interest).
  ///
  /// A zero or negative balance is already settled and returns [from].
  static DateTime? calculatePayoffDate({
    required double remainingAmount,
    required double annualInterestRate,
    required double monthlyPayment,
    required DateTime from,
  }) {
    if (remainingAmount <= 0) {
      return from;
    }
    return buildPaymentPlan(
      remainingAmount: remainingAmount,
      annualInterestRate: annualInterestRate,
      monthlyPayment: monthlyPayment,
      from: from,
    )?.payoffDate;
  }

  /// Builds the full amortization schedule, or `null` when the payment cannot
  /// cover interest or the plan would exceed 100 years.
  static DebtPaymentPlan? buildPaymentPlan({
    required double remainingAmount,
    required double annualInterestRate,
    required double monthlyPayment,
    required DateTime from,
  }) {
    if (remainingAmount <= 0) {
      return DebtPaymentPlan(
        installments: const [],
        totalInterest: 0,
        totalPaid: 0,
        payoffDate: from,
      );
    }
    if (!annualInterestRate.isFinite || annualInterestRate < 0) {
      return null;
    }
    if (!monthlyPayment.isFinite || monthlyPayment <= 0) {
      return null;
    }

    final monthlyRate = annualInterestRate / 100 / 12;
    var balance = remainingAmount;
    var totalInterest = 0.0;
    var totalPaid = 0.0;
    final installments = <DebtInstallment>[];
    var months = 0;

    while (balance > 0.004) {
      final interest = _round(balance * monthlyRate);
      if (monthlyPayment <= interest) {
        return null;
      }
      final payment = _round(
        monthlyPayment >= balance + interest
            ? balance + interest
            : monthlyPayment,
      );
      final principal = _round(payment - interest);
      balance = _round(balance + interest - payment);
      months++;
      totalInterest = _round(totalInterest + interest);
      totalPaid = _round(totalPaid + payment);
      final date = _monthOffset(from, months);
      installments.add(
        DebtInstallment(
          period: months,
          date: date,
          payment: payment,
          interest: interest,
          principal: principal,
          remaining: balance < 0 ? 0 : balance,
        ),
      );
      if (months > 1200) {
        return null;
      }
    }

    return DebtPaymentPlan(
      installments: List<DebtInstallment>.unmodifiable(installments),
      totalInterest: totalInterest,
      totalPaid: totalPaid,
      payoffDate: _monthOffset(from, months),
    );
  }

  static double _round(double value) => double.parse(value.toStringAsFixed(2));

  static DateTime _monthOffset(DateTime from, int months) {
    return from.isUtc
        ? DateTime.utc(
            from.year,
            from.month + months,
            from.day,
            from.hour,
            from.minute,
            from.second,
            from.millisecond,
            from.microsecond,
          )
        : DateTime(
            from.year,
            from.month + months,
            from.day,
            from.hour,
            from.minute,
            from.second,
            from.millisecond,
            from.microsecond,
          );
  }
}
