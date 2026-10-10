package com.KHEasyDev.easy_plate.widgets

import android.content.Context
import android.content.res.Configuration
import android.widget.RemoteViews
import com.KHEasyDev.easy_plate.R

/** Light or dark, as this one widget resolves it. */
enum class Look { LIGHT, DARK }

/**
 * The widget's colours, picked from `easy_plate_widget_colors.xml` for the
 * look in force: the widget's own setting first (light / dark / the
 * phone's night mode), else the app's defaults, where `app` means
 * whatever the app itself is showing right now (`dark` in the snapshot).
 */
class WidgetPalette(private val context: Context, val look: Look) {
    private fun c(light: Int, dark: Int) = context.getColor(if (look == Look.LIGHT) light else dark)

    val surface get() = c(R.color.epw_light_surface, R.color.epw_dark_surface)
    val surfaceLow get() = c(R.color.epw_light_surface_low, R.color.epw_dark_surface_low)
    val onSurface get() = c(R.color.epw_light_on_surface, R.color.epw_dark_on_surface)
    val onSurfaceVariant get() = c(R.color.epw_light_on_surface_variant, R.color.epw_dark_on_surface_variant)
    val outline get() = c(R.color.epw_light_outline, R.color.epw_dark_outline)
    val outlineVariant get() = c(R.color.epw_light_outline_variant, R.color.epw_dark_outline_variant)
    val primary get() = c(R.color.epw_light_primary, R.color.epw_dark_primary)
    val onPrimary get() = c(R.color.epw_light_on_primary, R.color.epw_dark_on_primary)
    val onPrimaryFixed get() = c(R.color.epw_light_on_primary_fixed, R.color.epw_dark_on_primary_fixed)
    val mint get() = c(R.color.epw_light_mint, R.color.epw_dark_mint)
    val onSecondaryContainer get() = c(R.color.epw_light_on_secondary_container, R.color.epw_dark_on_secondary_container)

    val card get() = if (look == Look.LIGHT) R.drawable.epw_card_light else R.drawable.epw_card_dark
    val inset get() = if (look == Look.LIGHT) R.drawable.epw_inset_light else R.drawable.epw_inset_dark
    val chip get() = if (look == Look.LIGHT) R.drawable.epw_chip_light else R.drawable.epw_chip_dark
    val roundPrimary get() = if (look == Look.LIGHT) R.drawable.epw_round_primary_light else R.drawable.epw_round_primary_dark
    val roundSoft get() = if (look == Look.LIGHT) R.drawable.epw_round_soft_light else R.drawable.epw_round_soft_dark

    companion object {
        fun resolve(context: Context, config: WidgetConfig, snapshot: WidgetSnapshot?): WidgetPalette {
            val appearance = config.appearance ?: snapshot?.defaults?.appearance ?: "app"
            val night = (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
                Configuration.UI_MODE_NIGHT_YES
            val look = when (appearance) {
                "light" -> Look.LIGHT
                "dark" -> Look.DARK
                "system" -> if (night) Look.DARK else Look.LIGHT
                else -> if (snapshot?.dark ?: night) Look.DARK else Look.LIGHT
            }
            return WidgetPalette(context, look)
        }
    }
}

/** The handful of RemoteViews calls every widget makes. */
object Rv {
    fun text(rv: RemoteViews, id: Int, text: CharSequence, color: Int) {
        rv.setTextViewText(id, text)
        rv.setTextColor(id, color)
    }

    fun tint(rv: RemoteViews, id: Int, color: Int) = rv.setInt(id, "setColorFilter", color)

    fun background(rv: RemoteViews, id: Int, drawable: Int) = rv.setInt(id, "setBackgroundResource", drawable)

    fun direction(rv: RemoteViews, id: Int, rtl: Boolean) =
        rv.setInt(id, "setLayoutDirection", if (rtl) android.view.View.LAYOUT_DIRECTION_RTL else android.view.View.LAYOUT_DIRECTION_LTR)
}
