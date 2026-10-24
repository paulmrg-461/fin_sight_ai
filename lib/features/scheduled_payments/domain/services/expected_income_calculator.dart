import '../entities/scheduled_payment_entity.dart';
import 'schedule_calculator.dart';

/// Aggregated recurring income shown above the scheduled payments list.
class Summary {
  const Summary({
    required this.monthlyAmount,
    required this.count,
    this.nextIncomeDate,
  });

  /// Expected income per month, rounded to two decimals.
  final double monthlyAmount;

  /// Number of active income schedules counted.
  final int count;

  /// Earliest next payday among the counted schedules, or null when empty.
  final DateTime? nextIncomeDate;

  bool get isEmpty => count == 0;

  bool get isNotEmpty => count > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Summary &&
          other.monthlyAmount == monthlyAmount &&
          other.count == count &&
          other.nextIncomeDate == nextIncomeDate;

  @override
  int get hashCode => Object.hash(monthlyAmount, count, nextIncomeDate);

  @override
  String toString() =>
      'Summary(monthlyAmount: $monthlyAmount, count: $count, '
      'nextIncomeDate: $nextIncomeDate)';
}

/// Pure calculation of expected recurring income.
abstract final class ExpectedIncomeCalculator {
  /// Sums active income schedules: monthly amounts plus yearly amounts / 12.
  static Summary calculate(List<ScheduledPaymentEntity> payments) {
    final incomes = payments
        .where((payment) => payment.isActive && payment.isIncome)
        .toList();
    if (incomes.isEmpty) {
      return const Summary(monthlyAmount: 0, count: 0);
    }

    var monthlyAmount = 0.0;
    DateTime? nextIncomeDate;
    for (final payment in incomes) {
      monthlyAmount += switch (payment.frequency) {
        PaymentFrequency.monthly => payment.amount,
        PaymentFrequency.yearly => payment.amount / 12,
      };

      final due = ScheduleCalculator.dateOnly(payment.nextDueDate);
      if (nextIncomeDate == null || due.isBefore(nextIncomeDate)) {
        nextIncomeDate = due;
      }
    }

    return Summary(
      monthlyAmount: _roundToCents(monthlyAmount),
      count: incomes.length,
      nextIncomeDate: nextIncomeDate,
    );
  }

  static double _roundToCents(double value) =>
      (value * 100).roundToDouble() / 100;
}
