import 'package:flutter/widgets.dart';

/// Persists the user's language choice. `null` means follow the system.
abstract interface class LocaleRepository {
  Future<Locale?> getLocale();

  Future<void> setLocale(Locale? locale);
}
