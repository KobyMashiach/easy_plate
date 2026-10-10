package com.KHEasyDev.easy_plate.widgets

import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import com.KHEasyDev.easy_plate.R

/**
 * The scrolling rows of the list widget. Each row is a tick and the
 * line; a tap fills the provider's toggle template with the list, the
 * line and the new state. A line the app has not applied yet (added from
 * the quick-add dialog a moment ago) is drawn slightly muted.
 */
class GroceryItemsService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
        GroceryItemsFactory(applicationContext, intent.getIntExtra(EXTRA_WIDGET_ID, 0))

    companion object {
        const val EXTRA_WIDGET_ID = "widgetId"
        const val EXTRA_LOOK = "look"
    }
}

private class GroceryItemsFactory(private val context: Context, private val widgetId: Int) :
    RemoteViewsService.RemoteViewsFactory {
    private var items: List<WidgetItem> = emptyList()
    private var listId: String? = null
    private lateinit var palette: WidgetPalette
    private var rtl = false

    override fun onCreate() = onDataSetChanged()

    override fun onDataSetChanged() {
        val snapshot = WidgetStore.snapshot(context)
        val config = WidgetStore.config(context, widgetId)
        palette = WidgetPalette.resolve(context, config, snapshot)
        rtl = snapshot?.rtl ?: false
        val list = snapshot?.list(config.listId)
        listId = list?.id
        val all = list?.items ?: emptyList()
        // Unticked first; ticked at the bottom when they are shown at all.
        items = if (config.showChecked) all.filter { !it.checked } + all.filter { it.checked } else all.filter { !it.checked }
    }

    override fun onDestroy() {}
    override fun getCount() = items.size
    override fun getItemId(position: Int) = items.getOrNull(position)?.id?.hashCode()?.toLong() ?: position.toLong()
    override fun hasStableIds() = true
    override fun getViewTypeCount() = 1
    override fun getLoadingView(): RemoteViews? = null

    override fun getViewAt(position: Int): RemoteViews {
        val item = items[position]
        val p = palette
        val rv = RemoteViews(context.packageName, R.layout.epw_item_row)
        Rv.direction(rv, R.id.epw_row, rtl)
        rv.setImageViewResource(R.id.epw_row_icon, if (item.checked) R.drawable.epw_ic_check else R.drawable.epw_ic_circle)
        Rv.tint(rv, R.id.epw_row_icon, if (item.checked) p.mint else p.outlineVariant)
        val ink = when {
            item.pending -> p.outline
            item.checked -> p.outline
            else -> p.onSurface
        }
        Rv.text(rv, R.id.epw_row_text, item.name, ink)
        rv.setInt(R.id.epw_row_text, "setPaintFlags", if (item.checked) STRIKE else PLAIN)
        Rv.text(rv, R.id.epw_row_qty, item.qty, p.outline)
        rv.setViewVisibility(R.id.epw_row_qty, if (item.qty.isEmpty()) View.GONE else View.VISIBLE)
        val fill = Intent().apply {
            putExtra(WidgetActionReceiver.EXTRA_LIST_ID, listId)
            putExtra(WidgetActionReceiver.EXTRA_ITEM_ID, item.id)
            putExtra(WidgetActionReceiver.EXTRA_CHECKED, !item.checked)
        }
        rv.setOnClickFillInIntent(R.id.epw_row, fill)
        return rv
    }

    companion object {
        private const val PLAIN = android.graphics.Paint.ANTI_ALIAS_FLAG
        private const val STRIKE = android.graphics.Paint.ANTI_ALIAS_FLAG or android.graphics.Paint.STRIKE_THRU_TEXT_FLAG
    }
}

/** Today's meals, one card per meal, with what is in each. */
class TodayMealsService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
        TodayMealsFactory(applicationContext, intent.getIntExtra(EXTRA_WIDGET_ID, 0))

    companion object {
        const val EXTRA_WIDGET_ID = "widgetId"
        const val EXTRA_LOOK = "look"
    }
}

private class TodayMealsFactory(private val context: Context, private val widgetId: Int) :
    RemoteViewsService.RemoteViewsFactory {
    private var meals: List<WidgetMeal> = emptyList()
    private lateinit var palette: WidgetPalette
    private var rtl = false

    override fun onCreate() = onDataSetChanged()

    override fun onDataSetChanged() {
        val snapshot = WidgetStore.snapshot(context)
        val config = WidgetStore.config(context, widgetId)
        palette = WidgetPalette.resolve(context, config, snapshot)
        rtl = snapshot?.rtl ?: false
        meals = snapshot?.plan(config.planId)?.today() ?: emptyList()
    }

    override fun onDestroy() {}
    override fun getCount() = meals.size
    override fun getItemId(position: Int) = meals.getOrNull(position)?.id?.hashCode()?.toLong() ?: position.toLong()
    override fun hasStableIds() = true
    override fun getViewTypeCount() = 1
    override fun getLoadingView(): RemoteViews? = null

    override fun getViewAt(position: Int): RemoteViews {
        val meal = meals[position]
        val p = palette
        val rv = RemoteViews(context.packageName, R.layout.epw_meal_row)
        Rv.direction(rv, R.id.epw_row, rtl)
        Rv.background(rv, R.id.epw_row, p.inset)
        Rv.text(rv, R.id.epw_meal_name, meal.name, p.primary)
        val items = meal.items.joinToString("\n") { "• ${it.label}" }
        Rv.text(rv, R.id.epw_meal_items, items, p.onSurface)
        rv.setViewVisibility(R.id.epw_meal_items, if (items.isEmpty()) View.GONE else View.VISIBLE)
        rv.setOnClickFillInIntent(R.id.epw_row, Intent())
        return rv
    }
}
