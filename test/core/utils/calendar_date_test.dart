import 'package:fin_sight_ai/core/utils/calendar_date.dart';
import 'package:fin_sight_ai/core/utils/date_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calendarDate', () {
    test('preserves the local calendar day and drops the time of day', () {
      final result = calendarDate(DateTime(2026, 10, 31, 20, 30, 45, 120));

      expect(result, DateTime.utc(2026, 10, 31, 12));
      expect(result.year, 2026);
      expect(result.month, 10);
      expect(result.day, 31);
      expect(result.isUtc, isTrue);
      expect(isCalendarDate(result), isTrue);
    });

    test('keeps an already normalized date unchanged', () {
      final value = DateTime.utc(2026, 10, 31, 12);

      expect(calendarDate(value), value);
    });

    test('a late evening input formats as the same calendar day', () {
      final result = calendarDate(DateTime(2026, 10, 31, 20, 30));

      expect(result, DateTime.utc(2026, 10, 31, 12));
      expect(formatDisplayDate(result), '31/10/2026');
    });
  });

  group('calendarMonth', () {
    test('drops the day and time and stores the first day at UTC noon', () {
      final result = calendarMonth(DateTime(2026, 11, 20, 18, 15));

      expect(result, DateTime.utc(2026, 11, 1, 12));
      expect(result.year, 2026);
      expect(result.month, 11);
      expect(result.day, 1);
      expect(result.isUtc, isTrue);
      expect(isCalendarDate(result), isTrue);
    });
  });

  group('isCalendarDate', () {
    test('rejects local values and non-noon UTC values', () {
      expect(isCalendarDate(DateTime(2026, 10, 31, 12)), isFalse);
      expect(isCalendarDate(DateTime.utc(2026, 10, 31)), isFalse);
      expect(isCalendarDate(DateTime.utc(2026, 10, 31, 13)), isFalse);
    });
  });
}
