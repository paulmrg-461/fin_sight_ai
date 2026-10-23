import 'dart:convert';

import 'package:fin_sight_ai/features/auth/data/datasources/secure_session_storage.dart';
import 'package:fin_sight_ai/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage storage;
  late SecureSessionStorage sessionStorage;

  final session = AuthSession(
    accessToken: 'access',
    refreshToken: 'refresh',
    userId: 'user-1',
    email: 'user@example.com',
    expiresAt: DateTime.utc(2030),
  );

  setUp(() {
    storage = MockFlutterSecureStorage();
    sessionStorage = SecureSessionStorage.withStorage(storage);
  });

  test('writes the session as JSON', () async {
    when(
      () => storage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});

    await sessionStorage.write(session);

    final captured = verify(
      () => storage.write(
        key: captureAny(named: 'key'),
        value: captureAny(named: 'value'),
      ),
    ).captured;
    expect(captured[0], 'finsight.auth.session');
    final json = jsonDecode(captured[1] as String) as Map<String, dynamic>;
    expect(json['accessToken'], 'access');
  });

  test('reads and maps a stored session', () async {
    final encoded = jsonEncode({
      'accessToken': 'access',
      'refreshToken': 'refresh',
      'userId': 'user-1',
      'email': 'user@example.com',
      'expiresAt': '2030-01-01T00:00:00.000Z',
    });
    when(() => storage.read(key: any(named: 'key')))
        .thenAnswer((_) async => encoded);

    final restored = await sessionStorage.read();

    expect(restored?.accessToken, 'access');
    expect(restored?.email, 'user@example.com');
  });

  test('returns null when nothing is stored', () async {
    when(() => storage.read(key: any(named: 'key')))
        .thenAnswer((_) async => null);

    expect(await sessionStorage.read(), isNull);
  });

  test('rejects malformed stored data', () async {
    when(() => storage.read(key: any(named: 'key')))
        .thenAnswer((_) async => 'not-json');

    await expectLater(sessionStorage.read(), throwsFormatException);
  });

  test('clears the stored session', () async {
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {});

    await sessionStorage.clear();

    verify(() => storage.delete(key: any(named: 'key'))).called(1);
  });
}
