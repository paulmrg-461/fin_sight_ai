/// Authenticated Supabase session.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.email,
    required this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final String userId;
  final String email;
  final DateTime expiresAt;

  bool get isExpired => !expiresAt.isAfter(DateTime.now());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthSession &&
          other.accessToken == accessToken &&
          other.refreshToken == refreshToken &&
          other.userId == userId &&
          other.email == email &&
          other.expiresAt == expiresAt;

  @override
  int get hashCode =>
      Object.hash(accessToken, refreshToken, userId, email, expiresAt);

  @override
  String toString() => 'AuthSession(user: $email)';
}
