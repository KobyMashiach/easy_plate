import 'dart:convert';
import 'dart:io';

import 'package:easy_plate/core/errors/app_exception.dart';
import 'package:easy_plate/core/network/http_calls.dart';
import 'package:flutter_test/flutter_test.dart';

/// The server refuses an account the administrator switched off with 403
/// `account_disabled` (the `disabled` custom claim). That is its own error,
/// never retried, and the gate is told so it can hold the account on the
/// blocked screen at once rather than at its next sign-in.
void main() {
  group('HttpCalls.errorTypeFor', () {
    test('403 account_disabled maps to accountDisabled', () {
      expect(
        HttpCalls.errorTypeFor(403, {
          'error': {'code': 'account_disabled', 'message': 'Disabled'},
        }),
        AppErrorType.accountDisabled,
      );
    });

    test('socialRecipe\'s own shape maps the same way', () {
      expect(
        HttpCalls.errorTypeFor(403, {
          'error': {'status': 'ACCOUNT_DISABLED', 'message': 'Disabled'},
        }),
        AppErrorType.accountDisabled,
      );
    });

    test('the code on another status, or another 403, stays as it was', () {
      expect(
        HttpCalls.errorTypeFor(401, {
          'error': {'code': 'account_disabled'},
        }),
        AppErrorType.unauthorized,
      );
      expect(
        HttpCalls.errorTypeFor(403, {
          'error': {'code': 'forbidden'},
        }),
        AppErrorType.unauthorized,
      );
      expect(HttpCalls.isAccountDisabled(403, 'account_disabled'), isFalse);
    });
  });

  group('a refused call', () {
    late HttpServer server;
    late int requests;

    setUp(() async {
      requests = 0;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        requests++;
        request.response
          ..headers.contentType = ContentType.json
          ..statusCode = 403
          ..write(
            jsonEncode({
              'error': {'code': 'account_disabled', 'message': 'Disabled'},
            }),
          );
        await request.response.close();
      });
    });

    tearDown(() async {
      HttpCalls.onAccountDisabled = null;
      HttpCalls.refreshIdentity = null;
      await server.close(force: true);
    });

    test('tells the gate once and is not retried', () async {
      var told = 0;
      var refreshes = 0;
      HttpCalls.onAccountDisabled = () => told++;
      HttpCalls.refreshIdentity = () async {
        refreshes++;
        return true;
      };
      final calls = HttpCalls(
        baseUrl: 'http://${server.address.host}:${server.port}',
        headerProvider: () async => {'Authorization': 'Bearer t'},
      );

      await expectLater(
        calls.post('/'),
        throwsA(
          isA<AppException>().having(
            (e) => e.type,
            'type',
            AppErrorType.accountDisabled,
          ),
        ),
      );
      expect(told, 1);
      expect(
        refreshes,
        0,
        reason: 'a disabled account has no claim to refresh',
      );
      expect(requests, 1);
    });

    test('without a hook the error alone is thrown', () async {
      final calls = HttpCalls(
        baseUrl: 'http://${server.address.host}:${server.port}',
      );
      await expectLater(
        calls.get('/'),
        throwsA(
          isA<AppException>().having(
            (e) => e.type,
            'type',
            AppErrorType.accountDisabled,
          ),
        ),
      );
    });
  });
}
