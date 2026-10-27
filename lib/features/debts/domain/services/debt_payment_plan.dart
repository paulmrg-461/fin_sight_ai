/// One monthly installment in a debt payoff plan.
class DebtInstallment {
  const DebtInstallment({
    required this.period,
    required this.date,
    required this.payment,
    required this.interest,
    required this.principal,
    required this.remaining,
  });

  final int period;
  final DateTime date;
  final double payment;
  final double interest;
  final double principal;
  final double remaining;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebtInstallment &&
          other.period == period &&
          other.date == date &&
          other.payment == payment &&
          other.interest == interest &&
          other.principal == principal &&
          other.remaining == remaining;

  @override
  int get hashCode =>
      Object.hash(period, date, payment, interest, principal, remaining);

  @override
  String toString() =>
      'DebtInstallment($period, payment: $payment, remaining: $remaining)';
}

/// Deterministic amortization schedule for one debt.
class DebtPaymentPlan {
  const DebtPaymentPlan({
    required this.installments,
    required this.totalInterest,
    required this.totalPaid,
    required this.payoffDate,
  });

  final List<DebtInstallment> installments;
  final double totalInterest;
  final double totalPaid;
  final DateTime payoffDate;

  int get months => installments.length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebtPaymentPlan &&
          other.totalInterest == totalInterest &&
          other.totalPaid == totalPaid &&
          other.payoffDate == payoffDate &&
          _sameInstallments(other.installments, installments);

  @override
  int get hashCode => Object.hash(
    totalInterest,
    totalPaid,
    payoffDate,
    Object.hashAll(installments),
  );

  @override
  String toString() =>
      'DebtPaymentPlan($months months, interest: $totalInterest)';

  static bool _sameInstallments(
    List<DebtInstallment> a,
    List<DebtInstallment> b,
  ) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }
}
