package com.KHEasyDev.easy_plate

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import com.KHEasyDev.easy_plate.wakeword.ShefiOverlay
import com.KHEasyDev.easy_plate.wakeword.WakeWordController
import com.KHEasyDev.easy_plate.widgets.WidgetIntents

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
        // The home-screen Shefi widget asks for the panel outright (Koby:
        // the widget must not open the app's chat). Only our own widget's
        // PendingIntent (it carries the trust token): the panel opens
        // listening, and this activity is exported, so any other app asking
        // for it would switch the microphone on — it just opens the app.
        val viaWidget = intent?.action == ACTION_SHEFI_PANEL && WidgetIntents.isTrusted(this, intent)

        if (viaWidget || (viaGemini && prefs.getBoolean(WakeWordController.ASSISTANT_PANEL, true))) {
            WakeWordController.init(this)
            // Our own "Hey Shefi" listener, if on, gives up the microphone.
            WakeWordController.hold(PANEL_HOLD)
            // Only our own widget's PendingIntent may hand Shefi a request;
            // any other app reaching this exported activity just opens it.
            val prompt = if (WidgetIntents.isTrusted(this, intent)) {
                intent?.getStringExtra(EXTRA_PROMPT).orEmpty()
            } else {
                ""
            }
            panel = ShefiOverlay(
                this,
                onClosed = {
                    panel = null
                    WakeWordController.release(PANEL_HOLD)
                },
                host = this,
            ).also { it.start(prompt) }
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
            // Decided here (the referrer is Gemini), so MainActivity keeps `voice`.
            forward.putExtra(WidgetIntents.EXTRA_TRUST, WidgetIntents.trustToken(this))
        } else {
            // A forwarded launch never vouches for itself: drop any token-looking
            // extra a caller put on it (it could only guess, but be explicit).
            forward.removeExtra(WidgetIntents.EXTRA_TRUST)
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

    /**
     * Only the system's own record of who started this activity counts.
     * `Activity.getReferrer()` first returns whatever the caller put in
     * `EXTRA_REFERRER` / `EXTRA_REFERRER_NAME` (any app can write
     * "android-app://com.google.android.googlequicksearchbox" there and,
     * with "Gemini opens Shefi" on, have the panel open listening); only
     * when neither extra is present does it fall back to the package the
     * ActivityManager saw launch us, which cannot be spoofed. A real Gemini
     * launch still passes: with the extras gone the referrer is the package
     * that actually started us, which is Gemini's.
     */
    private fun openedByAssistant(intent: Intent?): Boolean {
        if (intent?.action != Intent.ACTION_MAIN || intent.data != null) return false
        try {
            intent.removeExtra(Intent.EXTRA_REFERRER)
            intent.removeExtra(Intent.EXTRA_REFERRER_NAME)
        } catch (_: Exception) {
            return false // a malformed extras bundle from another app
        }
        val from = referrer?.host ?: return false
        return from in ASSISTANT_PACKAGES
    }

    companion object {
        /** From the Shefi home-screen widget: the floating panel, here. */
        const val ACTION_SHEFI_PANEL = "com.KHEasyDev.easy_plate.SHEFI_PANEL"
        const val EXTRA_VOICE = "voice"
        const val EXTRA_PROMPT = "prompt"

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
