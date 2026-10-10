package com.KHEasyDev.easy_plate.widgets

import android.content.Intent
import android.net.Uri
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import com.KHEasyDev.easy_plate.R

/**
 * The list itself: a header with the name, what is left and a + for the
 * quick-add dialog, then the lines, each a tick that queues for the app.
 * Small sizes show the first few lines as text; from two rows up the
 * lines scroll (a RemoteViewsService). Ticked lines are hidden unless the
 * widget's settings say otherwise.
 */
class GroceryListWidgetProvider : EasyPlateWidgetProvider() {
    override val kind = WidgetKind.GROCERY_LIST

    override val breakpoints = listOf(
        SizeF(130f, 110f),   // header + three lines
        SizeF(250f, 110f),   // header + scrolling list
        SizeF(250f, 250f),
    )

    override fun build(ctx: WidgetContext, size: SizeF): RemoteViews {
        val p = ctx.palette
        val c = ctx.context
        val list = ctx.list
        val compact = size.width < 250f
        val rv = ctx.views(if (compact) R.layout.epw_grocery_list_compact else R.layout.epw_grocery_list)
        Rv.tint(rv, R.id.epw_icon, p.primary)
        Rv.text(rv, R.id.epw_title, list?.name ?: ctx.str("noLists"), p.onSurface)
        val count = if (list == null) "" else "${list.checked}/${list.total}"
        Rv.text(rv, R.id.epw_count, count, p.outline)
        Rv.background(rv, R.id.epw_add, p.roundPrimary)
        Rv.tint(rv, R.id.epw_add_icon, p.onPrimary)
        rv.setOnClickPendingIntent(R.id.epw_add, WidgetIntents.quickAdd(c, ctx.widgetId, list?.id))
        rv.setOnClickPendingIntent(R.id.epw_title_area, WidgetIntents.grocery(c, list?.id))
        rv.setOnClickPendingIntent(R.id.epw_root, WidgetIntents.grocery(c, list?.id))

        val visible = list?.items?.filter { ctx.config.showChecked || !it.checked } ?: emptyList()
        val empty = when {
            list == null -> ctx.str("openApp")
            list.total == 0 -> ctx.str("emptyList")
            visible.isEmpty() -> ctx.str("allDone")
            else -> null
        }
        if (compact) {
            val rows = listOf(
                Triple(R.id.epw_row1, R.id.epw_row1_icon, R.id.epw_row1_text),
                Triple(R.id.epw_row2, R.id.epw_row2_icon, R.id.epw_row2_text),
                Triple(R.id.epw_row3, R.id.epw_row3_icon, R.id.epw_row3_text),
            )
            rows.forEachIndexed { index, (row, icon, text) ->
                val item = visible.getOrNull(index)
                if (item == null) {
                    rv.setViewVisibility(row, View.GONE)
                    return@forEachIndexed
                }
                rv.setViewVisibility(row, View.VISIBLE)
                rv.setImageViewResource(icon, if (item.checked) R.drawable.epw_ic_check else R.drawable.epw_ic_circle)
                Rv.tint(rv, icon, if (item.checked) p.mint else p.outlineVariant)
                val label = if (item.qty.isEmpty()) item.name else "${item.name} · ${item.qty}"
                Rv.text(rv, text, label, if (item.checked) p.outline else p.onSurface)
            }
            val more = visible.size - rows.size
            rv.setViewVisibility(R.id.epw_more, if (more > 0) View.VISIBLE else View.GONE)
            if (more > 0) Rv.text(rv, R.id.epw_more, "+$more", p.primary)
            rv.setViewVisibility(R.id.epw_empty, if (empty != null) View.VISIBLE else View.GONE)
            if (empty != null) Rv.text(rv, R.id.epw_empty, empty, p.outline)
            return rv
        }

        // The scrolling list: the service reads the same snapshot and the
        // widget's config; the row's tap fills the toggle template in.
        val adapter = Intent(c, GroceryItemsService::class.java).apply {
            putExtra(GroceryItemsService.EXTRA_WIDGET_ID, ctx.widgetId)
            putExtra(GroceryItemsService.EXTRA_LOOK, p.look.name)
            data = Uri.parse("easyplate-widget://items/${ctx.widgetId}/${p.look.name}")
        }
        rv.setRemoteAdapter(R.id.epw_list, adapter)
        rv.setPendingIntentTemplate(R.id.epw_list, WidgetIntents.toggleTemplate(c, ctx.widgetId))
        rv.setEmptyView(R.id.epw_list, R.id.epw_empty)
        Rv.text(rv, R.id.epw_empty, empty ?: "", p.outline)
        progress(rv, ctx, list)
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
