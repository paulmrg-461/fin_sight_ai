import '../../../../core/usecase/usecase.dart';
import '../entities/auth_session.dart';

/// Exposes the current access token to infrastructure clients.
abstract interface class AuthTokenProvider {
  String? get accessToken;

  bool get isAuthenticated;
}

/// Domain contract for Supabase authentication.
abstract interface class AuthRepository implements AuthTokenProvider {
  ResultFuture<AuthSession> signIn({
    required String email,
    required String password,
  });

  ResultFuture<AuthSession> signUp({
    required String email,
    required String password,
  });

  /// Restores a persisted session, refreshing it when expired.
  ///
  /// Returns `Right(null)` when there is no session or it can no longer be
  /// refreshed.
  ResultFuture<AuthSession?> restoreSession();

  ResultFuture<void> signOut();
}
