import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/services/local_data_scope.dart';
import 'package:fin_sight_ai/features/auth/data/datasources/session_storage.dart';
import 'package:fin_sight_ai/features/auth/data/services/account_scope_service.dart';
import 'package:fin_sight_ai/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSessionStorage extends Mock implements SessionStorage {}

class MockLocalDataScope extends Mock implements LocalDataScope {}

void main() {
  final session = AuthSession(
    accessToken: 'access',
    refreshToken: 'refresh',
    userId: 'user-1',
    email: 'user@example.com',
    expiresAt: DateTime.utc(2026, 10, 23, 12),
  );

  late MockSessionStorage storage;
  late MockLocalDataScope scope;

  setUp(() {
    storage = MockSessionStorage();
    scope = MockLocalDataScope();
    when(() => scope.getOwnerUserId()).thenAnswer((_) async => null);
    when(() => scope.setOwnerUserId(any())).thenAnswer((_) async {});
    when(() => scope.clearAllUserData()).thenAnswer((_) async {});
  });

  AccountScopeService buildService() => AccountScopeService(storage, scope);

  test('does nothing when no session is stored', () async {
    when(() => storage.read()).thenAnswer((_) async => null);

    final result = await buildService().ensure();

    expect(result.getOrElse((_) => true), isFalse);
    verifyNever(() => scope.getOwnerUserId());
    verifyNever(() => scope.clearAllUserData());
  });

  test('adopts the session owner when none is recorded', () async {
    when(() => storage.read()).thenAnswer((_) async => session);

    final result = await buildService().ensure();

    expect(result.getOrElse((_) => true), isFalse);
    verify(() => scope.setOwnerUserId('user-1')).called(1);
    verifyNever(() => scope.clearAllUserData());
  });

  test('keeps data when the owner matches the session', () async {
    when(() => storage.read()).thenAnswer((_) async => session);
    when(() => scope.getOwnerUserId()).thenAnswer((_) async => 'user-1');

    final result = await buildService().ensure();

    expect(result.getOrElse((_) => true), isFalse);
    verifyNever(() => scope.clearAllUserData());
    verifyNever(() => scope.setOwnerUserId(any()));
  });

  test('erases data when the owner does not match the session', () async {
    when(() => storage.read()).thenAnswer((_) async => session);
    when(() => scope.getOwnerUserId()).thenAnswer((_) async => 'user-2');

    final result = await buildService().ensure();

    expect(result.getOrElse((_) => false), isTrue);
    verify(() => scope.clearAllUserData()).called(1);
    verify(() => scope.setOwnerUserId('user-1')).called(1);
  });

  test('maps storage failures to CacheFailure', () async {
    when(() => storage.read()).thenThrow(Exception('secure storage'));

    final result = await buildService().ensure();

    final failure = result.getLeft().toNullable();
    expect(failure, isA<CacheFailure>());
    expect(failure?.code, 'local_scope_failed');
  });

  test('maps scope failures to CacheFailure', () async {
    when(() => storage.read()).thenAnswer((_) async => session);
    when(() => scope.getOwnerUserId()).thenThrow(Exception('hive'));

    final result = await buildService().ensure();

    expect(result.getLeft().toNullable()?.code, 'local_scope_failed');
  });
}
