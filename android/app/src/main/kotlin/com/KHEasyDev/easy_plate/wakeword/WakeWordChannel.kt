package com.KHEasyDev.easy_plate.wakeword

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

/**
 * `easy_plate/wake_word`: the Dart side's door to [WakeWordController].
 * See lib/core/wake_word/wake_word_channel.dart for the contract.
 */
class WakeWordChannel(private val activity: Activity, engine: FlutterEngine) {
    private val channel = MethodChannel(engine.dartExecutor.binaryMessenger, NAME)
    private var pendingPermission: MethodChannel.Result? = null

    init {
        WakeWordController.init(activity)
        WakeWordController.channel = this
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "configure" -> {
                    @Suppress("UNCHECKED_CAST")
                    val args = call.arguments as? Map<String, Any?> ?: emptyMap()
                    WakeWordController.configure(
                        newMode = args["mode"] as? String ?: "off",
                        newPaused = args["paused"] as? Boolean ?: false,
                        newLocale = args["locale"] as? String ?: "en-US",
                        phrases = JSONObject((args["phrases"] as? Map<*, *>) ?: emptyMap<String, Any>()),
                        newTexts = JSONObject((args["texts"] as? Map<*, *>) ?: emptyMap<String, Any>()),
                    )
                    result.success(null)
                }
                "resumeAfterDetection" -> {
                    WakeWordController.resumeAfterDetection()
                    result.success(null)
                }
                "permission" -> result.success(permissionStatus())
                "requestPermission" -> requestPermission(result)
                "canOpenFromBackground" -> result.success(Settings.canDrawOverlays(activity))
                "openBackgroundSettings" -> {
                    open(
                        Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:${activity.packageName}"),
                        ),
                    )
                    result.success(null)
                }
                "openAppSettings" -> {
                    open(
                        Intent(
                            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.parse("package:${activity.packageName}"),
                        ),
                    )
                    result.success(null)
                }
                "takePendingLaunch" -> result.success(false)
                "takeBackgroundStop" -> result.success(WakeWordController.takeBackgroundStop())
                "setAssistantOpensShefi" -> {
                    activity.getSharedPreferences(WakeWordController.PREFS, Activity.MODE_PRIVATE).edit()
                        .putBoolean(
                            WakeWordController.ASSISTANT_OPENS_SHEFI,
                            call.argument<Boolean>("enabled") == true,
                        )
                        .putBoolean(
                            WakeWordController.ASSISTANT_PANEL,
                            call.argument<Boolean>("panel") != false,
                        ).apply()
                    result.success(null)
                }
                "setLauncherIcon" -> {
                    setLauncherIcon(call.argument<Boolean>("enabled") == true)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    /** Shows or hides the "שפי" app-drawer icon (ff_shefi_launcher). */
    private fun setLauncherIcon(enabled: Boolean) {
        val component = android.content.ComponentName(activity, "${activity.packageName}.ShefiLauncher")
        val wanted = if (enabled) {
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED
        } else {
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED
        }
        val pm = activity.packageManager
        if (pm.getComponentEnabledSetting(component) == wanted) return
        try {
            pm.setComponentEnabledSetting(component, wanted, PackageManager.DONT_KILL_APP)
        } catch (_: Exception) {
        }
    }

    fun detected(command: String) {
        channel.invokeMethod("detected", mapOf("command" to command))
    }

    fun backgroundStopped() {
        channel.invokeMethod("backgroundStopped", null)
    }

    fun dispose() {
        if (WakeWordController.channel === this) WakeWordController.channel = null
        channel.setMethodCallHandler(null)
        pendingPermission?.success(permissionStatus())
        pendingPermission = null
    }

    private fun granted() =
        activity.checkSelfPermission(Manifest.permission.RECORD_AUDIO) ==
            PackageManager.PERMISSION_GRANTED

    private fun permissionStatus(): String {
        if (granted()) return "granted"
        val asked = activity.getSharedPreferences(PREFS, Activity.MODE_PRIVATE)
            .getBoolean("askedMicrophone", false)
        if (!asked) return "unknown"
        // Asked before and the system no longer shows a rationale: refused
        // for good, only the settings screen can change it.
        return if (activity.shouldShowRequestPermissionRationale(Manifest.permission.RECORD_AUDIO)) {
            "denied"
        } else {
            "permanentlyDenied"
        }
    }

    private fun requestPermission(result: MethodChannel.Result) {
        if (granted()) {
            result.success("granted")
            return
        }
        pendingPermission?.success(permissionStatus())
        pendingPermission = result
        activity.getSharedPreferences(PREFS, Activity.MODE_PRIVATE).edit()
            .putBoolean("askedMicrophone", true).apply()
        val wanted = mutableListOf(Manifest.permission.RECORD_AUDIO)
        // The background notifications ("Shefi is listening", "tap to
        // talk") need this on Android 13+.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            wanted.add(Manifest.permission.POST_NOTIFICATIONS)
        }
        activity.requestPermissions(wanted.toTypedArray(), REQUEST_CODE)
    }

    /** Forwarded by MainActivity. */
    fun onRequestPermissionsResult(requestCode: Int): Boolean {
        if (requestCode != REQUEST_CODE) return false
        pendingPermission?.success(permissionStatus())
        pendingPermission = null
        return true
    }

    private fun open(intent: Intent) {
        try {
            activity.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        } catch (_: Exception) {
        }
    }

    companion object {
        const val NAME = "easy_plate/wake_word"
        private const val PREFS = "easy_plate_wake_word_permission"
        const val REQUEST_CODE = 4711
    }
}
