import 'package:fin_sight_ai/features/scheduled_payments/domain/entities/scheduled_payment_entity.dart';
import 'package:fin_sight_ai/features/scheduled_payments/domain/services/schedule_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizes dates to midnight', () {
    expect(
      ScheduleCalculator.dateOnly(DateTime(2026, 10, 23, 18, 45)),
      DateTime(2026, 10, 23),
    );
  });

  test('advances monthly and clamps short months', () {
    final february = ScheduleCalculator.advanceOnce(
      current: DateTime(2026, 1, 31),
      frequency: PaymentFrequency.monthly,
      dayOfMonth: 31,
    );
    expect(february, DateTime(2026, 2, 28));

    final march = ScheduleCalculator.advanceOnce(
      current: february,
      frequency: PaymentFrequency.monthly,
      dayOfMonth: 31,
    );
    expect(march, DateTime(2026, 3, 31));
  });

  test('keeps leap-day monthly schedules on the 29th', () {
    final february = ScheduleCalculator.advanceOnce(
      current: DateTime(2028, 1, 31),
      frequency: PaymentFrequency.monthly,
      dayOfMonth: 31,
    );
    expect(february, DateTime(2028, 2, 29));
  });

  test('advances yearly and clamps leap days', () {
    final next = ScheduleCalculator.advanceOnce(
      current: DateTime(2028, 2, 29),
      frequency: PaymentFrequency.yearly,
      dayOfMonth: 29,
    );
    expect(next, DateTime(2029, 2, 28));
  });

  test('advances past a cutoff', () {
    final next = ScheduleCalculator.advancePast(
      current: DateTime(2026, 1, 31),
      frequency: PaymentFrequency.monthly,
      dayOfMonth: 31,
      cutoff: DateTime(2026, 3, 15),
    );
    expect(next, DateTime(2026, 3, 31));
  });

  test('stops at the iteration guard', () {
    final next = ScheduleCalculator.advancePast(
      current: DateTime(2026, 1, 1),
      frequency: PaymentFrequency.monthly,
      dayOfMonth: 1,
      cutoff: DateTime(2035, 1, 1),
      maxIterations: 3,
    );
    expect(next, DateTime(2026, 4, 1));
  });
}
