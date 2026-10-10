package com.KHEasyDev.easy_plate.widgets

import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import com.KHEasyDev.easy_plate.R

/**
 * The door to Shefi from the home screen. One cell is the round gradient
 * button; two is the pill with the microphone; wider adds quick questions
 * as chips; taller stacks three. Every tap opens the copilot on the
 * question — or listening — without a stop on the home tab first.
 */
class AssistantWidgetProvider : EasyPlateWidgetProvider() {
    override val kind = WidgetKind.ASSISTANT

    /** Shefi is Premium-only in the console: a free account sees that, not a door. */
    override fun access(snapshot: WidgetSnapshot) = snapshot.assistantAccess

    override val breakpoints = listOf(
        SizeF(50f, 50f),     // round button
        SizeF(130f, 50f),    // pill + mic
        SizeF(250f, 50f),    // pill + two chips
        SizeF(250f, 130f),   // pill + mic + three chips
    )

    override fun build(ctx: WidgetContext, size: SizeF): RemoteViews {
        val p = ctx.palette
        val c = ctx.context
        val prompts = ctx.s.prompts
        return when {
            size.width < 130f -> {
                val rv = RemoteViews(c.packageName, R.layout.epw_assistant_round)
                rv.setOnClickPendingIntent(R.id.epw_root, WidgetIntents.assistant(c, ctx.voice))
                rv.setContentDescription(R.id.epw_root, ctx.str("askShefi"))
                rv
            }
            size.height < 130f && size.width < 250f -> {
                val rv = ctx.views(R.layout.epw_assistant_pill)
                // The pill alone, on the wallpaper: a card around one button
                // is a frame around a frame.
                rv.setInt(R.id.epw_root, "setBackgroundResource", 0)
                Rv.text(rv, R.id.epw_title, ctx.str("askShefi"), c.getColor(R.color.epw_light_on_primary))
                rv.setOnClickPendingIntent(R.id.epw_pill, WidgetIntents.assistant(c, ctx.voice))
                rv.setOnClickPendingIntent(R.id.epw_mic, WidgetIntents.assistant(c, voice = true))
                rv
            }
            size.height < 130f -> {
                val rv = ctx.views(R.layout.epw_assistant_bar)
                Rv.text(rv, R.id.epw_title, ctx.str("askShefi"), c.getColor(R.color.epw_light_on_primary))
                rv.setOnClickPendingIntent(R.id.epw_pill, WidgetIntents.assistant(c, ctx.voice))
                rv.setOnClickPendingIntent(R.id.epw_mic, WidgetIntents.assistant(c, voice = true))
                chips(ctx, rv, prompts, listOf(R.id.epw_chip1, R.id.epw_chip2))
                rv
            }
            else -> {
                val rv = ctx.views(R.layout.epw_assistant_panel)
                Rv.text(rv, R.id.epw_title, ctx.str("askShefi"), c.getColor(R.color.epw_light_on_primary))
                Rv.text(rv, R.id.epw_subtitle, ctx.str("tapToAsk"), p.onSurfaceVariant)
                rv.setOnClickPendingIntent(R.id.epw_pill, WidgetIntents.assistant(c, ctx.voice))
                rv.setOnClickPendingIntent(R.id.epw_mic, WidgetIntents.assistant(c, voice = true))
                Rv.background(rv, R.id.epw_mic, p.roundSoft)
                Rv.tint(rv, R.id.epw_mic_icon, p.primary)
                chips(ctx, rv, prompts, listOf(R.id.epw_chip1, R.id.epw_chip2, R.id.epw_chip3))
                rv
            }
        }
    }

    private fun chips(ctx: WidgetContext, rv: RemoteViews, prompts: List<String>, ids: List<Int>) {
        val p = ctx.palette
        ids.forEachIndexed { index, id ->
            val prompt = prompts.getOrNull(index)
            if (prompt == null) {
                rv.setViewVisibility(id, View.GONE)
                return@forEachIndexed
            }
            rv.setViewVisibility(id, View.VISIBLE)
            Rv.text(rv, id, prompt, p.onPrimaryFixed)
            Rv.background(rv, id, p.chip)
            rv.setOnClickPendingIntent(id, WidgetIntents.assistant(ctx.context, voice = false, prompt = prompt))
        }
    }
}
