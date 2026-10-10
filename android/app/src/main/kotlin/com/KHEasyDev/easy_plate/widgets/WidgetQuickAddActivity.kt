package com.KHEasyDev.easy_plate.widgets

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.speech.RecognizerIntent
import android.view.View
import android.view.WindowManager
import android.view.inputmethod.EditorInfo
import android.widget.EditText
import android.widget.ImageButton
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import com.KHEasyDev.easy_plate.R

/**
 * The quick-add dialog a widget opens on the home screen: one field with
 * the keyboard up, the account's lists as chips (the widget's list
 * preselected), a microphone that dictates into the field through the
 * phone's recognizer, and Add. The line is queued for the app and shown
 * on the widgets at once; the app applies it when it runs — right away
 * if it is alive. Nothing of the app itself has to start for this.
 */
class WidgetQuickAddActivity : Activity() {
    private var listId: String? = null
    private lateinit var snapshot: WidgetSnapshot
    private lateinit var palette: WidgetPalette
    private lateinit var field: EditText

    override fun onCreate(savedInstanceState: Bundle?) {
        val widgetId = intent.getIntExtra(EXTRA_WIDGET_ID, 0)
        val loaded = WidgetStore.snapshot(this)
        val config = WidgetStore.config(this, widgetId)
        palette = WidgetPalette.resolve(this, config, loaded)
        setTheme(if (palette.look == Look.DARK) R.style.EasyPlateWidgetDialogDark else R.style.EasyPlateWidgetDialog)
        super.onCreate(savedInstanceState)
        if (loaded == null || !loaded.enabled) {
            // Nothing to add to: the app will say why.
            startActivity(Intent(Intent.ACTION_VIEW, android.net.Uri.parse("easyplate://open/widget/settings")))
            finish()
            return
        }
        snapshot = loaded
        listId = intent.getStringExtra(EXTRA_LIST_ID) ?: snapshot.list(config.listId)?.id

        setContentView(R.layout.epw_quick_add)
        window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_STATE_ALWAYS_VISIBLE)
        window.decorView.layoutDirection = if (snapshot.rtl) View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR

        val root = findViewById<LinearLayout>(R.id.epw_dialog_root)
        root.background = GradientDrawable().apply {
            cornerRadius = dp(28f)
            setColor(palette.surface)
            setStroke(dp(1f).toInt(), palette.primary and 0x33FFFFFF)
        }
        findViewById<TextView>(R.id.epw_dialog_title).apply {
            text = snapshot.s("quickAdd")
            setTextColor(palette.onSurface)
        }
        field = findViewById(R.id.epw_dialog_field)
        field.hint = snapshot.s("itemHint")
        field.setTextColor(palette.onSurface)
        field.setHintTextColor(palette.outline)
        field.background = GradientDrawable().apply {
            cornerRadius = dp(18f)
            setColor(palette.surfaceLow)
        }
        field.setOnEditorActionListener { _, actionId, _ ->
            if (actionId == EditorInfo.IME_ACTION_DONE) { submit(); true } else false
        }
        field.requestFocus()

        val mic = findViewById<ImageButton>(R.id.epw_dialog_mic)
        mic.background = GradientDrawable().apply { shape = GradientDrawable.OVAL; setColor(palette.primary and 0x22FFFFFF or (palette.primary and 0x00FFFFFF)) }
        mic.setColorFilter(palette.primary)
        mic.contentDescription = snapshot.s("speak")
        mic.setOnClickListener { dictate() }

        val add = findViewById<TextView>(R.id.epw_dialog_add)
        add.text = snapshot.s("add")
        add.setTextColor(palette.onPrimary)
        add.background = GradientDrawable().apply { cornerRadius = dp(999f); setColor(palette.primary) }
        add.setOnClickListener { submit() }

        val cancel = findViewById<TextView>(R.id.epw_dialog_cancel)
        cancel.text = snapshot.s("cancel")
        cancel.setTextColor(palette.outline)
        cancel.setOnClickListener { finish() }

        buildChips()
        if (intent.getBooleanExtra(EXTRA_VOICE, false)) dictate()
    }

    /** The lists as pills; the chosen one filled. One list needs no row. */
    private fun buildChips() {
        val row = findViewById<LinearLayout>(R.id.epw_dialog_lists)
        val lists = snapshot.lists
        if (lists.size <= 1) {
            row.visibility = View.GONE
            return
        }
        row.removeAllViews()
        for (list in lists) {
            val chip = TextView(this).apply {
                text = list.name
                textSize = 13f
                maxLines = 1
                setPadding(dp(14f).toInt(), dp(8f).toInt(), dp(14f).toInt(), dp(8f).toInt())
                setOnClickListener {
                    listId = list.id
                    buildChips()
                }
            }
            val selected = list.id == listId
            chip.setTextColor(if (selected) palette.onPrimary else palette.onSurface)
            chip.background = GradientDrawable().apply {
                cornerRadius = dp(999f)
                setColor(if (selected) palette.primary else palette.surfaceLow)
                if (!selected) setStroke(dp(1f).toInt(), palette.outlineVariant)
            }
            val params = LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT)
            params.marginEnd = dp(8f).toInt()
            row.addView(chip, params)
        }
    }

    private fun dictate() {
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, snapshot.lang)
            putExtra(RecognizerIntent.EXTRA_PROMPT, snapshot.s("itemHint"))
        }
        try {
            @Suppress("DEPRECATION")
            startActivityForResult(intent, REQUEST_SPEECH)
        } catch (e: Exception) {
            Toast.makeText(this, snapshot.s("speak"), Toast.LENGTH_SHORT).show()
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != REQUEST_SPEECH || resultCode != RESULT_OK) return
        val heard = data?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)?.firstOrNull() ?: return
        field.setText(heard)
        field.setSelection(heard.length)
    }

    /** Several lines at once: "milk, bread, eggs" is three. */
    private fun submit() {
        val text = field.text?.toString()?.trim().orEmpty()
        if (text.isEmpty()) return
        val names = text.split(',', '،', '\n').map { it.trim() }.filter { it.isNotEmpty() }
        for (name in names) WidgetStore.enqueue(this, PendingAction.add(listId, name))
        WidgetUpdater.refreshAll(this)
        HomeWidgetsChannel.nudge()
        finish()
    }

    private fun dp(value: Float) = value * resources.displayMetrics.density

    companion object {
        const val EXTRA_WIDGET_ID = "widgetId"
        const val EXTRA_LIST_ID = "listId"
        const val EXTRA_VOICE = "voice"
        private const val REQUEST_SPEECH = 41
    }
}
