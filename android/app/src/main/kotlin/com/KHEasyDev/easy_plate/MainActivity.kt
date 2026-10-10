package com.KHEasyDev.easy_plate

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin
import com.KHEasyDev.easy_plate.widgets.HomeWidgetsChannel

// FlutterFragmentActivity rather than FlutterActivity: RevenueCat's paywall and
// Customer Center are fragments and refuse to show from a plain activity.
class MainActivity : FlutterFragmentActivity() {
    /** Must match `AdsConfig.nativeFactoryId` on the Dart side. */
    private val nativeAdFactoryId = "easyPlateCard"

    /** The home-screen widgets' channel; see widgets/HomeWidgetsChannel.kt. */
    private var homeWidgets: HomeWidgetsChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        homeWidgets = HomeWidgetsChannel(applicationContext, flutterEngine)
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            nativeAdFactoryId,
            EasyPlateNativeAdFactory(layoutInflater),
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        homeWidgets?.dispose()
        homeWidgets = null
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, nativeAdFactoryId)
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
