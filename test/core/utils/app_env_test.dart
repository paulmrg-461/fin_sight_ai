import 'package:fin_sight_ai/core/utils/app_env.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => dotenv.clean());

  group('AppEnv', () {
    test('reads values from the dotenv map', () {
      dotenv.loadFromString(
        envString: '''
SUPABASE_URL=https://demo.supabase.co
SUPABASE_ANON_KEY=anon-key
GROQ_API_KEY=groq-key
''',
      );

      final env = AppEnv.current();

      expect(env.supabaseUrl, 'https://demo.supabase.co');
      expect(env.supabaseAnonKey, 'anon-key');
      expect(env.groqApiKey, 'groq-key');
      expect(env.hasSupabase, isTrue);
      expect(env.hasGroq, isTrue);
    });

    test('falls back to empty strings when keys are absent', () {
      dotenv.loadFromString(envString: '', isOptional: true);

      final env = AppEnv.current();

      expect(env.supabaseUrl, isEmpty);
      expect(env.supabaseAnonKey, isEmpty);
      expect(env.groqApiKey, isEmpty);
      expect(env.hasSupabase, isFalse);
      expect(env.hasGroq, isFalse);
    });

    test('reports whether Groq is configured', () {
      dotenv.loadFromString(envString: 'GROQ_API_KEY=key');

      expect(AppEnv.current().hasGroq, isTrue);
    });

    test('does not require dotenv to be initialized', () {
      dotenv.clean();

      final env = AppEnv.current();

      expect(env.supabaseUrl, isEmpty);
      expect(env.hasSupabase, isFalse);
    });
  });
}
