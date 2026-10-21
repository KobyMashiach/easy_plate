package com.KHEasyDev.easy_plate.wakeword

import android.app.KeyguardManager
import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import com.KHEasyDev.easy_plate.MainActivity
import com.KHEasyDev.easy_plate.R

/**
 * "Hey Shefi" with the app closed: a foreground service of type microphone
 * that runs the [WakeWordListener] and shows a permanent, low-importance
 * notification with a Stop action.
 *
 * `stopWithTask="false"` keeps it going after the task is swiped away. It
 * pauses while the screen is off (the recognizer loop would only cost
 * battery, and nothing can open over a locked phone), resumes when the
 * phone is unlocked, and gives the microphone up whenever
 * [WakeWordController.shouldListen] says so.
 *
 * Android 14 refuses to (re)start a microphone service from the background,
 * so a sticky restart after the process was killed fails; that is caught
 * and the service ends quietly until the app is opened again.
 */
class WakeWordService : Service() {
    private lateinit var listener: KwsListener
    private var screenReceiver: BroadcastReceiver? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        WakeWordController.init(this)
        listener = KwsListener(this) { WakeWordController.onHeard(it) }
        instance = this
        registerScreenReceiver()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            WakeWordController.stopFromNotification()
            return START_NOT_STICKY
        }
        if (WakeWordController.mode != "background") {
            stopSelf()
            return START_NOT_STICKY
        }
        try {
            val notification = buildNotification()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE,
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            Log.w(TAG, "Microphone service could not start in the foreground", e)
            stopSelf()
            return START_NOT_STICKY
        }
        refresh(false)
        return START_STICKY
    }

    /** Words, language or pause state changed. */
    fun refresh(localeChanged: Boolean) {
        if (WakeWordController.shouldListen) {
            listener.resume(PAUSED)
            listener.start()
            if (localeChanged) listener.restart()
        } else {
            listener.suspend(PAUSED)
        }
    }

    override fun onDestroy() {
        listener.stop()
        screenReceiver?.let { receiver ->
            // Registered once per filter (see registerScreenReceiver).
            repeat(2) {
                try {
                    unregisterReceiver(receiver)
                } catch (_: IllegalArgumentException) {
                }
            }
        }
        screenReceiver = null
        if (instance === this) instance = null
        super.onDestroy()
    }

    /**
     * All three are protected broadcasts (only the system may send them), so
     * the receiver is registered unexported on Android 13+, where the flag
     * exists. One exception: ACTION_USER_PRESENT is sent by SystemUI, which
     * runs under its own uid rather than the system's, and an unexported
     * receiver only accepts the system uid and our own, so that one filter
     * stays exported, or the listener would never resume after an unlock.
     */
    private fun registerScreenReceiver() {
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                when (intent.action) {
                    Intent.ACTION_SCREEN_OFF -> listener.suspend(SCREEN)
                    Intent.ACTION_USER_PRESENT -> listener.resume(SCREEN)
                    Intent.ACTION_SCREEN_ON -> {
                        val keyguard = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
                        if (!keyguard.isKeyguardLocked) listener.resume(SCREEN)
                    }
                }
            }
        }
        val screen = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
        }
        val unlock = IntentFilter(Intent.ACTION_USER_PRESENT)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(receiver, screen, Context.RECEIVER_NOT_EXPORTED)
            registerReceiver(receiver, unlock, Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(receiver, screen)
            registerReceiver(receiver, unlock)
        }
        screenReceiver = receiver
    }

    private fun buildNotification(): Notification {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        WakeWordController.ensureChannels(manager)
        val open = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val stop = PendingIntent.getService(
            this,
            1,
            Intent(this, WakeWordService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, WakeWordController.CHANNEL_LISTENING)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this).setPriority(Notification.PRIORITY_LOW)
        }
        val stopAction = Notification.Action.Builder(
            null,
            WakeWordController.text("stop", "Stop"),
            stop,
        ).build()
        return builder
            .setSmallIcon(R.drawable.ic_stat_shefi)
            .setContentTitle(WakeWordController.text("listeningTitle", "Shefi is listening"))
            .setContentText(WakeWordController.text("listeningBody", "Say \"Hey Shefi\""))
            .setContentIntent(open)
            .setOngoing(true)
            .setShowWhen(false)
            .addAction(stopAction)
            .build()
    }

    companion object {
        private const val TAG = "WakeWord"
        private const val NOTIFICATION_ID = 13000
        private const val ACTION_STOP = "com.KHEasyDev.easy_plate.wakeword.STOP"
        private const val PAUSED = "paused"
        private const val SCREEN = "screen"

        @Volatile
        var instance: WakeWordService? = null
            private set

        fun start(context: Context) {
            val intent = Intent(context, WakeWordService::class.java)
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (e: Exception) {
                Log.w(TAG, "Could not start the wake word service", e)
            }
        }

        fun stop(context: Context) {
            if (instance == null) return
            context.stopService(Intent(context, WakeWordService::class.java))
        }
    }
}
