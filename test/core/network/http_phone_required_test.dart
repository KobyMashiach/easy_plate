import 'dart:convert';
import 'dart:io';

import 'package:easy_plate/core/errors/app_exception.dart';
import 'package:easy_plate/core/network/http_calls.dart';
import 'package:flutter_test/flutter_test.dart';

/// The paid endpoints refuse an account whose ID token carries no verified
/// phone (403 `phone_required`). That must read as its own error — not
/// "sign in" or a generic failure — and a phone linked after the token was
/// minted gets exactly one refreshed retry, never a loop.
void main() {
  group('HttpCalls.errorTypeFor', () {
    test('both refusal shapes map to phoneRequired', () {
      expect(
        HttpCalls.errorTypeFor(403, {
          'error': {'code': 'phone_required', 'message': 'Verify'},
        }),
        AppErrorType.phoneRequired,
      );
      expect(
        HttpCalls.errorTypeFor(403, {
          'error': {'status': 'PHONE_REQUIRED', 'message': 'Verify'},
        }),
        AppErrorType.phoneRequired,
      );
    });

    test('another 403, or the code on another status, stays as it was', () {
      expect(
        HttpCalls.errorTypeFor(403, {
          'error': {'code': 'forbidden'},
        }),
        AppErrorType.unauthorized,
      );
      expect(
        HttpCalls.errorTypeFor(401, {
          'error': {'code': 'phone_required'},
        }),
        AppErrorType.unauthorized,
      );
    });
  });

  group('the refreshed retry', () {
    late HttpServer server;
    late int requests;
    late bool phoneInToken;

    setUp(() async {
      requests = 0;
      phoneInToken = false;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        requests++;
        final authorized =
            request.headers.value('authorization') == 'Bearer fresh';
        request.response.headers.contentType = ContentType.json;
        if (authorized && phoneInToken) {
          request.response.write(jsonEncode({'ok': true}));
        } else {
          request.response
            ..statusCode = 403
            ..write(
              jsonEncode({
                'error': {'code': 'phone_required', 'message': 'Verify'},
              }),
            );
        }
        await request.response.close();
      });
    });

    tearDown(() async {
      HttpCalls.refreshIdentity = null;
      await server.close(force: true);
    });

    String baseUrl() => 'http://${server.address.host}:${server.port}';

    test(
      'a phone linked after the token was minted: one retry succeeds',
      () async {
        var token = 'stale';
        var refreshes = 0;
        phoneInToken = true;
        HttpCalls.refreshIdentity = () async {
          refreshes++;
          token = 'fresh';
          return true;
        };
        final calls = HttpCalls(
          baseUrl: baseUrl(),
          headerProvider: () async => {'Authorization': 'Bearer $token'},
        );

        final response = await calls.post('/');

        expect(response?.data, {'ok': true});
        expect(refreshes, 1);
        expect(requests, 2);
      },
    );

    test('no phone at all: refused once, no retry, typed error', () async {
      var refreshes = 0;
      HttpCalls.refreshIdentity = () async {
        refreshes++;
        return false;
      };
      final calls = HttpCalls(
        baseUrl: baseUrl(),
        headerProvider: () async => {'Authorization': 'Bearer stale'},
      );

      await expectLater(
        calls.post('/'),
        throwsA(
          isA<AppException>().having(
            (e) => e.type,
            'type',
            AppErrorType.phoneRequired,
          ),
        ),
      );
      expect(refreshes, 1);
      expect(requests, 1);
    });

    test(
      'a refreshed token still without a phone is not retried twice',
      () async {
        var refreshes = 0;
        HttpCalls.refreshIdentity = () async {
          refreshes++;
          return true;
        };
        final calls = HttpCalls(
          baseUrl: baseUrl(),
          headerProvider: () async => {'Authorization': 'Bearer fresh'},
        );

        await expectLater(
          calls.post('/'),
          throwsA(
            isA<AppException>().having(
              (e) => e.type,
              'type',
              AppErrorType.phoneRequired,
            ),
          ),
        );
        expect(refreshes, 1);
        expect(requests, 2);
      },
    );
  });
}
