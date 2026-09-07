/// Gemini configuration for the recipe ingestion pipeline.
///
/// There are two ways to reach the model, and [aiBaseUrl] is the only knob that
/// picks between them.
///
/// **Development** talks to Google directly, authenticating with a key supplied
/// through `--dart-define-from-file=dart_defines/dev.json`.
///
/// **Production** talks to our own Cloud Function, which holds the key in Secret
/// Manager and authenticates the caller by their Firebase ID token. A key
/// compiled into a mobile binary is extractable with `strings`, so a shipped
/// build must carry none.
abstract class ApiConfig {
  /// Google's own endpoint. Anything else in [aiBaseUrl] is taken to be our
  /// proxy, which is what flips the authentication scheme below.
  static const googleDirectBaseUrl = 'https://generativelanguage.googleapis.com';

  static const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  static const aiBaseUrl = String.fromEnvironment(
    'AI_BASE_URL',
    defaultValue: googleDirectBaseUrl,
  );

  /// True when requests go through our backend rather than straight to Google.
  static bool get usesProxy => proxyFor(aiBaseUrl);

  /// The switch itself, as a pure function. [aiBaseUrl] is fixed at compile
  /// time, so this is the only way to cover both branches in a test.
  static bool proxyFor(String baseUrl) => baseUrl != googleDirectBaseUrl;

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

  /// How long the model may reason before it starts answering.
  ///
  /// Gemini 3 thinks by default, and on a recipe extraction that reasoning was
  /// most of the wait — the work is transcription against a fixed schema, not a
  /// problem to be solved, so it buys nothing. `low` is the floor for
  /// [model]: `minimal` exists but the flash models that take it are a
  /// different tier, and sending it to one that does not is a 400.
  static const thinkingLevel = String.fromEnvironment(
    'GEMINI_THINKING_LEVEL',
    defaultValue: 'low',
  );

  /// [searchModel] is a lite model, which does accept `minimal` — and picking
  /// five links needs no deliberation at all.
  static const searchThinkingLevel = String.fromEnvironment(
    'GEMINI_SEARCH_THINKING_LEVEL',
    defaultValue: 'minimal',
  );

  /// Behind the proxy there is nothing to configure in the app: the key lives
  /// on the server, and the caller's identity is the credential.
  static bool get isConfigured => configuredFor(aiBaseUrl, geminiApiKey);

  static bool configuredFor(String baseUrl, String key) =>
      proxyFor(baseUrl) || key.isNotEmpty;
}
