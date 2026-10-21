import 'dart:async';

import 'package:easy_plate/core/constants/purchases_config.dart';
import 'package:easy_plate/core/monetization/purchases_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The RevenueCat SDK talks over one method channel; standing in for it
/// here is what lets the sign-in / sign-out choreography run under test.
class _FakeSdk {
  static const channel = MethodChannel('purchases_flutter');

  final calls = <String>[];
  bool configureFails = false;

  /// Completed by the test, so a sign-in can land in the middle of it.
  Completer<bool>? anonymousGate;

  static const _emptyCustomerInfo = <String, dynamic>{
    'entitlements': {'all': {}, 'active': {}, 'verification': 'NOT_REQUESTED'},
    'allPurchaseDates': {},
    'activeSubscriptions': [],
    'allPurchasedProductIdentifiers': [],
    'nonSubscriptionTransactions': [],
    'firstSeen': '2026-01-01T00:00:00Z',
    'originalAppUserId': 'u',
    'allExpirationDates': {},
    'requestDate': '2026-01-01T00:00:00Z',
  };

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          switch (call.method) {
            case 'setupPurchases':
              if (configureFails) {
                throw PlatformException(code: 'CONFIG', message: 'no network');
              }
              return null;
            case 'setLogLevel':
              return null;
            case 'getCustomerInfo':
            case 'logOut':
              return _emptyCustomerInfo;
            case 'logIn':
              return {'customerInfo': _emptyCustomerInfo, 'created': false};
            case 'isAnonymous':
              return await (anonymousGate?.future ?? Future.value(false));
          }
          throw PlatformException(code: 'UNHANDLED', message: call.method);
        });
  }

  void uninstall() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeSdk sdk;
  late PurchasesService service;

  setUp(() {
    PurchasesConfig.enabledOverride = true;
    sdk = _FakeSdk()..install();
    service = PurchasesService()..resetForTest();
  });

  tearDown(() {
    sdk.uninstall();
    PurchasesConfig.enabledOverride = null;
    service.resetForTest();
  });

  test(
    'a failed configure is retried on the same account\'s next sign-in',
    () async {
      sdk.configureFails = true;
      await service.logIn('u1');
      expect(service.isConfigured, isFalse);

      // The network is back and the auth stream re-emits the same user: before
      // the fix `_uid` already held u1 and the call returned at once, so the
      // SDK stayed down for the whole session.
      sdk.configureFails = false;
      await service.logIn('u1');
      expect(service.isConfigured, isTrue);
      expect(sdk.calls.where((c) => c == 'setupPurchases').length, 2);
    },
  );

  test('a sign-in landing during logOut is not logged out', () async {
    await service.logIn('u1');
    expect(service.isConfigured, isTrue);

    final gate = sdk.anonymousGate = Completer<bool>();
    final signingOut = service.logOut();
    // The next account arrives while `isAnonymous` is still being asked.
    await service.logIn('u2');
    gate.complete(false);
    await signingOut;

    expect(sdk.calls, contains('logIn'));
    expect(sdk.calls, isNot(contains('logOut')));
  });

  test('a sign-out while the SDK is still coming up detaches it', () async {
    // Every SDK call crosses the channel asynchronously, so the sign-out
    // below lands while configure is still in flight. Before the fix it saw
    // `_configured == false`, returned, and the SDK finished coming up
    // identified as u1 with nobody signed in.
    final gate = sdk.anonymousGate = Completer<bool>();
    final signingIn = service.logIn('u1');
    final signingOut = service.logOut();
    gate.complete(false);
    await Future.wait([signingIn, signingOut]);

    expect(service.isConfigured, isTrue);
    expect(sdk.calls, contains('logOut'));
  });
}
