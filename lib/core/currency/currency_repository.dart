import 'app_currency.dart';

/// Persists the user's display/ledger currency.
abstract interface class CurrencyRepository {
  Future<AppCurrency> getCurrency();

  Future<void> setCurrency(AppCurrency currency);
}
