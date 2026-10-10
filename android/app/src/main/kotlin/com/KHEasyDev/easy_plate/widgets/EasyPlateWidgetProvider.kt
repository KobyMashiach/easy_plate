package com.KHEasyDev.easy_plate.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.widget.RemoteViews
import com.KHEasyDev.easy_plate.R

/**
 * What the four widgets share: the snapshot and the widget's own config
 * are read, the look resolved, and the layout picked for the cell size
 * — exact per size on Android 12+ (the launcher gets one RemoteViews per
 * breakpoint and switches without a round trip), by the current options
 * below that. A widget without a signed-in account, or with the feature
 * gated in the console, draws the notice instead of its content.
 */
abstract class EasyPlateWidgetProvider : AppWidgetProvider() {
    abstract val kind: WidgetKind

    /** The breakpoints this widget has layouts for, smallest first, in dp. */
    abstract val breakpoints: List<SizeF>

    /** The content for one breakpoint. */
    abstract fun build(ctx: WidgetContext, size: SizeF): RemoteViews

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) update(context, manager, id)
    }

    override fun onAppWidgetOptionsChanged(context: Context, manager: AppWidgetManager, id: Int, options: Bundle) {
        update(context, manager, id)
    }

    override fun onDeleted(context: Context, ids: IntArray) {
        WidgetStore.removeConfig(context, ids)
    }

    fun update(context: Context, manager: AppWidgetManager, id: Int) {
        val snapshot = WidgetStore.snapshot(context)
        val config = WidgetStore.config(context, id)
        val ctx = WidgetContext(context, id, config, snapshot, WidgetPalette.resolve(context, config, snapshot))
        val views = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            RemoteViews(breakpoints.associateWith { size -> render(ctx, size) })
        } else {
            val options = manager.getAppWidgetOptions(id)
            val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0).toFloat()
            val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 0).toFloat()
            render(ctx, pick(width, height))
        }
        manager.updateAppWidget(id, views)
    }

    /** The largest breakpoint that fits, else the smallest. */
    private fun pick(width: Float, height: Float): SizeF =
        breakpoints.lastOrNull { it.width <= width && it.height <= height } ?: breakpoints.first()

    /** The console's verdict on this widget's own feature, over the widgets' one. */
    open fun access(snapshot: WidgetSnapshot): String = snapshot.access

    private fun render(ctx: WidgetContext, size: SizeF): RemoteViews {
        val snapshot = ctx.snapshot
        if (snapshot == null || !snapshot.signedIn) return notice(ctx, size, null)
        val access = if (snapshot.access != "enabled") snapshot.access else access(snapshot)
        if (access != "enabled") return notice(ctx, size, access)
        return build(ctx, size)
    }

    /** Signed out, coming soon, Premium, or hidden: one card that says so. */
    private fun notice(ctx: WidgetContext, size: SizeF, access: String?): RemoteViews {
        val p = ctx.palette
        val s = ctx.snapshot
        val rv = RemoteViews(ctx.context.packageName, R.layout.epw_notice)
        Rv.background(rv, R.id.epw_root, p.card)
        Rv.direction(rv, R.id.epw_root, s?.rtl ?: false)
        val (icon, text) = when {
            s == null || !s.signedIn -> R.drawable.epw_ic_lock to (s?.s("signIn") ?: ctx.context.getString(R.string.epw_sign_in))
            access == "comingSoon" -> R.drawable.epw_ic_schedule to s.s("comingSoon")
            access == "locked" -> R.drawable.epw_ic_crown to s.s("premiumOnly")
            else -> R.drawable.epw_ic_lock to s.s("unavailable")
        }
        rv.setImageViewResource(R.id.epw_notice_icon, icon)
        Rv.tint(rv, R.id.epw_notice_icon, p.primary)
        Rv.text(rv, R.id.epw_notice_text, text, p.onSurfaceVariant)
        rv.setViewVisibility(R.id.epw_notice_text, if (size.height < 80) android.view.View.GONE else android.view.View.VISIBLE)
        rv.setOnClickPendingIntent(R.id.epw_root, WidgetIntents.open(ctx.context, "settings"))
        return rv
    }
}

/** Everything a build needs, resolved once per update. */
class WidgetContext(
    val context: Context,
    val widgetId: Int,
    val config: WidgetConfig,
    val snapshot: WidgetSnapshot?,
    val palette: WidgetPalette,
) {
    val s: WidgetSnapshot get() = snapshot!!
    fun str(key: String) = snapshot?.s(key) ?: key
    fun views(layout: Int): RemoteViews = RemoteViews(context.packageName, layout).also {
        Rv.background(it, R.id.epw_root, palette.card)
        Rv.direction(it, R.id.epw_root, snapshot?.rtl ?: false)
    }

    /** The list this widget shows: its own choice, else the defaults, else the first. */
    val list: WidgetList? get() = snapshot?.list(config.listId)
    val plan: WidgetPlan? get() = snapshot?.plan(config.planId)
    val voice: Boolean get() = config.voice ?: snapshot?.defaults?.voice ?: false
}
