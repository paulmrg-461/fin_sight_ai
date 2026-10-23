import 'dart:convert';

import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/core/utils/app_env.dart';
import 'package:fin_sight_ai/features/ai_coach/data/datasources/groq_api_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

AppEnv env({String key = 'test-key'}) {
  return AppEnv(supabaseUrl: '', supabaseAnonKey: '', groqApiKey: key);
}

String successBody(String content) {
  return jsonEncode({
    'choices': [
      {
        'message': {'role': 'assistant', 'content': content},
      },
    ],
  });
}

void main() {
  group('GroqApiDatasource', () {
    test('returns the model content and sends the expected request', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(
          successBody('{"type":"analysis","content":"Stable spending."}'),
          200,
        );
      });
      final datasource = GroqApiDatasource(client, env());

      final content = await datasource.callGroqApi(
        'Analyze my spending.',
        'Income: 1000. Expenses: 400.',
      );

      expect(content, contains('Stable spending.'));
      expect(captured.url.toString(), GroqApiDatasource.endpoint);
      expect(captured.headers['Authorization'], 'Bearer test-key');
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['model'], GroqApiDatasource.model);
      final messages = body['messages'] as List<dynamic>;
      expect(messages, hasLength(2));
      final userMessage = messages.last as Map<String, dynamic>;
      expect(userMessage['content'], contains('Analyze my spending.'));
      expect(userMessage['content'], contains('Income: 1000'));
    });

    test('throws when the API key is missing', () async {
      final client = MockClient((request) async {
        fail('HTTP should not be called without an API key');
      });
      final datasource = GroqApiDatasource(client, env(key: ''));

      await expectLater(
        datasource.callGroqApi('prompt', 'context'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.code,
            'code',
            'groq_not_configured',
          ),
        ),
      );
    });

    test('maps non-200 responses to an HTTP failure', () async {
      final client = MockClient(
        (request) async => http.Response('unauthorized', 401),
      );
      final datasource = GroqApiDatasource(client, env());

      await expectLater(
        datasource.callGroqApi('prompt', 'context'),
        throwsA(
          isA<ServerException>().having((e) => e.code, 'code', 'groq_http_401'),
        ),
      );
    });

    test('rejects invalid JSON envelopes', () async {
      final client = MockClient(
        (request) async => http.Response('not-json', 200),
      );
      final datasource = GroqApiDatasource(client, env());

      await expectLater(
        datasource.callGroqApi('prompt', 'context'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.code,
            'code',
            'groq_invalid_response',
          ),
        ),
      );
    });

    test('rejects responses without choices', () async {
      final client = MockClient(
        (request) async => http.Response('{"choices":[]}', 200),
      );
      final datasource = GroqApiDatasource(client, env());

      await expectLater(
        datasource.callGroqApi('prompt', 'context'),
        throwsA(isA<ServerException>()),
      );
    });

    test('rejects empty content', () async {
      final client = MockClient(
        (request) async => http.Response(successBody('  '), 200),
      );
      final datasource = GroqApiDatasource(client, env());

      await expectLater(
        datasource.callGroqApi('prompt', 'context'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.code,
            'code',
            'groq_invalid_response',
          ),
        ),
      );
    });

    test('maps network errors to a stable code', () async {
      final client = MockClient((request) async {
        throw http.ClientException('offline');
      });
      final datasource = GroqApiDatasource(client, env());

      await expectLater(
        datasource.callGroqApi('prompt', 'context'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.code,
            'code',
            'groq_network_error',
          ),
        ),
      );
    });
  });
}
