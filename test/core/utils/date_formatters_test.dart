import 'package:fin_sight_ai/core/utils/date_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatDisplayDate renders zero-padded dd/MM/yyyy', () {
    expect(formatDisplayDate(DateTime(2026, 1, 5)), '05/01/2026');
  });

  test('startOfDay drops the time component', () {
    final result = startOfDay(DateTime(2026, 10, 22, 18, 45, 12));

    expect(result, DateTime(2026, 10, 22));
  });

  test('endOfDay points to the last millisecond of the day', () {
    final result = endOfDay(DateTime(2026, 10, 22, 8));

    expect(result, DateTime(2026, 10, 22, 23, 59, 59, 999));
  });
}
