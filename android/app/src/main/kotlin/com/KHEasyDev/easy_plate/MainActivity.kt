package com.KHEasyDev.easy_plate

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

// FlutterFragmentActivity rather than FlutterActivity: RevenueCat's paywall and
// Customer Center are fragments and refuse to show from a plain activity.
class MainActivity : FlutterFragmentActivity() {
    /** Must match `AdsConfig.nativeFactoryId` on the Dart side. */
    private val nativeAdFactoryId = "easyPlateCard"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            nativeAdFactoryId,
            EasyPlateNativeAdFactory(layoutInflater),
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, nativeAdFactoryId)
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
