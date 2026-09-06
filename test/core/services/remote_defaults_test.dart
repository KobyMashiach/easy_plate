import 'package:easy_plate/core/services/firebase_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isProd defaults to production', () {
    // The DEV badge keys off this. If the default ever flips to false, a
    // release build whose Remote Config fetch fails would show DEV to real
    // users — so the default is pinned here on purpose.
    expect(FirebaseService.remoteDefaults[FirebaseService.isProdKey], isTrue);
  });

  test('the isProd key matches the Remote Config parameter name', () {
    expect(FirebaseService.isProdKey, 'isProd');
  });

  group('resolveIsProd', () {
    test('a blank console value falls back to production', () {
      // Observed in the wild: the parameter existed with no value, came back
      // as source=valueRemote with raw="", and asBool("") = false marked a
      // production build as DEV.
      expect(FirebaseService.resolveIsProd(raw: '', parsed: false), isTrue);
      expect(FirebaseService.resolveIsProd(raw: '   ', parsed: false), isTrue);
    });

    test('a real value is honoured in both directions', () {
      expect(FirebaseService.resolveIsProd(raw: 'true', parsed: true), isTrue);
      expect(FirebaseService.resolveIsProd(raw: 'false', parsed: false), isFalse);
    });

    test('an explicit false still shows DEV, which is the whole point', () {
      expect(FirebaseService.resolveIsProd(raw: 'false', parsed: false), isFalse);
    });
  });

  test('the flag starts from the default, so nothing reads null before a fetch', () {
    expect(FirebaseService().isProdListenable.value, isTrue);
    expect(FirebaseService().isProd, isTrue);
  });

  test('listeners are notified when the flag changes', () {
    final service = FirebaseService();
    var notified = 0;
    void listener() => notified++;

    service.isProdListenable.addListener(listener);
    addTearDown(() {
      service.isProdListenable.removeListener(listener);
      service.isProdListenable.value = true;
    });

    // What a refresh does when the console says this build is not production:
    // the badge has to appear without the page being reopened.
    service.isProdListenable.value = false;
    expect(notified, 1);
    expect(service.isProd, isFalse);
  });
}
