import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/features/auth/domain/entities/auth_session.dart';
import 'package:fin_sight_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:fin_sight_ai/features/auth/domain/usecases/auth_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;

  final session = AuthSession(
    accessToken: 'access',
    refreshToken: 'refresh',
    userId: 'user-1',
    email: 'user@example.com',
    expiresAt: DateTime.utc(2026, 10, 23, 12),
  );

  setUp(() {
    repository = MockAuthRepository();
  });

  group('SignInUseCase', () {
    test('trims the email and delegates', () async {
      when(
        () => repository.signIn(email: 'user@example.com', password: 'secret1'),
      ).thenAnswer((_) async => Right(session));

      final result = await SignInUseCase(repository)(
        const SignInParams(email: '  user@example.com  ', password: 'secret1'),
      );

      expect(result.getOrElse((_) => fail('Expected session')), session);
    });

    test('rejects an invalid email', () async {
      final result = await SignInUseCase(repository)(
        const SignInParams(email: 'not-an-email', password: 'secret1'),
      );

      expect(result.getLeft().toNullable()?.code, 'invalid_email');
      verifyNever(
        () => repository.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });

    test('rejects a short password', () async {
      final result = await SignInUseCase(repository)(
        const SignInParams(email: 'user@example.com', password: '123'),
      );

      expect(result.getLeft().toNullable()?.code, 'weak_password');
    });

    test('propagates auth failures', () async {
      const failure = AuthFailure('Invalid credentials.');
      when(
        () => repository.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      final result = await SignInUseCase(repository)(
        const SignInParams(email: 'user@example.com', password: 'secret1'),
      );

      expect(result.getLeft().toNullable(), failure);
    });
  });

  group('SignUpUseCase', () {
    test('delegates valid credentials', () async {
      when(
        () => repository.signUp(email: 'user@example.com', password: 'secret1'),
      ).thenAnswer((_) async => Right(session));

      final result = await SignUpUseCase(repository)(
        const SignUpParams(email: 'user@example.com', password: 'secret1'),
      );

      expect(result.getOrElse((_) => fail('Expected session')), session);
    });

    test('validates input before calling the repository', () async {
      final result = await SignUpUseCase(repository)(
        const SignUpParams(email: 'bad', password: '123'),
      );

      expect(result.getLeft().toNullable()?.code, 'invalid_email');
    });
  });

  group('session use cases', () {
    test('RestoreSessionUseCase delegates', () async {
      when(() => repository.restoreSession())
          .thenAnswer((_) async => Right(session));

      final result = await RestoreSessionUseCase(repository)(const NoParams());

      expect(result.getOrElse((_) => null), session);
    });

    test('SignOutUseCase delegates', () async {
      when(() => repository.signOut())
          .thenAnswer((_) async => const Right(null));

      final result = await SignOutUseCase(repository)(const NoParams());

      expect(result.isRight(), isTrue);
    });
  });
}
