import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/services/biometric_service.dart';
import '../../../../core/services/secure_screen.dart';
import '../../../../core/services/security_preferences.dart';
import 'security_state.dart';

@injectable
class SecurityCubit extends Cubit<SecurityState> {
  SecurityCubit(this._preferences, this._biometrics, {this.secureScreen})
    : super(const SecurityState());

  final SecurityPreferences _preferences;
  final BiometricService _biometrics;
  final SecureScreen? secureScreen;

  Future<void> load() async {
    final enabled = await _preferences.isBiometricEnabled();
    final available = await _biometrics.isAvailable();
    final active = enabled && available;
    emit(SecurityState(loading: false, enabled: active, available: available));
    await _applySecureScreen(active);
  }

  Future<void> setEnabled(bool enabled) async {
    final available = await _biometrics.isAvailable();
    final next = enabled && available;
    await _preferences.setBiometricEnabled(next);
    emit(state.copyWith(loading: false, enabled: next, available: available));
    await _applySecureScreen(next);
  }

  Future<bool> authenticate() => _biometrics.authenticate();

  Future<void> _applySecureScreen(bool enabled) async {
    try {
      await secureScreen?.setEnabled(enabled);
    } catch (_) {
      // Screenshot protection is best effort.
    }
  }
}
