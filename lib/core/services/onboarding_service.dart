import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

import 'app_boxes.dart';

/// Tracks whether the first-run tour has been completed on this device.
abstract interface class OnboardingService {
  Future<bool> isCompleted();

  Future<void> complete();
}

@LazySingleton(as: OnboardingService)
class HiveOnboardingService implements OnboardingService {
  const HiveOnboardingService(this._boxes);

  static const String key = 'onboarding_completed_v1';

  final AppBoxes _boxes;

  Box<dynamic> get _box => _boxes.settings;

  @override
  Future<bool> isCompleted() async {
    try {
      return _box.get(key) == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> complete() async {
    try {
      await _box.put(key, true);
    } catch (_) {
      // A settings failure should not trap the user in onboarding.
    }
  }
}
