import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

/// Toggles platform screenshot / recents protection.
abstract interface class SecureScreen {
  Future<void> setEnabled(bool enabled);
}

/// Android implementation backed by `FLAG_SECURE` in `MainActivity`.
@LazySingleton(as: SecureScreen)
class MethodChannelSecureScreen implements SecureScreen {
  const MethodChannelSecureScreen();

  static const String channelName = 'devpaul.fin_sight_ai/secure_screen';

  static const MethodChannel _channel = MethodChannel(channelName);

  @override
  Future<void> setEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod<void>('setSecure', enabled);
    } catch (_) {
      // Unsupported platforms and vendor failures must not block the app.
    }
  }
}
