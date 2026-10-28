import 'package:fin_sight_ai/core/services/biometric_service.dart';
import 'package:fin_sight_ai/core/services/secure_screen.dart';
import 'package:fin_sight_ai/core/services/security_preferences.dart';
import 'package:fin_sight_ai/features/security/presentation/bloc/security_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class _Preferences implements SecurityPreferences {
  _Preferences({this.enabled = false});

  bool enabled;

  @override
  Future<bool> isBiometricEnabled() async => enabled;

  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    this.enabled = enabled;
  }
}

class _SecureScreen implements SecureScreen {
  final List<bool> states = [];

  @override
  Future<void> setEnabled(bool enabled) async => states.add(enabled);
}

class _Biometrics implements BiometricService {
  _Biometrics({this.available = true, this.result = true});

  bool available;
  bool result;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate() async => result;
}

void main() {
  test(
    'load reports the stored preference when biometrics are available',
    () async {
      final cubit = SecurityCubit(_Preferences(enabled: true), _Biometrics());
      addTearDown(cubit.close);

      await cubit.load();

      expect(cubit.state.loading, isFalse);
      expect(cubit.state.enabled, isTrue);
      expect(cubit.state.available, isTrue);
    },
  );

  test('load keeps the lock off when biometrics are unavailable', () async {
    final cubit = SecurityCubit(
      _Preferences(enabled: true),
      _Biometrics(available: false),
    );
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.enabled, isFalse);
    expect(cubit.state.available, isFalse);
  });

  test('setEnabled persists the preference and updates the state', () async {
    final preferences = _Preferences();
    final cubit = SecurityCubit(preferences, _Biometrics());
    addTearDown(cubit.close);

    await cubit.setEnabled(true);

    expect(preferences.enabled, isTrue);
    expect(cubit.state.enabled, isTrue);
    expect(cubit.state.loading, isFalse);
  });

  test('setEnabled refuses to enable without biometric support', () async {
    final preferences = _Preferences();
    final cubit = SecurityCubit(preferences, _Biometrics(available: false));
    addTearDown(cubit.close);

    await cubit.setEnabled(true);

    expect(preferences.enabled, isFalse);
    expect(cubit.state.enabled, isFalse);
  });

  test('toggles screenshot protection with the lock', () async {
    final screen = _SecureScreen();
    final cubit = SecurityCubit(
      _Preferences(enabled: true),
      _Biometrics(),
      secureScreen: screen,
    );
    addTearDown(cubit.close);

    await cubit.load();
    await cubit.setEnabled(false);
    await cubit.setEnabled(true);

    expect(screen.states, [true, false, true]);
  });

  test('authenticate delegates to the biometric service', () async {
    final cubit = SecurityCubit(_Preferences(), _Biometrics(result: false));
    addTearDown(cubit.close);

    expect(await cubit.authenticate(), isFalse);
  });
}
