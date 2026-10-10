package com.KHEasyDev.easy_plate.widgets

import android.content.Intent
import android.net.Uri
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import com.KHEasyDev.easy_plate.R

/**
 * Today's meals from one plan — the widget's own choice, or the
 * defaults'. The day is worked out here, from the phone's clock, so the
 * widget rolls over at midnight on its own; the snapshot carries all
 * seven days. Small sizes list the meal names; larger ones scroll the
 * meals with what is in each.
 */
class TodayMenuWidgetProvider : EasyPlateWidgetProvider() {
    override val kind = WidgetKind.TODAY_MENU

    override val breakpoints = listOf(
        SizeF(130f, 110f),   // day + meal names
        SizeF(250f, 110f),   // scrolling meals with items
        SizeF(250f, 250f),
    )

    override fun build(ctx: WidgetContext, size: SizeF): RemoteViews {
        val p = ctx.palette
        val c = ctx.context
        val plan = ctx.plan
        val compact = size.width < 250f
        val rv = ctx.views(if (compact) R.layout.epw_today_menu_compact else R.layout.epw_today_menu)
        Rv.tint(rv, R.id.epw_icon, p.primary)
        Rv.text(rv, R.id.epw_title, ctx.str("todayMenu"), p.onSurface)
        Rv.text(rv, R.id.epw_day, ctx.s.todayLabel(), p.onPrimaryFixed)
        Rv.background(rv, R.id.epw_day, p.chip)
        Rv.text(rv, R.id.epw_plan_name, plan?.name ?: "", p.outline)
        rv.setViewVisibility(R.id.epw_plan_name, if (plan == null) View.GONE else View.VISIBLE)
        rv.setOnClickPendingIntent(R.id.epw_root, WidgetIntents.plan(c, plan?.id))

        val meals = plan?.today() ?: emptyList()
        val empty = when {
            plan == null -> ctx.str("noPlan")
            meals.isEmpty() -> ctx.str("noMeals")
            else -> null
        }
        if (compact) {
            val rows = listOf(R.id.epw_row1, R.id.epw_row2, R.id.epw_row3)
            rows.forEachIndexed { index, id ->
                val meal = meals.getOrNull(index)
                if (meal == null) {
                    rv.setViewVisibility(id, View.GONE)
                    return@forEachIndexed
                }
                rv.setViewVisibility(id, View.VISIBLE)
                val items = meal.items.joinToString(", ") { it.label }.ifEmpty { "" }
                val text = if (items.isEmpty()) meal.name else "${meal.name}: $items"
                Rv.text(rv, id, text, p.onSurface)
            }
            val more = meals.size - rows.size
            rv.setViewVisibility(R.id.epw_more, if (more > 0) View.VISIBLE else View.GONE)
            if (more > 0) Rv.text(rv, R.id.epw_more, "+$more", p.primary)
            rv.setViewVisibility(R.id.epw_empty, if (empty != null) View.VISIBLE else View.GONE)
            if (empty != null) Rv.text(rv, R.id.epw_empty, empty, p.outline)
            return rv
        }
        val adapter = Intent(c, TodayMealsService::class.java).apply {
            putExtra(TodayMealsService.EXTRA_WIDGET_ID, ctx.widgetId)
            putExtra(TodayMealsService.EXTRA_LOOK, p.look.name)
            data = Uri.parse("easyplate-widget://meals/${ctx.widgetId}/${p.look.name}")
        }
        rv.setRemoteAdapter(R.id.epw_list, adapter)
        rv.setPendingIntentTemplate(R.id.epw_list, WidgetIntents.plan(c, plan?.id))
        rv.setEmptyView(R.id.epw_list, R.id.epw_empty)
        Rv.text(rv, R.id.epw_empty, empty ?: "", p.outline)
        return rv
    }
}
