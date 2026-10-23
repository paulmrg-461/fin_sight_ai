import 'package:fin_sight_ai/features/ocr/data/parsers/receipt_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = ReceiptParser();
  final now = DateTime.utc(2026, 10, 22, 12);

  group('ReceiptParser', () {
    test('extracts merchant, date, total, currency, and items', () {
      final parsed = parser.parse('''
ACME MARKET
123 Main St
Date: 22/10/2026
Milk 2 x 3.50
Bread 4.50
TOTAL \$11.50
''', now: now);

      expect(parsed.merchantName, 'ACME MARKET');
      expect(parsed.date, DateTime(2026, 10, 22));
      expect(parsed.totalAmount, 11.5);
      expect(parsed.currency, 'USD');
      expect(parsed.items, hasLength(2));
      expect(parsed.items.first.name, 'Milk');
      expect(parsed.items.first.quantity, 2);
      expect(parsed.items.first.price, 3.5);
      expect(parsed.items.last.name, 'Bread');
      expect(parsed.items.last.quantity, 1);
    });

    test('detects ISO dates', () {
      final parsed = parser.parse(
        'Corner Store\n2026-11-05\nTOTAL 20.00',
        now: now,
      );

      expect(parsed.date, DateTime(2026, 11, 5));
    });

    test('defaults ambiguous dates to day/month', () {
      final parsed = parser.parse('Shop\n03/04/2026\nTOTAL 10.00', now: now);

      expect(parsed.date, DateTime(2026, 4, 3));
    });

    test('handles two-digit years', () {
      final parsed = parser.parse('Shop\n22/10/26\nTOTAL 10.00', now: now);

      expect(parsed.date, DateTime(2026, 10, 22));
    });

    test('falls back to the provided date when none is found', () {
      final parsed = parser.parse('Shop\nTOTAL 10.00', now: now);

      expect(parsed.date, now);
    });

    test('ignores impossible calendar dates', () {
      final parsed = parser.parse('Shop\n31/02/2026\nTOTAL 10.00', now: now);

      expect(parsed.date, now);
    });

    test('detects currency codes and symbols', () {
      final euro = parser.parse('Shop\nTOTAL €12,50', now: now);
      final code = parser.parse('Shop\nTOTAL 12.50 EUR', now: now);

      expect(euro.currency, 'EUR');
      expect(euro.totalAmount, 12.5);
      expect(code.currency, 'EUR');
    });

    test('parses thousands separators and comma decimals', () {
      final parsed = parser.parse('Shop\nTOTAL 1.234,56', now: now);

      expect(parsed.totalAmount, 1234.56);
    });

    test('falls back to the largest amount when TOTAL is absent', () {
      final parsed = parser.parse('Shop\nMilk 5.00\nBread 3.00', now: now);

      expect(parsed.totalAmount, 5);
    });

    test('returns zero when no amount is found', () {
      final parsed = parser.parse('Shop\nThank you', now: now);

      expect(parsed.totalAmount, 0);
    });

    test('uses a safe merchant fallback', () {
      final parsed = parser.parse('12345\n67890', now: now);

      expect(parsed.merchantName, 'Unknown merchant');
    });

    test('parses items with currency symbols and quantities', () {
      final parsed = parser.parse(
        'Shop\nCoffee 3 x \$2,50\nTOTAL \$7,50',
        now: now,
      );

      expect(parsed.items.single.name, 'Coffee');
      expect(parsed.items.single.quantity, 3);
      expect(parsed.items.single.price, 2.5);
    });

    test('does not throw on empty input', () {
      final parsed = parser.parse('', now: now);

      expect(parsed.merchantName, 'Unknown merchant');
      expect(parsed.totalAmount, 0);
      expect(parsed.items, isEmpty);
      expect(parsed.currency, 'USD');
      expect(parsed.date, now);
    });
  });
}
