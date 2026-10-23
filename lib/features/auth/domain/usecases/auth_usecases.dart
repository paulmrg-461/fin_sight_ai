import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class SignInParams {
  const SignInParams({required this.email, required this.password});

  final String email;
  final String password;
}

class SignUpParams {
  const SignUpParams({required this.email, required this.password});

  final String email;
  final String password;
}

@lazySingleton
class SignInUseCase implements UseCase<AuthSession, SignInParams> {
  const SignInUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<AuthSession>> call(SignInParams params) {
    final validation = _validate(params.email, params.password);
    if (validation != null) {
      return Future.value(Left(validation));
    }
    return _repository.signIn(
      email: params.email.trim(),
      password: params.password,
    );
  }
}

@lazySingleton
class SignUpUseCase implements UseCase<AuthSession, SignUpParams> {
  const SignUpUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<AuthSession>> call(SignUpParams params) {
    final validation = _validate(params.email, params.password);
    if (validation != null) {
      return Future.value(Left(validation));
    }
    return _repository.signUp(
      email: params.email.trim(),
      password: params.password,
    );
  }
}

@lazySingleton
class RestoreSessionUseCase implements UseCase<AuthSession?, NoParams> {
  const RestoreSessionUseCase(this._repository);

  final AuthRepository _repository;

  @override
  ResultFuture<AuthSession?> call(NoParams params) =>
      _repository.restoreSession();
}

@lazySingleton
class SignOutUseCase implements UseCase<void, NoParams> {
  const SignOutUseCase(this._repository);

  final AuthRepository _repository;

  @override
  ResultFuture<void> call(NoParams params) => _repository.signOut();
}

Failure? _validate(String email, String password) {
  final normalizedEmail = email.trim();
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalizedEmail)) {
    return const ValidationFailure(
      'Enter a valid email address.',
      code: 'invalid_email',
    );
  }
  if (password.length < 6) {
    return const ValidationFailure(
      'Password must be at least 6 characters.',
      code: 'weak_password',
    );
  }
  return null;
}
