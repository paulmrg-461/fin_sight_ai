import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

import 'app_boxes.dart';

abstract interface class SecurityPreferences {
  Future<bool> isBiometricEnabled();

  Future<void> setBiometricEnabled(bool enabled);
}

@LazySingleton(as: SecurityPreferences)
class HiveSecurityPreferences implements SecurityPreferences {
  const HiveSecurityPreferences(this._boxes);

  static const String key = 'biometric_lock_enabled';

  final AppBoxes _boxes;

  Box<dynamic> get _box => _boxes.settings;

  @override
  Future<bool> isBiometricEnabled() async {
    try {
      return _box.get(key) == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _box.put(key, enabled);
    } catch (_) {
      // Preferences are best effort; the gate stays unlocked on failure.
    }
  }
}
