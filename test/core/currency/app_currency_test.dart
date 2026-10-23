import 'package:fin_sight_ai/core/currency/app_currency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats COP with Colombian separators', () {
    final formatted = MoneyFormatter.format(1234.5, AppCurrency.cop);

    expect(formatted, contains('1.234,50'));
  });

  test('formats USD with US separators', () {
    final formatted = MoneyFormatter.format(1234.5, AppCurrency.usd);

    expect(formatted, contains('1,234.50'));
  });

  test('formats signed amounts', () {
    expect(MoneyFormatter.signed(-120, AppCurrency.cop), startsWith('-'));
    expect(MoneyFormatter.signed(120, AppCurrency.cop), startsWith('+'));
  });

  test('exposes codes, locales, and labels', () {
    expect(AppCurrency.cop.code, 'COP');
    expect(AppCurrency.usd.code, 'USD');
    expect(AppCurrency.cop.locale, 'es_CO');
    expect(AppCurrency.usd.locale, 'en_US');
    expect(AppCurrency.cop.label, contains('Peso colombiano'));
  });
}
