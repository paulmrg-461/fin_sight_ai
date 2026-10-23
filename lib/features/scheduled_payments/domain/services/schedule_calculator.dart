import '../entities/scheduled_payment_entity.dart';

/// Pure date math for recurring payments.
abstract final class ScheduleCalculator {
  /// Returns a midnight-normalized copy of [date].
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Number of days in the month that contains [date].
  static int daysInMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0).day;

  /// Advances one period from [current], preserving [dayOfMonth] where possible.
  static DateTime advanceOnce({
    required DateTime current,
    required PaymentFrequency frequency,
    required int dayOfMonth,
  }) {
    switch (frequency) {
      case PaymentFrequency.monthly:
        final target = DateTime(current.year, current.month + 1);
        final day = dayOfMonth.clamp(1, daysInMonth(target));
        return DateTime(target.year, target.month, day);
      case PaymentFrequency.yearly:
        final year = current.year + 1;
        final target = DateTime(year, current.month);
        final day = dayOfMonth.clamp(1, daysInMonth(target));
        return DateTime(year, current.month, day);
    }
  }

  /// Advances from [current] until the result is strictly after [cutoff].
  ///
  /// [maxIterations] guards against pathological dates; the caller receives
  /// the last computed date when the guard is hit.
  static DateTime advancePast({
    required DateTime current,
    required PaymentFrequency frequency,
    required int dayOfMonth,
    required DateTime cutoff,
    int maxIterations = 60,
  }) {
    var next = dateOnly(current);
    final limit = dateOnly(cutoff);
    var iterations = 0;
    while (!next.isAfter(limit) && iterations < maxIterations) {
      next = advanceOnce(
        current: next,
        frequency: frequency,
        dayOfMonth: dayOfMonth,
      );
      iterations++;
    }
    return next;
  }
}
