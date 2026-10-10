package com.KHEasyDev.easy_plate.widgets

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * A tick on a list widget's row: queued for the app, drawn at once, and
 * the app nudged if it is alive. Nothing is written to the account's own
 * boxes from here — see `HomeWidgetsService` on the Dart side for why.
 */
class WidgetActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_TOGGLE) return
        val listId = intent.getStringExtra(EXTRA_LIST_ID) ?: return
        val itemId = intent.getStringExtra(EXTRA_ITEM_ID) ?: return
        val checked = intent.getBooleanExtra(EXTRA_CHECKED, true)
        WidgetStore.enqueue(context, PendingAction.toggle(listId, itemId, checked))
        WidgetUpdater.refreshAll(context)
        HomeWidgetsChannel.nudge()
    }

    companion object {
        const val ACTION_TOGGLE = "com.KHEasyDev.easy_plate.widgets.TOGGLE"
        const val EXTRA_LIST_ID = "listId"
        const val EXTRA_ITEM_ID = "itemId"
        const val EXTRA_CHECKED = "checked"
    }
}
