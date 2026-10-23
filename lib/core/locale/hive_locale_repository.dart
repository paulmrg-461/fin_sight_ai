import 'package:flutter/widgets.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'locale_repository.dart';

/// Hive-backed language preference.
class HiveLocaleRepository implements LocaleRepository {
  const HiveLocaleRepository(this._box);

  static const String _key = 'locale';

  final Box<dynamic> _box;

  @override
  Future<Locale?> getLocale() async {
    final value = _box.get(_key);
    if (value is! String || value == 'system') {
      return null;
    }
    return switch (value) {
      'en' => const Locale('en'),
      'es' => const Locale('es'),
      _ => null,
    };
  }

  @override
  Future<void> setLocale(Locale? locale) =>
      _box.put(_key, locale?.languageCode ?? 'system');
}
