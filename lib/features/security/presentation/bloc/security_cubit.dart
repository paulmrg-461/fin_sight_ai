import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/services/biometric_service.dart';
import '../../../../core/services/security_preferences.dart';
import 'security_state.dart';

@injectable
class SecurityCubit extends Cubit<SecurityState> {
  SecurityCubit(this._preferences, this._biometrics)
    : super(const SecurityState());

  final SecurityPreferences _preferences;
  final BiometricService _biometrics;

  Future<void> load() async {
    final enabled = await _preferences.isBiometricEnabled();
    final available = await _biometrics.isAvailable();
    emit(
      SecurityState(
        loading: false,
        enabled: enabled && available,
        available: available,
      ),
    );
  }

  Future<void> setEnabled(bool enabled) async {
    final available = await _biometrics.isAvailable();
    final next = enabled && available;
    await _preferences.setBiometricEnabled(next);
    emit(state.copyWith(loading: false, enabled: next, available: available));
  }

  Future<bool> authenticate() => _biometrics.authenticate();
}
