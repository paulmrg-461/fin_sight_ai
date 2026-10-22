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
    if (!annualInterestRate.isFinite || annualInterestRate < 0) {
      return null;
    }
    if (!monthlyPayment.isFinite || monthlyPayment <= 0) {
      return null;
    }

    final monthlyRate = annualInterestRate / 100 / 12;
    var balance = remainingAmount;
    var months = 0;

    while (balance > 0) {
      final interest = balance * monthlyRate;
      if (monthlyPayment <= interest) {
        return null;
      }
      balance = balance + interest - monthlyPayment;
      months++;
      if (months > 1200) {
        // Guard against pathological inputs (over 100 years).
        return null;
      }
    }

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
