import 'package:fin_sight_ai/core/currency/app_currency.dart';
import 'package:fin_sight_ai/core/domain/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money.parse', () {
    test('parses COP grouping and decimals', () {
      expect(
        Money.parse('1.234,56', currency: AppCurrency.cop).minorUnits,
        123456,
      );
      expect(Money.parse('12,5', currency: AppCurrency.cop).minorUnits, 1250);
      expect(Money.parse('12', currency: AppCurrency.cop).minorUnits, 1200);
      expect(
        Money.parse('1.234', currency: AppCurrency.cop).minorUnits,
        123400,
      );
    });

    test('parses USD grouping and decimals', () {
      expect(
        Money.parse(r'$1,234.56', currency: AppCurrency.usd).minorUnits,
        123456,
      );
      expect(Money.parse('12.5', currency: AppCurrency.usd).minorUnits, 1250);
      expect(Money.parse('12', currency: AppCurrency.usd).minorUnits, 1200);
      expect(
        Money.parse('1,234', currency: AppCurrency.usd).minorUnits,
        123400,
      );
    });

    test('accepts negative amounts', () {
      expect(
        Money.parse('-1.234,56', currency: AppCurrency.cop).minorUnits,
        -123456,
      );
    });

    test('rejects malformed or over-precise input', () {
      expect(
        () => Money.parse('', currency: AppCurrency.usd),
        throwsFormatException,
      );
      expect(
        () => Money.parse('abc', currency: AppCurrency.usd),
        throwsFormatException,
      );
      expect(
        () => Money.parse('12.345', currency: AppCurrency.usd),
        throwsFormatException,
      );
      expect(
        () => Money.parse('12,345', currency: AppCurrency.cop),
        throwsFormatException,
      );
      expect(
        () => Money.parse('1.2,3,4', currency: AppCurrency.cop),
        throwsFormatException,
      );
      expect(
        () => Money.parse('1-2', currency: AppCurrency.usd),
        throwsFormatException,
      );
      expect(
        () => Money.parse('999999999999999', currency: AppCurrency.usd),
        throwsFormatException,
      );
    });
  });

  group('Money', () {
    test('converts to and from major units exactly', () {
      expect(Money.fromMajor(0.1).minorUnits, 10);
      expect(Money.fromMajor(0.29).minorUnits, 29);
      expect(const Money(123456).major, 1234.56);
    });

    test('formats with the active currency', () {
      expect(
        const Money(123456).format(AppCurrency.cop),
        MoneyFormatter.format(1234.56, AppCurrency.cop),
      );
      expect(
        const Money(123456).format(AppCurrency.usd),
        MoneyFormatter.format(1234.56, AppCurrency.usd),
      );
    });

    test('writes exact decimal strings for the wire', () {
      expect(const Money(0).toDecimalString(), '0.00');
      expect(const Money(5).toDecimalString(), '0.05');
      expect(const Money(-123456).toDecimalString(), '-1234.56');
      expect(const Money(100).toDecimalString(), '1.00');
    });

    test('adds, subtracts, multiplies, and negates without drift', () {
      final sum = const Money(10) + const Money(20);
      expect(sum, const Money(30));
      expect((const Money(100) - const Money(250)), const Money(-150));
      expect(const Money(999) * 3, const Money(2997));
      expect(-const Money(75), const Money(-75));
    });

    test('compares by minor units', () {
      expect(const Money(10) < const Money(20), isTrue);
      expect(const Money(20) <= const Money(20), isTrue);
      expect(const Money(30) > const Money(20), isTrue);
      expect(const Money(30) >= const Money(30), isTrue);
      expect(const Money(10).compareTo(const Money(20)), -1);
    });

    test('reads legacy and new JSON shapes', () {
      expect(Money.fromJson(1234), const Money(1234));
      expect(Money.fromJson(12.34), const Money(1234));
      expect(Money.fromJson({'minorUnits': 99}), const Money(99));
      expect(Money.fromJson({'amount': 1.5}), const Money(150));
      expect(() => Money.fromJson('nope'), throwsFormatException);
      expect(() => Money.fromJson({'amount': 'nope'}), throwsFormatException);
    });

    test('uses value equality', () {
      expect(const Money(100), const Money(100));
      expect(const Money(100).hashCode, const Money(100).hashCode);
      expect(const Money(100), isNot(const Money(101)));
      expect(const Money(100).toString(), 'Money(1.00)');
      expect(Money.zero, const Money(0));
    });
  });
}
