import '../../domain/entities/auth_session.dart';

/// Supabase Auth (GoTrue) contract.
abstract interface class AuthRemoteDataSource {
  Future<AuthSession> signIn({required String email, required String password});

  Future<AuthSession> signUp({required String email, required String password});

  Future<AuthSession> refresh(String refreshToken);

  Future<void> signOut(String accessToken);
}
