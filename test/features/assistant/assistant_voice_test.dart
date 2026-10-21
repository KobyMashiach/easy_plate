import 'dart:convert';

import 'package:easy_plate/features/assistant/presentation/assistant_voice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AssistantVoice.isQuotaRefusal', () {
    List<int> bytes(Object json) => utf8.encode(jsonEncode(json));

    test('the daily-budget refusal, as bytes, is a quota refusal', () {
      final body = bytes({
        'error': {
          'code': 'quota',
          'quota': {'used': 300, 'limit': 300, 'kind': 'speak'},
        },
      });
      expect(AssistantVoice.isQuotaRefusal(429, body), isTrue);
    });

    test('an upstream 429 without quota is not', () {
      final body = bytes({
        'error': {'code': 'upstream_busy'},
      });
      expect(AssistantVoice.isQuotaRefusal(429, body), isFalse);
    });

    test('other statuses and unreadable bodies are not', () {
      expect(AssistantVoice.isQuotaRefusal(502, bytes({})), isFalse);
      expect(AssistantVoice.isQuotaRefusal(429, [0xff, 0xfe]), isFalse);
      expect(AssistantVoice.isQuotaRefusal(null, null), isFalse);
    });
  });
}
