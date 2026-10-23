import 'package:fin_sight_ai/core/utils/app_env.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppEnv', () {
    test('reports Supabase as configured when URL and key are present', () {
      const env = AppEnv(
        supabaseUrl: 'https://demo.supabase.co',
        supabaseAnonKey: 'anon-key',
        groqApiKey: '',
      );

      expect(env.supabaseUrl, 'https://demo.supabase.co');
      expect(env.supabaseAnonKey, 'anon-key');
      expect(env.hasSupabase, isTrue);
    });

    test('reports Supabase as unconfigured when a value is missing', () {
      const env = AppEnv(
        supabaseUrl: '',
        supabaseAnonKey: 'anon-key',
        groqApiKey: '',
      );

      expect(env.hasSupabase, isFalse);
    });

    test('reports Groq as configured when the key is present', () {
      const env = AppEnv(
        supabaseUrl: '',
        supabaseAnonKey: '',
        groqApiKey: 'groq-key',
      );

      expect(env.groqApiKey, 'groq-key');
      expect(env.hasGroq, isTrue);
    });

    test('reports Groq as unconfigured when the key is empty', () {
      const env = AppEnv(supabaseUrl: '', supabaseAnonKey: '', groqApiKey: '');

      expect(env.hasGroq, isFalse);
    });

    test('current reads no values when no dart-define is provided', () {
      final env = AppEnv.current();

      expect(env.supabaseUrl, isEmpty);
      expect(env.supabaseAnonKey, isEmpty);
      expect(env.groqApiKey, isEmpty);
      expect(env.hasSupabase, isFalse);
      expect(env.hasGroq, isFalse);
    });
  });
}
