import 'package:easy_plate/core/services/auth_session_service.dart';
import 'package:easy_plate/core/utils/routing/app_router.dart';
import 'package:easy_plate/core/utils/routing/routing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('unknown', () {
    test('holds everything on the splash until the first auth state lands', () {
      expect(
        gateRedirect(stage: AuthStage.unknown, location: Routing.home),
        Routing.splash,
      );
      expect(
        gateRedirect(stage: AuthStage.unknown, location: Routing.splash),
        isNull,
      );
    });
  });

  group('signedOut', () {
    test('sends every screen to the login', () {
      for (final location in [Routing.home, Routing.register, Routing.onboarding]) {
        expect(gateRedirect(stage: AuthStage.signedOut, location: location), Routing.login);
      }
    });

    test('lets the SMS code screen through mid sign-in', () {
      expect(
        gateRedirect(stage: AuthStage.signedOut, location: Routing.phoneVerify),
        isNull,
      );
    });
  });

  group('needsPhone', () {
    test('holds every other screen until a number is proved', () {
      for (final location in [
        Routing.home,
        Routing.login,
        Routing.register,
        Routing.onboarding,
        Routing.verifyEmail,
      ]) {
        expect(
          gateRedirect(stage: AuthStage.needsPhone, location: location),
          Routing.phoneGate,
        );
      }
    });

    test('lets its own screen through', () {
      expect(
        gateRedirect(stage: AuthStage.needsPhone, location: Routing.phoneGate),
        isNull,
      );
    });

    test('does not reuse the sign-in SMS screen, which needs arguments', () {
      expect(
        gateRedirect(stage: AuthStage.needsPhone, location: Routing.phoneVerify),
        Routing.phoneGate,
      );
    });
  });

  group('needsEmailVerification', () {
    test('holds a password account on the verification screen', () {
      expect(
        gateRedirect(stage: AuthStage.needsEmailVerification, location: Routing.home),
        Routing.verifyEmail,
      );
      expect(
        gateRedirect(stage: AuthStage.needsEmailVerification, location: Routing.verifyEmail),
        isNull,
      );
    });

    test('does not let registration be reached before the address is confirmed', () {
      expect(
        gateRedirect(stage: AuthStage.needsEmailVerification, location: Routing.register),
        Routing.verifyEmail,
      );
    });
  });

  group('needsProfile', () {
    test('forces registration and does not accept the login as done', () {
      expect(
        gateRedirect(stage: AuthStage.needsProfile, location: Routing.home),
        Routing.register,
      );
      expect(
        gateRedirect(stage: AuthStage.needsProfile, location: Routing.login),
        Routing.register,
      );
      expect(
        gateRedirect(stage: AuthStage.needsProfile, location: Routing.register),
        isNull,
      );
    });

    test('does not let the phone screen bypass registration', () {
      expect(
        gateRedirect(stage: AuthStage.needsProfile, location: Routing.phoneVerify),
        Routing.register,
      );
    });
  });

  group('needsOnboarding', () {
    test('routes to onboarding, not back to registration', () {
      expect(
        gateRedirect(stage: AuthStage.needsOnboarding, location: Routing.home),
        Routing.onboarding,
      );
      expect(
        gateRedirect(stage: AuthStage.needsOnboarding, location: Routing.onboarding),
        isNull,
      );
    });
  });

  group('ready', () {
    test('closes every gate screen behind the user', () {
      for (final location in [
        Routing.splash,
        Routing.login,
        Routing.phoneGate,
        // Pushed with arguments rather than owned by a stage, so it used to
        // stay reachable once the user was through.
        Routing.phoneVerify,
        Routing.verifyEmail,
        Routing.register,
        Routing.onboarding,
      ]) {
        expect(gateRedirect(stage: AuthStage.ready, location: location), Routing.home);
      }
    });

    test('leaves ordinary app routes alone', () {
      expect(gateRedirect(stage: AuthStage.ready, location: Routing.home), isNull);
      expect(
        gateRedirect(stage: AuthStage.ready, location: '/home/recipe_details'),
        isNull,
      );
    });
  });
}
