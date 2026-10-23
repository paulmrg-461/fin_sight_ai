import '../../domain/entities/auth_session.dart';

/// Persists the authenticated session between app launches.
abstract interface class SessionStorage {
  Future<AuthSession?> read();

  Future<void> write(AuthSession session);

  Future<void> clear();
}
