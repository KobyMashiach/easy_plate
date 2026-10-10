package com.KHEasyDev.easy_plate.widgets

import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import com.KHEasyDev.easy_plate.R

/**
 * Quick add: the list's name, how much of it is still to buy, and two
 * buttons — type, or dictate — that open the quick-add dialog right on
 * the home screen. The list is the widget's own choice, or the defaults'.
 */
class GroceryAddWidgetProvider : EasyPlateWidgetProvider() {
    override val kind = WidgetKind.GROCERY_ADD

    override val breakpoints = listOf(
        SizeF(50f, 50f),    // round + button
        SizeF(130f, 50f),   // name + two buttons
        SizeF(250f, 50f),   // + hint and progress
    )

    override fun build(ctx: WidgetContext, size: SizeF): RemoteViews {
        val p = ctx.palette
        val c = ctx.context
        val list = ctx.list
        if (size.width < 130f) {
            val rv = RemoteViews(c.packageName, R.layout.epw_grocery_add_round)
            Rv.background(rv, R.id.epw_root, p.roundPrimary)
            Rv.tint(rv, R.id.epw_icon, p.onPrimary)
            rv.setOnClickPendingIntent(R.id.epw_root, WidgetIntents.quickAdd(c, ctx.widgetId, list?.id))
            rv.setContentDescription(R.id.epw_root, ctx.str("quickAdd"))
            return rv
        }
        val wide = size.width >= 250f
        val rv = ctx.views(if (wide) R.layout.epw_grocery_add_wide else R.layout.epw_grocery_add)
        Rv.tint(rv, R.id.epw_icon, p.primary)
        Rv.text(rv, R.id.epw_title, list?.name ?: ctx.str("noLists"), p.onSurface)
        val subtitle = when {
            list == null -> ctx.str("openApp")
            list.total == 0 -> ctx.str("emptyList")
            list.remaining == 0 -> ctx.str("allDone")
            else -> ctx.str("remaining").replace("{n}", list.remaining.toString())
        }
        Rv.text(rv, R.id.epw_subtitle, subtitle, p.outline)
        Rv.background(rv, R.id.epw_add, p.roundPrimary)
        Rv.tint(rv, R.id.epw_add_icon, p.onPrimary)
        Rv.background(rv, R.id.epw_mic, p.roundSoft)
        Rv.tint(rv, R.id.epw_mic_icon, p.primary)
        rv.setOnClickPendingIntent(R.id.epw_add, WidgetIntents.quickAdd(c, ctx.widgetId, list?.id))
        rv.setOnClickPendingIntent(R.id.epw_mic, WidgetIntents.quickAdd(c, ctx.widgetId, list?.id, voice = true))
        rv.setOnClickPendingIntent(R.id.epw_title_area, WidgetIntents.grocery(c, list?.id))
        if (wide) {
            Rv.text(rv, R.id.epw_hint, ctx.str("itemHint"), p.onSurfaceVariant)
            Rv.background(rv, R.id.epw_hint, p.inset)
            rv.setOnClickPendingIntent(R.id.epw_hint, WidgetIntents.quickAdd(c, ctx.widgetId, list?.id))
            progress(rv, ctx, list)
        }
        return rv
    }

    private fun progress(rv: RemoteViews, ctx: WidgetContext, list: WidgetList?) {
        val light = ctx.palette.look == Look.LIGHT
        rv.setViewVisibility(R.id.epw_progress_light, if (light) View.VISIBLE else View.GONE)
        rv.setViewVisibility(R.id.epw_progress_dark, if (light) View.GONE else View.VISIBLE)
        val id = if (light) R.id.epw_progress_light else R.id.epw_progress_dark
        rv.setProgressBar(id, list?.total?.coerceAtLeast(1) ?: 1, list?.checked ?: 0, false)
    }
}
