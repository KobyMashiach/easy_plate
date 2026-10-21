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

    test(
      'a 429 whose body never parsed is treated as capacity, not as quota',
      () {
        expect(
          HttpCalls.errorTypeFor(429, 'upstream said no'),
          AppErrorType.overloaded,
        );
        expect(HttpCalls.errorTypeFor(429, null), AppErrorType.overloaded);
      },
    );

    test('the server errors the proxy returns stay retryable', () {
      for (final status in [500, 502, 503, 504, 529]) {
        expect(
          HttpCalls.errorTypeFor(status, null),
          AppErrorType.overloaded,
          reason: '$status',
        );
      }
    });

    test('an expired or rejected token is not mistaken for capacity', () {
      expect(HttpCalls.errorTypeFor(401, null), AppErrorType.unauthorized);
      expect(HttpCalls.errorTypeFor(403, null), AppErrorType.unauthorized);
    });

    test('the daily budgets (translate, speak, image search, prices) are '
        'quota, with or without `requested`', () {
      final body = {
        'error': {
          'code': 'quota',
          'status': 'RESOURCE_EXHAUSTED',
          'message': 'This request needs 500 translated lines; 250 left',
          'quota': {
            'used': 2750,
            'limit': 3000,
            'kind': 'translate',
            'requested': 500,
          },
        },
      };
      expect(HttpCalls.errorTypeFor(429, body), AppErrorType.quotaExceeded);
      expect(
        HttpCalls.quotaOf(body),
        (used: 2750, limit: 3000, requested: 500),
      );
      expect(
        HttpCalls.quotaOf({
          'error': {
            'quota': {'used': 30, 'limit': 30},
          },
        }),
        (used: 30, limit: 30, requested: null),
      );
    });

    test('a 429 named quota without the object is the provider, retryable', () {
      // imageSearch when Serper itself is out of credits.
      expect(
        HttpCalls.errorTypeFor(429, {
          'error': {'code': 'quota', 'message': 'Image search failed'},
        }),
        AppErrorType.overloaded,
      );
      expect(
        HttpCalls.quotaOf({
          'error': {'code': 'quota'},
        }),
        isNull,
      );
      expect(
        HttpCalls.errorTypeFor(429, {
          'error': {'code': 'rate_limited', 'message': 'Try again later'},
        }),
        AppErrorType.overloaded,
      );
    });

    test('refusals of the request itself are not retried as capacity', () {
      for (final (status, code) in [
        (400, 'too_many_lines'),
        (400, 'too_many_lines_in_item'),
        (409, 'checkout_pending'),
        (409, 'in_progress'),
      ]) {
        expect(
          HttpCalls.errorTypeFor(status, {
            'error': {'code': code},
          }),
          AppErrorType.unknown,
          reason: code,
        );
      }
    });

    test('a malformed quota object reads as none', () {
      expect(
        HttpCalls.quotaOf({
          'error': {
            'quota': {'used': 'x', 'limit': 3},
          },
        }),
        isNull,
      );
      expect(HttpCalls.quotaOf('text'), isNull);
    });
  });
}
