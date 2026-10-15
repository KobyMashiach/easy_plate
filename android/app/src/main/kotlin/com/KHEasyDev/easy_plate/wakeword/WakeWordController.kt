package com.KHEasyDev.easy_plate.wakeword

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import com.KHEasyDev.easy_plate.R
import org.json.JSONObject

/**
 * The one place that decides where the "Hey Shefi" listener runs.
 *
 * Dart sends the wanted state (`configure`): `off`, `foreground` (a listener
 * owned here, alive only while the app's activity is resumed) or
 * `background` (the microphone foreground service, which also survives the
 * task being swiped away). The state is kept in SharedPreferences, so the
 * service still has its words and texts when no engine is around.
 *
 * A detection pauses listening until Dart says the chat has closed
 * ([resumeAfterDetection]) or, if nothing ever opens, for [HEARD_PAUSE_MS].
 */
object WakeWordController {
    private const val TAG = "WakeWord"
    const val PREFS = "easy_plate_wake_word"

    /** Whether a launch by Gemini opens on Shefi (read by MainActivity). */
    const val ASSISTANT_OPENS_SHEFI = "assistantOpensShefi"

    /** …as the floating panel (true) or the app's chat (false). */
    const val ASSISTANT_PANEL = "assistantPanel"
    private const val HEARD_PAUSE_MS = 90_000L
    const val CHANNEL_LISTENING = "wake_word"
    const val CHANNEL_HEARD = "wake_word_heard"
    const val HEARD_NOTIFICATION_ID = 13001

    private lateinit var appContext: Context
    private val handler = Handler(Looper.getMainLooper())

    var mode = "off"
        private set
    private var paused = false
    var locale = "en-US"
        private set
    private var texts = JSONObject()

    private var heardPause = false
    private val holds = mutableSetOf<String>()
    private var activityResumed = false
    private var foregroundListener: KwsListener? = null

    /** The floating panel of a conversation started from outside the app. */
    private var overlay: ShefiOverlay? = null

    /** Set by the channel while an engine is attached. */
    var channel: WakeWordChannel? = null

    private var initialized = false

    fun init(context: Context) {
        if (initialized) return
        initialized = true
        appContext = context.applicationContext
        val prefs = appContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        mode = prefs.getString("mode", "off") ?: "off"
        paused = prefs.getBoolean("paused", false)
        locale = prefs.getString("locale", "en-US") ?: "en-US"
        texts = try {
            JSONObject(prefs.getString("texts", "{}") ?: "{}")
        } catch (e: Exception) {
            JSONObject()
        }
    }

    fun text(key: String, fallback: String): String =
        texts.optString(key).takeIf { it.isNotEmpty() } ?: fallback

    /** Whether the listener should hold the microphone right now. */
    val shouldListen: Boolean get() = !paused && !heardPause && holds.isEmpty()

    fun configure(
        newMode: String,
        newPaused: Boolean,
        newLocale: String,
        phrases: JSONObject,
        newTexts: JSONObject,
    ) {
        val localeChanged = newLocale != locale
        mode = newMode
        paused = newPaused
        locale = newLocale
        texts = newTexts
        appContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString("mode", mode)
            .putBoolean("paused", paused)
            .putString("locale", locale)
            .putString("phrases", phrases.toString())
            .putString("texts", texts.toString())
            .apply()
        if (mode == "off") heardPause = false
        apply(localeChanged)
    }

    fun setActivityResumed(resumed: Boolean) {
        activityResumed = resumed
        apply(false)
    }

    /** Something native needs the microphone (the widgets' dictation). */
    fun hold(reason: String) {
        if (holds.add(reason)) apply(false)
    }

    fun release(reason: String) {
        if (holds.remove(reason)) apply(false)
    }

    fun resumeAfterDetection() {
        handler.removeCallbacks(heardTimeout)
        if (!heardPause) return
        heardPause = false
        apply(false)
    }

    private val heardTimeout = Runnable {
        // A conversation in the floating panel still owns the microphone.
        if (overlay != null) return@Runnable
        heardPause = false
        apply(false)
    }

    /** The notification's "Stop": background listening off until the app
     *  turns it back on. Dart is told now if it is alive, or on its next
     *  start through [takeBackgroundStop]. */
    fun stopFromNotification() {
        appContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putBoolean("stoppedFromNotification", true)
            .apply()
        mode = if (mode == "background") "foreground" else mode
        apply(false)
        channel?.backgroundStopped()
    }

