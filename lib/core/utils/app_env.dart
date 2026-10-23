/// Typed access to environment configuration.
///
/// Values come from `--dart-define` (or `--dart-define-from-file=.env` for
/// local development). `.env` is local-only and never bundled as an asset;
/// missing configuration degrades to empty strings.
class AppEnv {
  const AppEnv({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.groqApiKey,
  });

  factory AppEnv.current() {
    return const AppEnv(
      supabaseUrl: _supabaseUrlDefine,
      supabaseAnonKey: _supabaseAnonKeyDefine,
      groqApiKey: _groqApiKeyDefine,
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
}
