import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed access to environment configuration.
///
/// Values come from `--dart-define` first, then from the `.env` asset. The
/// `.env` file committed to this repository only contains empty placeholders;
/// real credentials must be provided at build time or kept in a local,
/// untracked copy.
class AppEnv {
  const AppEnv({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.groqApiKey,
  });

  factory AppEnv.current() {
    return AppEnv(
      supabaseUrl: _value('SUPABASE_URL', _supabaseUrlDefine),
      supabaseAnonKey: _value('SUPABASE_ANON_KEY', _supabaseAnonKeyDefine),
      groqApiKey: _value('GROQ_API_KEY', _groqApiKeyDefine),
    );
  }

  static const String _supabaseUrlDefine = String.fromEnvironment(
    'SUPABASE_URL',
  );
  static const String _supabaseAnonKeyDefine = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );
  static const String _groqApiKeyDefine = String.fromEnvironment(
    'GROQ_API_KEY',
  );

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String groqApiKey;

  bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  bool get hasGroq => groqApiKey.isNotEmpty;

  /// Loads the `.env` asset. Missing files are tolerated so the app can still
  /// run with `--dart-define` only.
  static Future<void> load({String fileName = '.env'}) {
    return dotenv.load(fileName: fileName, isOptional: true);
  }

  static String _value(String key, String define) {
    if (define.isNotEmpty) {
      return define;
    }
    if (!dotenv.isInitialized) {
      return '';
    }
    return dotenv.maybeGet(key) ?? '';
  }
}
