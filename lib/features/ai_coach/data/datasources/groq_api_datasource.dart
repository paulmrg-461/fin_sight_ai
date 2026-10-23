import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/app_env.dart';
import 'ai_coach_datasource.dart';

/// Groq chat-completions implementation of [AiCoachDatasource].
@LazySingleton(as: AiCoachDatasource)
class GroqApiDatasource implements AiCoachDatasource {
  GroqApiDatasource(this._client, this._env);

  static const String endpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String model = 'openai/gpt-oss-20b';
  static const Duration timeout = Duration(seconds: 15);
  static const String systemPrompt =
      'You are FinSight AI, a precise personal finance coach. '
      'Always follow the requested response format.';

  final http.Client _client;
  final AppEnv _env;

  @override
  Future<String> callGroqApi(String prompt, String context) async {
    if (_env.groqApiKey.isEmpty) {
      throw const ServerException(
        'The AI coach is not configured.',
        code: 'groq_not_configured',
      );
    }

    try {
      final response = await _client
          .post(
            Uri.parse(endpoint),
            headers: <String, String>{
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${_env.groqApiKey}',
            },
            body: jsonEncode(<String, dynamic>{
              'model': model,
              'temperature': 0.4,
              'max_tokens': 512,
              'messages': [
                <String, String>{'role': 'system', 'content': systemPrompt},
                <String, String>{
                  'role': 'user',
                  'content':
                      '$prompt\n\nFinancial context:\n'
                      '${context.trim().isEmpty ? 'No context provided.' : context.trim()}',
                },
              ],
            }),
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw ServerException(
          'The AI coach request failed.',
          code: 'groq_http_${response.statusCode}',
        );
      }

      final content = _extractContent(response.body);
      if (content == null || content.trim().isEmpty) {
        throw const ServerException(
          'The AI coach returned an empty response.',
          code: 'groq_invalid_response',
        );
      }
      return content;
    } on ServerException {
      rethrow;
    } on TimeoutException {
      throw const ServerException(
        'The AI coach timed out. Try again.',
        code: 'groq_timeout',
      );
    } on http.ClientException {
      throw const ServerException(
        'Could not reach the AI coach.',
        code: 'groq_network_error',
      );
    } catch (_) {
      throw const ServerException(
        'Could not reach the AI coach.',
        code: 'groq_network_error',
      );
    }
  }

  String? _extractContent(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return null;
      }
      final choices = decoded['choices'];
      if (choices is! List || choices.isEmpty) {
        return null;
      }
      final first = choices.first;
      if (first is! Map) {
        return null;
      }
      final message = first['message'];
      if (message is! Map) {
        return null;
      }
      final content = message['content'];
      return content is String ? content : null;
    } catch (_) {
      return null;
    }
  }
}
