import 'package:hive_ce_flutter/hive_flutter.dart';

import 'app_currency.dart';
import 'currency_repository.dart';

/// Hive-backed currency preference. Defaults to COP.
class HiveCurrencyRepository implements CurrencyRepository {
  const HiveCurrencyRepository(this._box);

  static const String _key = 'currency';

  final Box<dynamic> _box;

  @override
  Future<AppCurrency> getCurrency() async {
    final value = _box.get(_key);
    if (value is! String) {
      return AppCurrency.cop;
    }
    return AppCurrency.values.asNameMap()[value.toLowerCase()] ??
        AppCurrency.cop;
  }

  @override
  Future<void> setCurrency(AppCurrency currency) =>
      _box.put(_key, currency.name);
}