    fun takeBackgroundStop(): Boolean {
        val prefs = appContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val stopped = prefs.getBoolean("stoppedFromNotification", false)
        if (stopped) prefs.edit().remove("stoppedFromNotification").apply()
        return stopped
    }

    private fun apply(localeChanged: Boolean) {
        when (mode) {
            "background" -> {
                stopForegroundListener()
                val service = WakeWordService.instance
                if (service != null) {
                    service.refresh(localeChanged)
                } else if (activityResumed) {
                    // Android 14 only lets a microphone service start while
                    // the app is visible; it then keeps the microphone
                    // after the app is closed.
                    WakeWordService.start(appContext)
                }
            }
            "foreground" -> {
                WakeWordService.stop(appContext)
                if (activityResumed && shouldListen) {
                    val listener = foregroundListener ?: KwsListener(appContext, ::onHeard)
                        .also { foregroundListener = it }
                    listener.start()
                } else {
                    stopForegroundListener()
                }
            }
            else -> {
                WakeWordService.stop(appContext)
                stopForegroundListener()
            }
        }
    }

    private fun stopForegroundListener() {
        foregroundListener?.stop()
        foregroundListener = null
    }

    /** Heard: pause, then open the chat the quickest way allowed. */
    fun onHeard(command: String) {
        Log.i(TAG, "Wake words heard, command='${command.take(40)}'")
        heardPause = true
        handler.removeCallbacks(heardTimeout)
        handler.postDelayed(heardTimeout, HEARD_PAUSE_MS)
        apply(false)

        val live = channel
        if (activityResumed && live != null) {
            live.detected(command)
            return
        }
        // Outside the app: the floating panel, Gemini-style, when the user
        // allowed "display over other apps".
        if (Settings.canDrawOverlays(appContext)) {
            overlay?.close()
            overlay = ShefiOverlay(appContext, onClosed = {
                overlay = null
                resumeAfterDetection()
            }).also { it.start(command) }
            return
        }
        val open = launchIntent(command)
        // Without "display over other apps" nothing may appear over another
        // app: a notification asks for the tap instead.
        postHeardNotification(open)
    }

    /** The same deep link a Shefi widget opens, marked as the wake word's. */
    private fun launchIntent(command: String): Intent {
        val uri = Uri.Builder()
            .scheme("easyplate")
            .authority("open")
            .path("/widget/assistant")
            .appendQueryParameter("voice", "1")
            .appendQueryParameter("source", "wake")
            .apply { if (command.isNotEmpty()) appendQueryParameter("prompt", command) }
            .build()
        return Intent(Intent.ACTION_VIEW, uri).apply {
            setPackage(appContext.packageName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
    }

    private fun postHeardNotification(open: Intent) {
        val manager = appContext.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        ensureChannels(manager)
        val tap = PendingIntent.getActivity(
            appContext,
            HEARD_NOTIFICATION_ID,
            open,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(appContext, CHANNEL_HEARD)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(appContext).setPriority(Notification.PRIORITY_HIGH)
        }
        val notification = builder
            .setSmallIcon(R.drawable.ic_stat_shefi)
            .setContentTitle(text("heardTitle", "Shefi"))
            .setContentText(text("heardBody", "Tap to talk to Shefi"))
            .setContentIntent(tap)
            .setAutoCancel(true)
            .setCategory(Notification.CATEGORY_REMINDER)
            .setTimeoutAfterCompat(60_000)
            .build()
        try {
            manager.notify(HEARD_NOTIFICATION_ID, notification)
        } catch (e: SecurityException) {
            Log.w(TAG, "Notification refused", e)
        }
    }

    private fun Notification.Builder.setTimeoutAfterCompat(ms: Long): Notification.Builder =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) setTimeoutAfter(ms) else this

    fun ensureChannels(manager: NotificationManager) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_LISTENING,
                text("channelListening", "Listening for \"Hey Shefi\""),
                NotificationManager.IMPORTANCE_LOW,
            ).apply { setShowBadge(false) },
        )
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_HEARD,
                text("channelHeard", "Shefi heard you"),
                NotificationManager.IMPORTANCE_HIGH,
            ),
        )
    }
}
