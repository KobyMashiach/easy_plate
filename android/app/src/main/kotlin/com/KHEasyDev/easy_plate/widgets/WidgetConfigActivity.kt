package com.KHEasyDev.easy_plate.widgets

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.view.View
import android.widget.CompoundButton
import android.widget.LinearLayout
import android.widget.Switch
import android.widget.TextView
import com.KHEasyDev.easy_plate.R

/**
 * One widget's settings, opened by the launcher when the widget is placed
 * (below Android 12; from 12 on the widget lands with the app's defaults
 * and this opens from its "reconfigure" handle): which list or plan, the
 * look (like the app / like the phone / light / dark), and — for the
 * Shefi button — whether it opens listening; for the list — whether
 * ticked lines stay in view. All labels come from the snapshot, so the
 * screen is in the app's language, not the phone's.
 */
class WidgetConfigActivity : Activity() {
    private var widgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private lateinit var kind: WidgetKind
    private var snapshot: WidgetSnapshot? = null
    private lateinit var palette: WidgetPalette
    private var config = WidgetConfig()

    override fun onCreate(savedInstanceState: Bundle?) {
        widgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
        snapshot = WidgetStore.snapshot(this)
        config = WidgetStore.config(this, widgetId)
        palette = WidgetPalette.resolve(this, config, snapshot)
        setTheme(if (palette.look == Look.DARK) R.style.EasyPlateWidgetDialogDark else R.style.EasyPlateWidgetDialog)
        super.onCreate(savedInstanceState)
        // Backing out leaves the launcher without a widget (first placement).
        setResult(RESULT_CANCELED, Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId))
        if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }
        val info = AppWidgetManager.getInstance(this).getAppWidgetInfo(widgetId)
        kind = WidgetKind.fromProvider(info?.provider?.className) ?: WidgetKind.ASSISTANT
        setContentView(R.layout.epw_config)
        window.decorView.layoutDirection = if (snapshot?.rtl == true) View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR
        render()
    }

    private fun s(key: String, fallback: Int) = snapshot?.s(key) ?: getString(fallback)

    private fun render() {
        val p = palette
        findViewById<LinearLayout>(R.id.epw_dialog_root).background = GradientDrawable().apply {
            cornerRadius = dp(28f)
            setColor(p.surface)
        }
        findViewById<TextView>(R.id.epw_config_title).apply {
            text = s("configTitle", R.string.epw_config_title)
            setTextColor(p.onSurface)
        }
        val body = findViewById<LinearLayout>(R.id.epw_config_body)
        body.removeAllViews()

        val snap = snapshot
        if (snap != null && snap.signedIn) {
            if (kind == WidgetKind.GROCERY_ADD || kind == WidgetKind.GROCERY_LIST) {
                section(body, s("listLabel", R.string.epw_list))
                val options = snap.lists.map { it.id to it.name }
                if (options.isEmpty()) note(body, snap.s("noLists")) else chips(body, options, config.listId ?: snap.list(null)?.id) {
                    config = config.copy(listId = it)
                    render()
                }
            }
            if (kind == WidgetKind.TODAY_MENU) {
                section(body, s("planLabel", R.string.epw_plan))
                val options = snap.plans.map { it.id to it.name }
                if (options.isEmpty()) note(body, snap.s("noPlan")) else chips(body, options, config.planId ?: snap.plan(null)?.id) {
                    config = config.copy(planId = it)
                    render()
                }
            }
        }

        section(body, s("appearance", R.string.epw_appearance))
        chips(
            body,
            listOf(
                "app" to s("followApp", R.string.epw_follow_app),
                "system" to s("system", R.string.epw_system),
                "light" to s("light", R.string.epw_light),
                "dark" to s("dark", R.string.epw_dark),
            ),
            config.appearance ?: snap?.defaults?.appearance ?: "app",
        ) {
            config = config.copy(appearance = it)
            palette = WidgetPalette.resolve(this, config, snapshot)
            render()
        }

        if (kind == WidgetKind.ASSISTANT) {
            toggle(body, s("voiceOpen", R.string.epw_voice_open), config.voice ?: snap?.defaults?.voice ?: false) {
                config = config.copy(voice = it)
            }
        }
        if (kind == WidgetKind.GROCERY_LIST) {
            toggle(body, s("showChecked", R.string.epw_show_checked), config.showChecked) {
                config = config.copy(showChecked = it)
            }
        }

        findViewById<TextView>(R.id.epw_config_save).apply {
            text = s("save", R.string.epw_save)
            setTextColor(p.onPrimary)
            background = GradientDrawable().apply { cornerRadius = dp(999f); setColor(p.primary) }
            setOnClickListener { save() }
        }
        findViewById<TextView>(R.id.epw_config_cancel).apply {
            text = s("cancel", R.string.epw_cancel)
            setTextColor(p.outline)
            setOnClickListener { finish() }
        }
    }

    private fun save() {
        WidgetStore.writeConfig(this, widgetId, config)
        val manager = AppWidgetManager.getInstance(this)
        val provider = manager.getAppWidgetInfo(widgetId)?.provider
        if (provider != null) {
            sendBroadcast(Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE).apply {
                component = provider
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(widgetId))
            })
            manager.notifyAppWidgetViewDataChanged(widgetId, R.id.epw_list)
        }
        setResult(RESULT_OK, Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId))
        finish()
    }

    // ---- Pieces --------------------------------------------------------

    private fun section(parent: LinearLayout, title: String) {
        parent.addView(TextView(this).apply {
            text = title
            textSize = 13f
            setTextColor(palette.onSurfaceVariant)
            setPadding(0, dp(14f).toInt(), 0, dp(6f).toInt())
        })
    }

    private fun note(parent: LinearLayout, text: String) {
        parent.addView(TextView(this).apply {
            this.text = text
            textSize = 14f
            setTextColor(palette.outline)
        })
    }

    private fun chips(parent: LinearLayout, options: List<Pair<String, String>>, selected: String?, onPick: (String) -> Unit) {
        // Wrapped by hand: rows of chips, a new row when one would overflow.
        val maxWidth = resources.displayMetrics.widthPixels - dp(96f)
        var row = newRow(parent)
        var used = 0f
        for ((id, label) in options) {
            val chip = chip(label, id == selected) { onPick(id) }
            chip.measure(View.MeasureSpec.UNSPECIFIED, View.MeasureSpec.UNSPECIFIED)
            val width = chip.measuredWidth + dp(8f)
            if (used + width > maxWidth && used > 0f) {
                row = newRow(parent)
                used = 0f
            }
            val params = LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT)
            params.marginEnd = dp(8f).toInt()
            params.bottomMargin = dp(8f).toInt()
            row.addView(chip, params)
            used += width
        }
    }

    private fun newRow(parent: LinearLayout) = LinearLayout(this).apply {
        orientation = LinearLayout.HORIZONTAL
        parent.addView(this, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))
    }

    private fun chip(label: String, selected: Boolean, onClick: () -> Unit) = TextView(this).apply {
        text = label
        textSize = 14f
        maxLines = 1
        setPadding(dp(16f).toInt(), dp(9f).toInt(), dp(16f).toInt(), dp(9f).toInt())
        setTextColor(if (selected) palette.onPrimary else palette.onSurface)
        background = GradientDrawable().apply {
            cornerRadius = dp(999f)
            setColor(if (selected) palette.primary else palette.surfaceLow)
            if (!selected) setStroke(dp(1f).toInt(), palette.outlineVariant)
        }
        setOnClickListener { onClick() }
    }

    private fun toggle(parent: LinearLayout, label: String, value: Boolean, onChange: (Boolean) -> Unit) {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(0, dp(12f).toInt(), 0, 0)
        }
        row.addView(TextView(this).apply {
            text = label
            textSize = 15f
            setTextColor(palette.onSurface)
        }, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f).apply { gravity = android.view.Gravity.CENTER_VERTICAL })
        @Suppress("UseSwitchCompatOrMaterialCode")
        val switch = Switch(this).apply {
            isChecked = value
            setOnCheckedChangeListener { _: CompoundButton, checked: Boolean -> onChange(checked) }
        }
        row.addView(switch)
        parent.addView(row)
    }

    private fun dp(value: Float) = value * resources.displayMetrics.density

    companion object {
        const val EXTRA_RECONFIGURE = "reconfigure"
    }
}
