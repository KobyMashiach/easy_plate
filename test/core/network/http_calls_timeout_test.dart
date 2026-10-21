import 'dart:convert';
import 'dart:io';

import 'package:easy_plate/core/errors/app_exception.dart';
import 'package:easy_plate/core/network/http_calls.dart';
import 'package:flutter_test/flutter_test.dart';

/// A server that answers after [delay]: long enough to trip a short
/// per-call receive timeout, short enough for the test to stay quick.
void main() {
  late HttpServer server;
  const delay = Duration(milliseconds: 400);

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      await Future<void>.delayed(delay);
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'ok': true}));
      await request.response.close();
    });
  });

  tearDown(() => server.close(force: true));

  String baseUrl() => 'http://${server.address.host}:${server.port}';

  test(
    'a per-call receive timeout shorter than the answer is a network error',
    () async {
      final calls = HttpCalls(baseUrl: baseUrl());
      await expectLater(
        calls.post('/', receiveTimeout: const Duration(milliseconds: 100)),
        throwsA(
          isA<AppException>().having(
            (e) => e.type,
            'type',
            AppErrorType.networkError,
          ),
        ),
      );
    },
  );

  test('a longer one waits the answer out', () async {
    final calls = HttpCalls(baseUrl: baseUrl());
    final response = await calls.post(
      '/',
      receiveTimeout: const Duration(seconds: 5),
    );
    expect(response?.data, {'ok': true});
  });

  test('without one the two-minute default applies', () async {
    final calls = HttpCalls(baseUrl: baseUrl());
    final response = await calls.post('/');
    expect(response?.data, {'ok': true});
  });
}
