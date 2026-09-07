import 'package:easy_plate/core/errors/app_exception.dart';
import 'package:easy_plate/core/network/http_calls.dart';
import 'package:flutter_test/flutter_test.dart';

/// The AI datasource retries `overloaded` and nothing else, so which of the two
/// 429s a response maps to decides whether the user waits out a backoff for an
/// answer that cannot change.
void main() {
  group('HttpCalls.errorTypeFor', () {
    test('a 429 carrying the proxy quota object is not retryable', () {
      final type = HttpCalls.errorTypeFor(429, {
        'error': {
          'status': 'RESOURCE_EXHAUSTED',
          'message': 'Daily limit of 30 AI requests reached',
          'quota': {'used': 30, 'limit': 30},
        },
      });

      expect(type, AppErrorType.quotaExceeded);
    });

    test('a 429 without one is upstream capacity, which is worth retrying', () {
      final type = HttpCalls.errorTypeFor(429, {
        'error': {'status': 'RESOURCE_EXHAUSTED', 'message': 'Rate limited'},
      });

      expect(type, AppErrorType.overloaded);
    });

    test('a 429 whose body never parsed is treated as capacity, not as quota', () {
      expect(HttpCalls.errorTypeFor(429, 'upstream said no'), AppErrorType.overloaded);
      expect(HttpCalls.errorTypeFor(429, null), AppErrorType.overloaded);
    });

    test('the server errors the proxy returns stay retryable', () {
      for (final status in [500, 502, 503, 504, 529]) {
        expect(HttpCalls.errorTypeFor(status, null), AppErrorType.overloaded, reason: '$status');
      }
    });

    test('an expired or rejected token is not mistaken for capacity', () {
      expect(HttpCalls.errorTypeFor(401, null), AppErrorType.unauthorized);
      expect(HttpCalls.errorTypeFor(403, null), AppErrorType.unauthorized);
    });
  });
}
