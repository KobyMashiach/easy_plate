import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:easy_plate/core/network/http_calls.dart';
import 'package:easy_plate/core/services/device_session_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  sessionSecretTests();

  final now = DateTime(2026, 10, 9, 12);
  final later = now.add(const Duration(days: 20));

  test('a document naming this device, still in date, keeps the session', () {
    expect(
      DeviceSessionService.evaluate(
        exists: true,
        deviceId: 'me',
        expiresAt: later,
        mine: 'me',
        now: now,
        seenBefore: true,
      ),
      isNull,
    );
  });

  test('a document naming another device ends it as a takeover', () {
    expect(
      DeviceSessionService.evaluate(
        exists: true,
        deviceId: 'them',
        expiresAt: later,
        mine: 'me',
        now: now,
        seenBefore: true,
      ),
      SessionEnd.otherDevice,
    );
  });

  test(
    'a document past its date, or one that disappears, ends it as expired',
    () {
      expect(
        DeviceSessionService.evaluate(
          exists: true,
          deviceId: 'me',
          expiresAt: now.subtract(const Duration(minutes: 1)),
          mine: 'me',
          now: now,
          seenBefore: true,
        ),
        SessionEnd.expired,
      );
      expect(
        DeviceSessionService.evaluate(
          exists: false,
          deviceId: null,
          expiresAt: null,
          mine: 'me',
          now: now,
          seenBefore: true,
        ),
        SessionEnd.expired,
      );
    },
  );

  test(
    'a missing document right after the claim is the write still landing',
    () {
      expect(
        DeviceSessionService.evaluate(
          exists: false,
          deviceId: null,
          expiresAt: null,
          mine: 'me',
          now: now,
          seenBefore: false,
        ),
        isNull,
      );
    },
  );

  test('no expiry date means a session that never runs out', () {
    expect(
      DeviceSessionService.evaluate(
        exists: true,
        deviceId: 'me',
        expiresAt: null,
        mine: 'me',
        now: now.add(const Duration(days: 400)),
        seenBefore: true,
      ),
      isNull,
    );
  });

  group('release requests', () {
    final now = DateTime.now();
    Map<String, dynamic> doc({
      String holder = 'A',
      String from = 'B',
      DateTime? at,
      bool declined = false,
    }) => {
      'deviceId': holder,
      'releaseRequest': {
        'deviceId': from,
        'platform': 'android',
        'at': Timestamp.fromDate(at ?? now),
        'declinedAt': declined ? Timestamp.fromDate(now) : null,
      },
    };

    test('the holder sees a fresh request from another device once', () {
      final request = DeviceSessionService.pendingRequest(
        doc(),
        mine: 'A',
        handled: null,
      );
      expect(request?.platform, 'android');
      expect(
        DeviceSessionService.pendingRequest(doc(), mine: 'A', handled: now),
        isNull,
      );
    });

    test('not on another device, not declined, not stale, not its own', () {
      expect(
        DeviceSessionService.pendingRequest(doc(), mine: 'B', handled: null),
        isNull,
      );
      expect(
        DeviceSessionService.pendingRequest(
          doc(declined: true),
          mine: 'A',
          handled: null,
        ),
        isNull,
      );
      expect(
        DeviceSessionService.pendingRequest(
          doc(at: now.subtract(const Duration(hours: 1))),
          mine: 'A',
          handled: null,
        ),
        isNull,
      );
      expect(
        DeviceSessionService.pendingRequest(
          doc(from: 'A'),
          mine: 'A',
          handled: null,
        ),
        isNull,
      );
    });
  });
}

class _Calls extends HttpCalls {
  final bodies = <Map<String, dynamic>>[];
  Map<String, dynamic> Function(Map<String, dynamic> body) answer;
  _Calls(this.answer);

  @override
  Future<Response?> post(
    String path, {
    dynamic data,
    Map<String, String>? headers,
    Duration? receiveTimeout,
  }) async {
    final body = Map<String, dynamic>.from(data as Map);
    bodies.add(body);
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: answer(body),
    );
  }
}

class _Secrets implements SessionSecretStore {
  final stored = <String, String>{};
  @override
  Future<String?> read(String uid) async => stored[uid];
  @override
  Future<void> write(String uid, String secret) async => stored[uid] = secret;
  @override
  Future<void> clear({String? keep}) async =>
      stored.removeWhere((uid, _) => uid != keep);
}

