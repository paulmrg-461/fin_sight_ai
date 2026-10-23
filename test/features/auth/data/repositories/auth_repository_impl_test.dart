import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/core/utils/clock.dart';
import 'package:fin_sight_ai/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:fin_sight_ai/features/auth/data/datasources/session_storage.dart';
import 'package:fin_sight_ai/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:fin_sight_ai/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockSessionStorage extends Mock implements SessionStorage {}

class FixedClock extends Clock {
  const FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

void main() {
  final now = DateTime.utc(2026, 10, 23, 12);

  late MockAuthRemoteDataSource remote;
  late MockSessionStorage storage;

  AuthSession session({DateTime? expiresAt}) {
    return AuthSession(
      accessToken: 'access',
      refreshToken: 'refresh',
      userId: 'user-1',
      email: 'user@example.com',
      expiresAt: expiresAt ?? DateTime.utc(2030),
    );
  }

  AuthRepositoryImpl buildRepository() {
    return AuthRepositoryImpl(remote, storage, clock: FixedClock(now));
  }

  setUp(() {
    remote = MockAuthRemoteDataSource();
    storage = MockSessionStorage();
    when(() => storage.write(any())).thenAnswer((_) async {});
    when(() => storage.clear()).thenAnswer((_) async {});
  });

  setUpAll(() {
    registerFallbackValue(
      AuthSession(
        accessToken: 'fallback',
        refreshToken: 'fallback',
        userId: 'fallback',
        email: 'fallback',
        expiresAt: DateTime.utc(2030),
      ),
    );
  });

  group('AuthRepositoryImpl.signIn', () {
    test('persists the session and exposes the token', () async {
      final expected = session();
      when(() => remote.signIn(email: 'user@example.com', password: 'secret1'))
          .thenAnswer((_) async => expected);
      final repository = buildRepository();

      final result = await repository.signIn(
        email: 'user@example.com',
        password: 'secret1',
      );

      expect(result.getOrElse((_) => fail('Expected session')), expected);
      verify(() => storage.write(expected)).called(1);
      expect(repository.accessToken, 'access');
      expect(repository.isAuthenticated, isTrue);
    });

    test('maps auth exceptions to AuthFailure', () async {
      when(
        () => remote.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        const AuthException(
          'Invalid credentials.',
          code: 'auth_invalid_credentials',
        ),
      );

      final result = await buildRepository().signIn(
        email: 'user@example.com',
        password: 'bad',
      );

      final failure = result.getLeft().toNullable();
      expect(failure, isA<AuthFailure>());
      expect(failure?.code, 'auth_invalid_credentials');
    });

    test('maps unexpected failures', () async {
      when(
        () => remote.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(StateError('boom'));

      final result = await buildRepository().signIn(
        email: 'user@example.com',
        password: 'secret1',
      );

      expect(result.getLeft().toNullable()?.code, 'auth_failed');
    });
  });

  group('AuthRepositoryImpl.restoreSession', () {
    test('returns null when nothing is stored', () async {
      when(() => storage.read()).thenAnswer((_) async => null);

      final result = await buildRepository().restoreSession();

      expect(result.getOrElse((_) => fail('Expected null')), isNull);
    });

    test('restores a valid session', () async {
      final expected = session();
      when(() => storage.read()).thenAnswer((_) async => expected);
      final repository = buildRepository();

      final result = await repository.restoreSession();

      expect(result.getOrElse((_) => null), expected);
      expect(repository.isAuthenticated, isTrue);
    });

    test('refreshes an expired session', () async {
      final expired = session(expiresAt: DateTime.utc(2020));
      final refreshed = session();
      when(() => storage.read()).thenAnswer((_) async => expired);
      when(() => remote.refresh('refresh')).thenAnswer((_) async => refreshed);
      final repository = buildRepository();

      final result = await repository.restoreSession();

      expect(result.getOrElse((_) => null), refreshed);
      verify(() => storage.write(refreshed)).called(1);
    });

    test('clears the session when refresh fails', () async {
      final expired = session(expiresAt: DateTime.utc(2020));
      when(() => storage.read()).thenAnswer((_) async => expired);
      when(() => remote.refresh(any()))
          .thenThrow(const AuthException('Expired.', code: 'auth_http_401'));
      final repository = buildRepository();

      final result = await repository.restoreSession();

      expect(result.getOrElse((_) => fail('Expected null')), isNull);
      verify(() => storage.clear()).called(1);
      expect(repository.isAuthenticated, isFalse);
    });

    test('maps storage failures', () async {
      when(() => storage.read()).thenThrow(Exception('storage'));

      final result = await buildRepository().restoreSession();

      expect(result.getLeft().toNullable()?.code, 'auth_restore_failed');
    });
  });

  group('AuthRepositoryImpl.signOut', () {
    test('clears the session even when the remote call fails', () async {
      final expected = session();
      when(() => storage.read()).thenAnswer((_) async => expected);
      final repository = buildRepository();
      await repository.restoreSession();
      when(
        () => remote.signOut(any()),
      ).thenThrow(const AuthException('Offline.', code: 'auth_network_error'));

      final result = await repository.signOut();

      expect(result.isRight(), isTrue);
      verify(() => storage.clear()).called(1);
      expect(repository.isAuthenticated, isFalse);
    });

    test('maps storage clear failures', () async {
      when(() => storage.clear()).thenThrow(Exception('storage'));

      final result = await buildRepository().signOut();

      expect(result.getLeft().toNullable()?.code, 'auth_storage_failed');
    });
  });

  group('AuthRepositoryImpl.signUp', () {
    test('persists the new session', () async {
      final expected = session();
      when(() => remote.signUp(email: 'user@example.com', password: 'secret1'))
          .thenAnswer((_) async => expected);
      final repository = buildRepository();

      final result = await repository.signUp(
        email: 'user@example.com',
        password: 'secret1',
      );

      expect(result.getOrElse((_) => fail('Expected session')), expected);
      expect(repository.accessToken, 'access');
    });
  });
}
