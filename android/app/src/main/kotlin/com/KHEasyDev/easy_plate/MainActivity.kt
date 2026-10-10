package com.KHEasyDev.easy_plate

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin
import com.KHEasyDev.easy_plate.widgets.HomeWidgetsChannel
import com.KHEasyDev.easy_plate.wakeword.WakeWordChannel
import com.KHEasyDev.easy_plate.wakeword.WakeWordController
import com.KHEasyDev.easy_plate.wakeword.ShefiVoiceEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity rather than FlutterActivity: RevenueCat's paywall and
// Customer Center are fragments and refuse to show from a plain activity.
class MainActivity : FlutterFragmentActivity() {
    /** Must match `AdsConfig.nativeFactoryId` on the Dart side. */
    private val nativeAdFactoryId = "easyPlateCard"

    /** The home-screen widgets' channel; see widgets/HomeWidgetsChannel.kt. */
    private var homeWidgets: HomeWidgetsChannel? = null

    /** "Hey Shefi"; see wakeword/WakeWordController.kt. */
    private var wakeWord: WakeWordChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        homeWidgets = HomeWidgetsChannel(applicationContext, flutterEngine)
        wakeWord = WakeWordChannel(this, flutterEngine)
        // Shefi's answers for the floating panel come from this engine while
        // it is alive; see wakeword/ShefiVoiceEngine.kt.
        ShefiVoiceEngine.mainChannel =
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ShefiVoiceEngine.CHANNEL)
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            nativeAdFactoryId,
            EasyPlateNativeAdFactory(layoutInflater),
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        homeWidgets?.dispose()
        homeWidgets = null
        wakeWord?.dispose()
        wakeWord = null
        ShefiVoiceEngine.mainChannel = null
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, nativeAdFactoryId)
        super.cleanUpFlutterEngine(flutterEngine)
    }

    // The foreground-only listener runs while this activity is resumed, and
    // a microphone service may only be started while it is.
    override fun onResume() {
        super.onResume()
        WakeWordController.init(this)
        WakeWordController.setActivityResumed(true)
    }

    override fun onPause() {
        WakeWordController.setActivityResumed(false)
        super.onPause()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        if (wakeWord?.onRequestPermissionsResult(requestCode) == true) return
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }
}
