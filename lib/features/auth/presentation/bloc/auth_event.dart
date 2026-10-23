import 'package:equatable/equatable.dart';

/// Base event for authentication.
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => const [];
}

/// Restores a persisted session on startup.
final class RestoreAuthSession extends AuthEvent {
  const RestoreAuthSession();
}

/// Signs in with email and password.
final class SignInRequested extends AuthEvent {
  const SignInRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// Creates an account with email and password.
final class SignUpRequested extends AuthEvent {
  const SignUpRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// Clears the current session.
final class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}
