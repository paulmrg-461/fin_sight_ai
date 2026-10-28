import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';

/// Device biometric / credential prompt behind a testable interface.
abstract interface class BiometricService {
  Future<bool> isAvailable();

  Future<bool> authenticate();
}

@LazySingleton(as: BiometricService)
class LocalAuthBiometricService implements BiometricService {
  LocalAuthBiometricService();

  final LocalAuthentication _auth = LocalAuthentication();

  @override
  Future<bool> isAvailable() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock FinSight AI',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}
