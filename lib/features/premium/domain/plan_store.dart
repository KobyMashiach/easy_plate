import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Whether a plan bought in [planStore] can be changed from this device's
/// store. A subscriber on the App Store opening the paywall on Android
/// must not hand Google Play an App Store product to replace — Play
/// refuses the whole purchase. An unknown store keeps the old behaviour
/// (pass it): dropping it could sell a second Play subscription instead.
bool planReplaceableHere(Store? planStore, TargetPlatform platform) =>
    switch (planStore) {
      null || Store.unknownStore => true,
      Store.playStore => platform == TargetPlatform.android,
      Store.appStore || Store.macAppStore =>
        platform == TargetPlatform.iOS || platform == TargetPlatform.macOS,
      _ => false,
    };
