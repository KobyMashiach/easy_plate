package com.KHEasyDev.easy_plate.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.lang.ref.WeakReference

/**
 * `easy_plate/home_widgets`, the Dart side's door to the widgets: the
 * snapshot in, the queue out, and the launcher's pin sheet. Mirrors
 * `lib/core/home_widgets/home_widgets_channel.dart`.
 *
 * Also the way back: [nudge] tells a running engine that a widget just
 * wrote to the queue, so the app applies it now rather than on its next
 * launch. The channel is held weakly — a widget must never keep a dead
 * engine alive.
 */
class HomeWidgetsChannel(private val context: Context, engine: FlutterEngine) {
    private val channel = MethodChannel(engine.dartExecutor.binaryMessenger, NAME)

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "publish" -> {
                    val snapshot = call.argument<String>("snapshot")
                    if (snapshot != null) WidgetStore.writeSnapshot(context, snapshot)
                    WidgetUpdater.refreshAll(context)
                    result.success(null)
                }
                "clear" -> {
                    WidgetStore.clearSnapshot(context)
                    WidgetUpdater.refreshAll(context)
                    result.success(null)
                }
                "readPending" -> result.success(WidgetStore.pendingJson(context))
                "removePending" -> {
                    val ids = call.argument<List<String>>("ids") ?: emptyList()
                    WidgetStore.removePending(context, ids)
                    result.success(null)
                }
                "pinSupported" -> result.success(pinSupported())
                "pinWidget" -> result.success(pin(call.argument<String>("kind")))
                "installedCounts" -> result.success(installedCounts())
                else -> result.notImplemented()
            }
        }
        live = WeakReference(channel)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        if (live?.get() === channel) live = null
    }

    private fun pinSupported(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        return AppWidgetManager.getInstance(context).isRequestPinAppWidgetSupported
    }

    private fun pin(kind: String?): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        val provider = WidgetKind.fromId(kind)?.provider ?: return false
        val manager = AppWidgetManager.getInstance(context)
        if (!manager.isRequestPinAppWidgetSupported) return false
        // The launcher confirms; nothing to do on success, so no callback.
        return manager.requestPinAppWidget(ComponentName(context, provider), null, null as PendingIntent?)
    }

    private fun installedCounts(): Map<String, Int> {
        val manager = AppWidgetManager.getInstance(context)
        return WidgetKind.values().associate { kind ->
            kind.id to manager.getAppWidgetIds(ComponentName(context, kind.provider)).size
        }
    }

    companion object {
        const val NAME = "easy_plate/home_widgets"
        private var live: WeakReference<MethodChannel>? = null

        /** A widget wrote to the queue: the app, if alive, applies it now. */
        fun nudge() {
            val channel = live?.get() ?: return
            Handler(Looper.getMainLooper()).post {
                try {
                    channel.invokeMethod("pendingChanged", null)
                } catch (_: Exception) {
                }
            }
        }
    }
}

/** The four widgets, by the ids the Dart side uses. */
enum class WidgetKind(val id: String, val provider: Class<*>) {
    ASSISTANT("assistant", AssistantWidgetProvider::class.java),
    GROCERY_ADD("grocery_add", GroceryAddWidgetProvider::class.java),
    GROCERY_LIST("grocery_list", GroceryListWidgetProvider::class.java),
    TODAY_MENU("today_menu", TodayMenuWidgetProvider::class.java);

    companion object {
        fun fromId(id: String?) = values().firstOrNull { it.id == id }
        fun fromProvider(className: String?) = values().firstOrNull { it.provider.name == className }
    }
}

/** Redraws every placed widget of every kind. */
object WidgetUpdater {
    fun refreshAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        for (kind in WidgetKind.values()) {
            val ids = manager.getAppWidgetIds(ComponentName(context, kind.provider))
            if (ids.isEmpty()) continue
            val intent = Intent(context, kind.provider).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            }
            context.sendBroadcast(intent)
            // The list rows live in a RemoteViewsService; they are told apart.
            manager.notifyAppWidgetViewDataChanged(ids, com.KHEasyDev.easy_plate.R.id.epw_list)
        }
    }
}
