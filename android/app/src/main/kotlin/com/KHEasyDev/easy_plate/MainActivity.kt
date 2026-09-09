package com.KHEasyDev.easy_plate

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterActivity() {
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
