import 'package:easy_plate/core/features/features_flags.dart';
import 'package:easy_plate/core/services/firebase_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the console values map to the four states, anything else is on', () {
    expect(FeatureFlagValue.fromInt(0), FeatureFlagValue.hidden);
    expect(FeatureFlagValue.fromInt(1), FeatureFlagValue.comingSoon);
    expect(FeatureFlagValue.fromInt(2), FeatureFlagValue.enabled);
    expect(FeatureFlagValue.fromInt(3), FeatureFlagValue.premiumOnly);
    expect(FeatureFlagValue.fromInt(7), FeatureFlagValue.enabled);
    expect(FeatureFlagValue.fromInt(-1), FeatureFlagValue.enabled);
  });

  test('premium-only is on for a paying account and locked for a free one', () {
    expect(
      FeaturesFlags.resolve(FeatureFlagValue.premiumOnly, true),
      FeatureAccess.enabled,
    );
    expect(
      FeaturesFlags.resolve(FeatureFlagValue.premiumOnly, false),
      FeatureAccess.locked,
    );
    // The plan changes nothing else.
    for (final premium in [true, false]) {
      expect(
        FeaturesFlags.resolve(FeatureFlagValue.hidden, premium),
        FeatureAccess.hidden,
      );
      expect(
        FeaturesFlags.resolve(FeatureFlagValue.comingSoon, premium),
        FeatureAccess.comingSoon,
      );
      expect(
        FeaturesFlags.resolve(FeatureFlagValue.enabled, premium),
        FeatureAccess.enabled,
      );
    }
  });

  test('access answers what a screen asks', () {
    expect(FeatureAccess.hidden.isVisible, isFalse);
    expect(FeatureAccess.comingSoon.isVisible, isTrue);
    expect(FeatureAccess.comingSoon.isEnabled, isFalse);
    expect(FeatureAccess.locked.isLocked, isTrue);
    expect(FeatureAccess.locked.isEnabled, isFalse);
    expect(FeatureAccess.enabled.isEnabled, isTrue);
  });

  test(
    'every flag has an in-app default of 2 and is registered with Remote Config',
    () {
      expect(FeaturesFlags.defaultValue, 2);
      for (final feature in FeaturesFlags.values) {
        expect(feature.key, startsWith('ff_'));
        expect(
          FirebaseService.remoteDefaults[feature.key],
          2,
          reason: feature.key,
        );
      }
      // The old boolean plan gates are gone: the flags carry the Premium rule.
      expect(
        FirebaseService.remoteDefaults.containsKey('cook_mode_premium_only'),
        isFalse,
      );
      expect(
        FirebaseService.remoteDefaults.containsKey('assistant_premium_only'),
        isFalse,
      );
      expect(
        FirebaseService.remoteDefaults.containsKey(
          'notifications_premium_only',
        ),
        isFalse,
      );
    },
  );

  test('keys are unique', () {
    final keys = FeaturesFlags.values.map((f) => f.key).toSet();
    expect(keys.length, FeaturesFlags.values.length);
  });

  group('overrides', () {
    tearDown(() => FeaturesFlags.overrides = null);

    test('an override is what the flag reads, and the default is on', () {
      expect(FeaturesFlags.books.value, FeatureFlagValue.enabled);
      FeaturesFlags.overrides = {FeaturesFlags.books: FeatureFlagValue.hidden};
      expect(FeaturesFlags.books.value, FeatureFlagValue.hidden);
      expect(FeaturesFlags.books.isVisible, isFalse);
    });

    test('ofAny takes the most permissive, and nothing means on', () {
      FeaturesFlags.overrides = {
        FeaturesFlags.shareRecipes: FeatureFlagValue.hidden,
        FeaturesFlags.shareBooks: FeatureFlagValue.comingSoon,
        FeaturesFlags.sharePlans: FeatureFlagValue.hidden,
      };
      expect(
        FeaturesFlags.ofAny([
          FeaturesFlags.shareRecipes,
          FeaturesFlags.shareBooks,
          FeaturesFlags.sharePlans,
        ]),
        FeatureAccess.comingSoon,
      );
      FeaturesFlags.overrides = {
        FeaturesFlags.shareRecipes: FeatureFlagValue.hidden,
        FeaturesFlags.shareBooks: FeatureFlagValue.hidden,
      };
      expect(
        FeaturesFlags.ofAny([
          FeaturesFlags.shareRecipes,
          FeaturesFlags.shareBooks,
        ]),
        FeatureAccess.hidden,
      );
      expect(FeaturesFlags.ofAny(const []), FeatureAccess.enabled);
    });
  });
}
