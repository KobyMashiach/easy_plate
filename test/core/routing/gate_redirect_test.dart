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