class _BrokenSecrets implements SessionSecretStore {
  @override
  Future<String?> read(String uid) async => null;
  @override
  Future<void> write(String uid, String secret) async =>
      throw StateError('no store');
  @override
  Future<void> clear({String? keep}) async {}
}

void sessionSecretTests() {
  group('session secret', () {
    late _Calls calls;
    late _Secrets secrets;
    late DeviceSessionService service;
    String? uid = 'u1';

    setUp(() {
      uid = 'u1';
      secrets = _Secrets();
      calls = _Calls((body) => {'ok': true});
      service = DeviceSessionService()..resetForTest();
      service.configure(
        calls: calls,
        deviceId: 'dev',
        hardwareId: 'hw',
        secrets: secrets,
        enabled: true,
      );
      service.uidSource = () => uid;
    });

    tearDown(() => service.resetForTest());

    test(
      'claim mints and stores the secret before sending, then reuses it',
      () async {
        String? storedWhenSent;
        calls.answer = (body) {
          storedWhenSent = secrets.stored['u1'];
          return {'ok': true};
        };
        expect(await service.claim(), isNull);
        final first = calls.bodies.single;
        expect(first['wantsSecret'], isTrue);
        final secret = first['secret'] as String;
        // 32 bytes, base64url without padding.
        expect(base64Url.decode('$secret='), hasLength(32));
        expect(secret, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
        expect(storedWhenSent, secret);

        // The answer got lost: the retry presents the very same secret.
        calls.answer = (body) => throw StateError('lost');
        expect(await service.claim(), isNull);
        expect(calls.bodies.last['secret'], secret);

        calls.answer = (body) => {'ok': true};
        await service.release();
        await service.declineRelease();
        await service.requestRelease(title: 't', body: 'b');
        for (final body in calls.bodies.skip(2)) {
          expect(body['secret'], secret, reason: body['action'] as String);
          expect(body.containsKey('wantsSecret'), isFalse);
        }
        expect(secrets.stored, {'u1': secret});
      },
    );

    test('takeover sends the held secret, or mints one first', () async {
      secrets.stored['u1'] = 'held';
      expect(await service.takeover(), isTrue);
      expect(calls.bodies.single['action'], 'takeover');
      expect(calls.bodies.single['wantsSecret'], isTrue);
      expect(calls.bodies.single['secret'], 'held');

      secrets.stored.clear();
      await service.takeover();
      final minted = calls.bodies.last['secret'] as String;
      expect(minted, hasLength(43));
      expect(secrets.stored, {'u1': minted});
    });

    test('release, decline and requestRelease never mint one', () async {
      await service.release();
      await service.declineRelease();
      await service.requestRelease(title: 't', body: 'b');
      for (final body in calls.bodies) {
        expect(body.containsKey('wantsSecret'), isFalse);
        expect(body.containsKey('secret'), isFalse);
      }
      expect(secrets.stored, isEmpty);
    });

    test('a store that cannot keep it sends none', () async {
      service.configure(
        calls: calls,
        deviceId: 'dev',
        hardwareId: 'hw',
        secrets: _BrokenSecrets(),
        enabled: true,
      );
      await service.claim();
      expect(calls.bodies.single.containsKey('secret'), isFalse);
      expect(calls.bodies.single.containsKey('wantsSecret'), isFalse);
    });

    test('another account\'s secret is dropped on the next claim', () async {
      secrets.stored['u0'] = 'theirs';
      secrets.stored['u1'] = 'mine';
      await service.claim();
      expect(calls.bodies.single['secret'], 'mine');
      expect(secrets.stored, {'u1': 'mine'});
    });

    test('a refused claim keeps the secret for the SMS takeover', () async {
      secrets.stored['u1'] = 'mine';
      calls.answer = (body) => {
        'ok': false,
        'refusal': {'code': 'other_device', 'platform': 'ios'},
      };
      final refusal = await service.claim();
      expect(refusal?.platform, 'ios');
      calls.answer = (body) => {'ok': true};
      expect(await service.takeover(), isTrue);
      expect(calls.bodies.last['secret'], 'mine');
    });

    test('sign-out forgets every secret; the next claim mints anew', () async {
      secrets.stored['u1'] = 's';
      await service.forgetSecrets();
      expect(secrets.stored, isEmpty);
      uid = null;
      await service.claim();
      expect(calls.bodies.single.containsKey('secret'), isFalse);
      uid = 'u1';
      await service.claim();
      expect(calls.bodies.last['secret'], isNot('s'));
    });
  });
}
