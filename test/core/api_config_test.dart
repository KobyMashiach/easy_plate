import 'package:easy_plate/core/constants/api_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// One base URL decides both how the app authenticates and whether the AI
/// feature is available at all, so both branches are pinned here. The compiled
/// values cannot vary inside a single test run, which is why the switch is
/// exercised through its pure form.
void main() {
  const proxy = 'https://us-central1-easy-plate.cloudfunctions.net/aiProxy';

  group('proxyFor', () {
    test('Google\'s own endpoint is not a proxy', () {
      expect(ApiConfig.proxyFor(ApiConfig.googleDirectBaseUrl), isFalse);
    });

    test('anything else is', () {
      expect(ApiConfig.proxyFor(proxy), isTrue);
    });
  });

  group('configuredFor', () {
    test('the proxy needs no key, because the server holds it', () {
      expect(ApiConfig.configuredFor(proxy, ''), isTrue);
    });

    test('going direct without a key is not configured', () {
      expect(ApiConfig.configuredFor(ApiConfig.googleDirectBaseUrl, ''), isFalse);
    });

    test('going direct with a key is configured', () {
      expect(
        ApiConfig.configuredFor(ApiConfig.googleDirectBaseUrl, 'a-dev-key'),
        isTrue,
      );
    });
  });

  test('the path the proxy must expose matches the one the app calls', () {
    expect(ApiConfig.interactionsPath, '/v1beta/interactions');
  });

  test('a test run carries no key, so it exercises the offline fallback', () {
    expect(ApiConfig.geminiApiKey, isEmpty);
    expect(ApiConfig.isConfigured, isFalse);
  });
}
