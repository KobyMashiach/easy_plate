/// Claude Messages API configuration for the recipe ingestion pipeline.
///
/// SECURITY: shipping an API key inside a mobile binary makes it extractable.
/// For production, point [aiBaseUrl] at your own backend proxy that holds the
/// key server-side; the direct-to-Anthropic path below is for local development
/// only, via `--dart-define=ANTHROPIC_API_KEY=sk-ant-...`.
abstract class ApiConfig {
  static const anthropicApiKey = String.fromEnvironment('ANTHROPIC_API_KEY');
  static const aiBaseUrl = String.fromEnvironment(
    'AI_BASE_URL',
    defaultValue: 'https://api.anthropic.com',
  );

  static const messagesPath = '/v1/messages';
  static const anthropicVersion = '2023-06-01';
  static const model = 'claude-opus-5';
  static const maxTokens = 16000;

  static bool get isConfigured => anthropicApiKey.isNotEmpty;
}
