import 'dart:convert';

import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/core/utils/app_env.dart';
import 'package:fin_sight_ai/features/auth/data/datasources/supabase_auth_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

AppEnv configuredEnv() => const AppEnv(
  supabaseUrl: 'https://demo.supabase.co',
  supabaseAnonKey: 'anon-key',
  groqApiKey: '',
);

String sessionBody() => jsonEncode({
  'access_token': 'access-token',
  'refresh_token': 'refresh-token',
  'expires_at': 1893456000,
  'user': {'id': 'user-1', 'email': 'user@example.com'},
});

void main() {
  group('SupabaseAuthDataSource', () {
    test('signs in and parses the session', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(sessionBody(), 200);
      });
      final datasource = SupabaseAuthDataSource(client, configuredEnv());

      final session = await datasource.signIn(
        email: 'user@example.com',
        password: 'secret1',
      );

      expect(session.accessToken, 'access-token');
      expect(session.refreshToken, 'refresh-token');
      expect(session.userId, 'user-1');
      expect(session.email, 'user@example.com');
      expect(captured.url.path, '/auth/v1/token');
      expect(captured.url.queryParameters['grant_type'], 'password');
      expect(captured.headers['apikey'], 'anon-key');
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['email'], 'user@example.com');
      expect(body['password'], 'secret1');
    });

    test('maps invalid credentials', () async {
      final client = MockClient(
        (request) async => http.Response('invalid', 400),
      );
      final datasource = SupabaseAuthDataSource(client, configuredEnv());

      await expectLater(
        datasource.signIn(email: 'user@example.com', password: 'bad'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.code,
            'code',
            'auth_invalid_credentials',
          ),
        ),
      );
    });

    test('requires email confirmation when signup has no session', () async {
      final client = MockClient(
        (request) async => http.Response(
          jsonEncode({
            'user': {'id': 'user-1', 'email': 'user@example.com'},
          }),
          200,
        ),
      );
      final datasource = SupabaseAuthDataSource(client, configuredEnv());

      await expectLater(
        datasource.signUp(email: 'user@example.com', password: 'secret1'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.code,
            'code',
            'auth_email_confirmation_required',
          ),
        ),
      );
    });

    test('returns a session when signup is auto-confirmed', () async {
      final client = MockClient(
        (request) async => http.Response(sessionBody(), 200),
      );
      final datasource = SupabaseAuthDataSource(client, configuredEnv());

      final session = await datasource.signUp(
        email: 'user@example.com',
        password: 'secret1',
      );

      expect(session.userId, 'user-1');
    });

    test('refreshes a session', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(sessionBody(), 200);
      });
      final datasource = SupabaseAuthDataSource(client, configuredEnv());

      final session = await datasource.refresh('refresh-token');

      expect(session.accessToken, 'access-token');
      expect(captured.url.queryParameters['grant_type'], 'refresh_token');
    });

    test('signs out with the access token', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response('', 204);
      });
      final datasource = SupabaseAuthDataSource(client, configuredEnv());

      await datasource.signOut('access-token');

      expect(captured.method, 'POST');
      expect(captured.url.path, '/auth/v1/logout');
      expect(captured.headers['Authorization'], 'Bearer access-token');
    });

    test('rejects calls without configuration', () async {
      final client = MockClient((request) async {
        fail('HTTP must not be called when unconfigured');
      });
      final datasource = SupabaseAuthDataSource(
        client,
        const AppEnv(supabaseUrl: '', supabaseAnonKey: '', groqApiKey: ''),
      );

      await expectLater(
        datasource.signIn(email: 'user@example.com', password: 'secret1'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.code,
            'code',
            'auth_not_configured',
          ),
        ),
      );
    });

    test('maps network errors', () async {
      final client = MockClient((request) async {
        throw http.ClientException('offline');
      });
      final datasource = SupabaseAuthDataSource(client, configuredEnv());

      await expectLater(
        datasource.signIn(email: 'user@example.com', password: 'secret1'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.code,
            'code',
            'auth_network_error',
          ),
        ),
      );
    });

    test('rejects invalid session payloads', () async {
      final client = MockClient(
        (request) async => http.Response('{"not":"a session"}', 200),
      );
      final datasource = SupabaseAuthDataSource(client, configuredEnv());

      await expectLater(
        datasource.signIn(email: 'user@example.com', password: 'secret1'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.code,
            'code',
            'auth_invalid_response',
          ),
        ),
      );
    });
  });
}
