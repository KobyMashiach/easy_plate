import 'package:easy_plate/data_delete.dart';

/// Gemini Interactions API configuration for the recipe ingestion pipeline.
///
/// SECURITY: shipping an API key inside a mobile binary makes it extractable.
/// For production, point [aiBaseUrl] at your own backend proxy that holds the
/// key server-side; the direct-to-Google path below is for local development
/// only, via `--dart-define=GEMINI_API_KEY=...`.
abstract class ApiConfig {
  static const geminiApiKey = geminiApiKeyTemp;
  // static const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const aiBaseUrl = String.fromEnvironment(
    'AI_BASE_URL',
    defaultValue: 'https://generativelanguage.googleapis.com',
  );

  static const interactionsPath = '/v1beta/interactions';
  static const model = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-3.8-flash',
  );

  /// Web search only returns titles and links — no reasoning to speak of — so
  /// it runs on the lightest model available. The main model is kept for
  /// extraction, where accuracy matters more than the wait.
  static const searchModel = String.fromEnvironment(
    'GEMINI_SEARCH_MODEL',
    defaultValue: 'gemini-3.5-flash-lite',
  );

  static bool get isConfigured => geminiApiKey.isNotEmpty;
}
