/// Build-time configuration, supplied with
/// `flutter run --dart-define-from-file=env.json`.
abstract final class Env {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  /// True when both values are set. When either is missing, startup skips
  /// Supabase init and the app still runs without a backend.
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
