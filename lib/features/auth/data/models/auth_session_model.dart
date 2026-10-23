import '../../domain/entities/auth_session.dart';

/// JSON representation of [AuthSession].
class AuthSessionModel extends AuthSession {
  const AuthSessionModel({
    required super.accessToken,
    required super.refreshToken,
    required super.userId,
    required super.email,
    required super.expiresAt,
  });

  factory AuthSessionModel.fromEntity(AuthSession session) {
    return AuthSessionModel(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      userId: session.userId,
      email: session.email,
      expiresAt: session.expiresAt,
    );
  }

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    final accessToken = json['accessToken'];
    final refreshToken = json['refreshToken'];
    final userId = json['userId'];
    final email = json['email'];
    final expiresAt = json['expiresAt'];

    if (accessToken is! String || accessToken.isEmpty) {
      throw const FormatException('Access token is missing.');
    }
    if (refreshToken is! String || refreshToken.isEmpty) {
      throw const FormatException('Refresh token is missing.');
    }
    if (userId is! String || userId.isEmpty) {
      throw const FormatException('User id is missing.');
    }
    if (email is! String) {
      throw const FormatException('Email is missing.');
    }
    if (expiresAt is! String) {
      throw const FormatException('Session expiry is missing.');
    }

    return AuthSessionModel(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      email: email,
      expiresAt: DateTime.parse(expiresAt),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'userId': userId,
      'email': email,
      'expiresAt': expiresAt.toUtc().toIso8601String(),
    };
  }

  AuthSession toEntity() {
    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      email: email,
      expiresAt: expiresAt,
    );
  }
}
