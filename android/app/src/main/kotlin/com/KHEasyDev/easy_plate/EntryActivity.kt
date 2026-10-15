package com.KHEasyDev.easy_plate

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import com.KHEasyDev.easy_plate.wakeword.ShefiOverlay
import com.KHEasyDev.easy_plate.wakeword.WakeWordController

/**
 * The app's launcher entry: transparent, with no layout of its own.
 *
 * Every ordinary launch (the icon, a notification, anything that asks the
 * system for the app's launch intent) is passed on to MainActivity as it
 * came, extras and all, and this closes before drawing anything.
 *
 * A launch by Gemini ("פתח את Easy Plate"), when the user left that on in
 * the "היי שפי" settings, becomes Shefi instead: either the floating panel
 * drawn right here over whatever was on screen, or the app opened on the
 * chat. Gemini opens apps only by name, so its launch is the voice door to
 * Shefi with no microphone of ours open before it.
 */
class EntryActivity : Activity() {
    private var panel: ShefiOverlay? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val prefs = getSharedPreferences(WakeWordController.PREFS, MODE_PRIVATE)
        val viaGemini = openedByAssistant(intent) &&
            prefs.getBoolean(WakeWordController.ASSISTANT_OPENS_SHEFI, false)

        if (viaGemini && prefs.getBoolean(WakeWordController.ASSISTANT_PANEL, true)) {
            WakeWordController.init(this)
            // Our own "Hey Shefi" listener, if on, gives up the microphone.
            WakeWordController.hold(PANEL_HOLD)
            panel = ShefiOverlay(
                this,
                onClosed = {
                    panel = null
                    WakeWordController.release(PANEL_HOLD)
                },
                host = this,
            ).also { it.start("") }
            return
        }

        // A copy of the launcher's intent, minus what this trampoline's own
        // manifest added to it: excludeFromRecents puts
        // FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS on the intent, and carried over it
        // hid the app's real task from the recent apps screen.
        val forward = Intent(intent).setClass(this, MainActivity::class.java)
        forward.removeFlags(Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS or Intent.FLAG_ACTIVITY_NO_HISTORY)
        if (viaGemini) {
            forward.action = Intent.ACTION_VIEW
            forward.data = Uri.parse("easyplate://open/widget/assistant?voice=1&source=launcher")
        }
        startActivity(forward)
        finish()
        @Suppress("DEPRECATION")
        overridePendingTransition(0, 0)
    }

    override fun onDestroy() {
        panel?.close()
        super.onDestroy()
    }

    private fun openedByAssistant(intent: Intent?): Boolean {
        if (intent?.action != Intent.ACTION_MAIN || intent.data != null) return false
        val from = referrer?.host ?: return false
        return from in ASSISTANT_PACKAGES
    }

    companion object {
        private const val PANEL_HOLD = "gemini_panel"

        /** The packages Gemini (and the Google app before it) launch apps from. */
        private val ASSISTANT_PACKAGES = setOf(
            "com.google.android.googlequicksearchbox",
            "com.google.android.apps.bard",
            "com.google.android.apps.googleassistant",
            "com.google.android.as",
        )
    }
}
