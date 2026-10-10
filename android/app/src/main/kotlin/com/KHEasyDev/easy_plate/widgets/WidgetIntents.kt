package com.KHEasyDev.easy_plate.widgets

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import com.KHEasyDev.easy_plate.MainActivity

/**
 * Where a tap goes. Every tap into the app is a deep link on the app's
 * own scheme — `easyplate://open/widget/<action>?…` — which Flutter hands to
 * the router like any other link (see `HomeWidgetLaunch` on the Dart
 * side). Taps that stay on the home screen (a tick, the quick-add dialog)
 * go to native screens of their own.
 */
object WidgetIntents {
    private const val SCHEME = "easyplate://open/widget/"

    fun open(context: Context, action: String, vararg params: Pair<String, String?>): PendingIntent {
        val builder = Uri.parse(SCHEME + action).buildUpon()
        for ((key, value) in params) if (!value.isNullOrEmpty()) builder.appendQueryParameter(key, value)
        val uri = builder.build()
        val intent = Intent(Intent.ACTION_VIEW, uri, context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        return PendingIntent.getActivity(
            context,
            uri.toString().hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    fun assistant(context: Context, voice: Boolean, prompt: String? = null) =
        open(context, "assistant", "voice" to if (voice) "1" else null, "prompt" to prompt)

    fun grocery(context: Context, listId: String?, add: Boolean = false) =
        open(context, "grocery", "list" to listId, "add" to if (add) "1" else null)

    fun plan(context: Context, planId: String?) = open(context, "plan", "plan" to planId)

    fun settings(context: Context) = open(context, "settings")

    /** The quick-add dialog, on the home screen, for [listId]. */
    fun quickAdd(context: Context, widgetId: Int, listId: String?, voice: Boolean = false): PendingIntent {
        val intent = Intent(context, WidgetQuickAddActivity::class.java).apply {
            putExtra(WidgetQuickAddActivity.EXTRA_WIDGET_ID, widgetId)
            putExtra(WidgetQuickAddActivity.EXTRA_LIST_ID, listId)
            putExtra(WidgetQuickAddActivity.EXTRA_VOICE, voice)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            // Distinct data so two widgets' intents never collapse into one.
            data = Uri.parse("easyplate-widget://quick-add/$widgetId?voice=$voice")
        }
        return PendingIntent.getActivity(
            context,
            ("quick-add-$widgetId-$voice").hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /** The widget's own settings screen. */
    fun configure(context: Context, widgetId: Int): PendingIntent {
        val intent = Intent(context, WidgetConfigActivity::class.java).apply {
            putExtra(android.appwidget.AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            putExtra(WidgetConfigActivity.EXTRA_RECONFIGURE, true)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            data = Uri.parse("easyplate-widget://configure/$widgetId")
        }
        return PendingIntent.getActivity(
            context,
            ("configure-$widgetId").hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /** The broadcast template a list row's tick fills in. */
    fun toggleTemplate(context: Context, widgetId: Int): PendingIntent {
        val intent = Intent(context, WidgetActionReceiver::class.java).apply {
            action = WidgetActionReceiver.ACTION_TOGGLE
            data = Uri.parse("easyplate-widget://toggle/$widgetId")
        }
        return PendingIntent.getBroadcast(
            context,
            ("toggle-$widgetId").hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
        )
    }
}
