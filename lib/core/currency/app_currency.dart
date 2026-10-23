import 'package:intl/intl.dart';

/// Supported ledger currencies. Amounts are not converted; switching changes
/// the currency label and formatting only.
enum AppCurrency {
  cop,
  usd;

  String get code => name.toUpperCase();

  String get symbol => '\$';

  String get locale => this == AppCurrency.cop ? 'es_CO' : 'en_US';

  String get label =>
      this == AppCurrency.cop ? 'COP — Peso colombiano' : 'USD — US Dollar';
}

/// Formats monetary amounts with the active currency.
abstract final class MoneyFormatter {
  static final Map<AppCurrency, NumberFormat> _formats = {
    for (final currency in AppCurrency.values)
      currency: NumberFormat.currency(
        locale: currency.locale,
        symbol: currency.symbol,
        decimalDigits: 2,
      ),
  };

  static String format(double amount, AppCurrency currency) =>
      _formats[currency]!.format(amount);

  /// Formats with an explicit `+`/`-` prefix (expenses are expected negative).
  static String signed(double amount, AppCurrency currency) {
    final formatted = format(amount.abs(), currency);
    return '${amount < 0 ? '-' : '+'}$formatted';
  }
}
