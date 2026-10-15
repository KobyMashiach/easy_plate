package com.KHEasyDev.easy_plate.wakeword

import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.Outline
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.text.InputType
import android.util.Log
import android.util.TypedValue
import android.view.Gravity
import android.view.KeyEvent
import android.view.MotionEvent
import android.view.View
import android.view.ViewOutlineProvider
import android.view.WindowManager
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import com.KHEasyDev.easy_plate.R
import java.util.Locale

/**
 * "Hey Shefi" heard while Easy Plate is not on screen: a floating panel at
 * the bottom of the screen, in the manner of Gemini's, over whatever app is
 * open. It holds a whole conversation: what the user says (or types) and
 * what Shefi answers stack up as bubbles, each answer is read aloud, and the
 * microphone opens again after it, until the conversation ends: the user
 * says goodbye ("סיום שיחה", or "no" after "anything else?"), taps ✕, or
 * leaves it untouched for a minute. A tap on the header opens the full chat.
 *
 * The window does not take focus (so the app underneath keeps working)
 * until the text field is tapped; then it does, for the keyboard, and gives
 * it back after sending. Samsung stops animations for a background app, so
 * nothing here relies on one. Needs "display over other apps".
 */
class ShefiOverlay(
    context: Context,
    private val onClosed: () -> Unit,
    /**
     * A transparent activity to draw the panel in, instead of a window over
     * other apps: the Gemini route (EntryActivity). The panel then needs no
     * "display over other apps", the microphone is the foreground app's,
     * and a tap outside the card closes it and returns to where the user
     * was.
     */
    private val host: android.app.Activity? = null,
) {
    private val ctx = context.applicationContext
    private val handler = Handler(Looper.getMainLooper())
    private val windows = ctx.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private val session = ShefiVoiceSession(ctx)

    private var root: View? = null
    private lateinit var params: WindowManager.LayoutParams
    private lateinit var status: TextView
    private lateinit var messages: LinearLayout
    private lateinit var scroll: ScrollView
    private lateinit var input: EditText
    private lateinit var micButton: FrameLayout
    private var liveBubble: TextView? = null

    private var recognizer: SpeechRecognizer? = null
    private var tts: TextToSpeech? = null
    private var ttsReady = false
    private var pendingSpeech: String? = null
    private var closed = false
    private var busy = false
    private var listening = false
    private var heard = ""

    private val locale = WakeWordController.locale
    private val rtl = locale.startsWith("he") || locale.startsWith("ar")
    private val dark =
        (ctx.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
            Configuration.UI_MODE_NIGHT_YES

    private val surface get() = color(R.color.epw_light_surface, R.color.epw_dark_surface)
    private val surfaceLow get() = color(R.color.epw_light_surface_container, R.color.epw_dark_surface_container)
    private val onSurface get() = color(R.color.epw_light_on_surface, R.color.epw_dark_on_surface)
    private val muted get() = color(R.color.epw_light_on_surface_variant, R.color.epw_dark_on_surface_variant)
    private val primary get() = ctx.getColor(R.color.epw_light_primary)

    private fun text(key: String, fallback: String) = WakeWordController.text(key, fallback)

    private val idleClose = Runnable { close() }

    /** Shows the panel; [command] is what came with the wake words, if anything. */
    fun start(command: String) {
        show()
        prepareTts()
        if (command.isNotBlank()) submit(command) else listen()
    }

    fun close() {
        if (closed) return
        closed = true
        handler.removeCallbacksAndMessages(null)
        stopListening()
        tts?.let {
            it.stop()
            it.shutdown()
        }
        tts = null
        session.close()
        root?.let { view ->
            hideKeyboard(view)
            if (host == null) {
                try {
                    windows.removeView(view)
                } catch (_: Exception) {
                }
            }
        }
        root = null
        onClosed()
        host?.let {
            if (!it.isFinishing) {
                it.finish()
                @Suppress("DEPRECATION")
                it.overridePendingTransition(0, 0)
            }
        }
    }

    // ---- conversation ----------------------------------------------------

    private fun touch() {
        handler.removeCallbacks(idleClose)
        handler.postDelayed(idleClose, IDLE_MS)
    }

    private fun listen() {
        if (closed || busy) return
        stopSpeaking()
        stopListening()
        touch()
        heard = ""
        listening = true
        setMic(active = true)
        setStatus(text("overlayListening", "Shefi is listening…"))
        val current = try {
            SpeechRecognizer.createSpeechRecognizer(ctx)
        } catch (e: Exception) {
            idle()
            return
        }
        recognizer = current
        current.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {}
            override fun onBeginningOfSpeech() {}
            override fun onRmsChanged(rmsdB: Float) {}
            override fun onBufferReceived(buffer: ByteArray?) {}
            override fun onEndOfSpeech() {}
            override fun onEvent(eventType: Int, params: Bundle?) {}

            override fun onPartialResults(partialResults: Bundle?) {
                best(partialResults)?.let {
                    heard = it
                    live().text = it
                    scrollDown()
                }
            }

            override fun onResults(results: Bundle?) {
                val said = best(results) ?: heard
                listening = false
                if (said.isBlank()) idle() else submit(said)
            }

            override fun onError(error: Int) {
                listening = false
                if (heard.isNotBlank()) submit(heard) else idle()
            }
        })
        current.startListening(
            Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                // Like the chat's recognizer: no tag when the phone already
                // speaks the language (some recognizers refuse "he-IL").
                if (!sameAsDevice()) putExtra(RecognizerIntent.EXTRA_LANGUAGE, locale)
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                putExtra(RecognizerIntent.EXTRA_CALLING_PACKAGE, ctx.packageName)
            },
        )
    }

    /** Nothing heard: wait for a tap on the mic or for typing. */
    private fun idle() {
        stopListening()
        liveBubble?.let { if (it.text.isNullOrBlank()) messages.removeView(it) }
        liveBubble = null
        setMic(active = false)
        setStatus(text("overlayTapToTalk", "Tap the mic or type"))
        touch()
    }

    private fun submit(said: String) {
        val request = said.trim()
        if (closed || request.isEmpty()) return
        stopListening()
        stopSpeaking()
        touch()
        busy = true
        setMic(active = false)
        live().text = request
        liveBubble = null
        scrollDown()
        setStatus(text("overlayThinking", "Shefi is thinking…"))
        session.ask(request) { reply, end ->
            if (closed) return@ask
            busy = false
            touch()
            val answer = reply?.takeIf { it.isNotBlank() }
                ?: text("overlayFailed", "Shefi couldn't answer right now.")
            addBubble(answer, mine = false)
            setStatus(text("overlayAnswer", "Shefi"))
            speak(answer) {
                if (closed) return@speak
                if (end) handler.postDelayed({ close() }, 1_500)
                else if (reply != null && !input.hasFocus()) listen()
                else idle()
            }
        }
    }

    // ---- voice -----------------------------------------------------------

    private fun prepareTts() {
        tts = TextToSpeech(ctx) { status ->
            val engine = tts ?: return@TextToSpeech
            if (status == TextToSpeech.SUCCESS) {
                engine.language = Locale.forLanguageTag(locale)
                ttsReady = true
            }
            pendingSpeech?.let { handler.post { speakNow(it) } }
        }
    }

    private var afterSpeech: (() -> Unit)? = null

    private fun speak(reply: String, then: () -> Unit) {
        afterSpeech = then
        if (!ttsReady) {
            // Not up yet (or no engine): read it once it is, or carry on.
            if (tts == null) return finishSpeech()
            pendingSpeech = reply
            handler.postDelayed({ if (pendingSpeech != null) { pendingSpeech = null; finishSpeech() } }, 4_000)
            return
        }
        speakNow(reply)
    }

    private fun speakNow(reply: String) {
        pendingSpeech = null
        val engine = tts
        if (engine == null || !ttsReady) return finishSpeech()
        engine.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
            override fun onStart(utteranceId: String?) {}
            override fun onDone(utteranceId: String?) { handler.post { finishSpeech() } }
            @Deprecated("Deprecated in Java")
            override fun onError(utteranceId: String?) { handler.post { finishSpeech() } }
        })
        engine.speak(reply, TextToSpeech.QUEUE_FLUSH, null, "shefi")
    }

    private fun finishSpeech() {
        val next = afterSpeech
        afterSpeech = null
        next?.invoke()
    }

    private fun stopSpeaking() {
        afterSpeech = null
        pendingSpeech = null
        tts?.stop()
    }

    private fun stopListening() {
        listening = false
        recognizer?.let {
            try {
                it.cancel()
                it.destroy()
            } catch (_: Exception) {
            }
        }
        recognizer = null
    }

    private fun best(results: Bundle?): String? =
        results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()
            ?.trim()?.takeIf { it.isNotEmpty() }

    private fun sameAsDevice(): Boolean {
        fun base(tag: String) = tag.substringBefore('-').substringBefore('_')
            .lowercase().let { if (it == "iw") "he" else it }
        return base(Locale.getDefault().language) == base(locale)
    }

    // ---- typing ----------------------------------------------------------

    /**
     * The window takes focus only while the user types. Then it also spans
     * the whole screen, so the keyboard's inset can lift the card above it
     * (an overlay is not resized for the keyboard on its own).
     */
    private fun setFocusable(focusable: Boolean) {
        // An activity's window takes focus and the keyboard by itself.
        if (host != null) return
        val view = root ?: return
        params.height = if (focusable) {
            WindowManager.LayoutParams.MATCH_PARENT
        } else {
            WindowManager.LayoutParams.WRAP_CONTENT
        }
        params.flags = if (focusable) {
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
        } else {
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
        }
        try {
            windows.updateViewLayout(view, params)
        } catch (_: Exception) {
        }
    }

    private fun startTyping() {
        stopListening()
        stopSpeaking()
        liveBubble?.let { if (it.text.isNullOrBlank()) messages.removeView(it) }
        liveBubble = null
        setMic(active = false)
        setStatus(text("overlayAnswer", "Shefi"))
        touch()
        setFocusable(true)
        input.requestFocus()
        handler.postDelayed({
            (ctx.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager)
                .showSoftInput(input, InputMethodManager.SHOW_IMPLICIT)
        }, 120)
    }

    private fun sendTyped() {
        val typed = input.text?.toString().orEmpty().trim()
        if (typed.isEmpty() || busy) return
        input.setText("")
        input.clearFocus()
        root?.let { hideKeyboard(it) }
        setFocusable(false)
        submit(typed)
    }

    private fun hideKeyboard(view: View) {
        (ctx.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager)
            .hideSoftInputFromWindow(view.windowToken, 0)
    }

    // ---- view ------------------------------------------------------------

    private fun dp(value: Float) =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value, ctx.resources.displayMetrics)

    private fun color(light: Int, darkId: Int) = ctx.getColor(if (dark) darkId else light)

    private fun setStatus(value: String) {
        status.text = value
    }

    private fun setMic(active: Boolean) {
        (micButton.background as? GradientDrawable)?.setColor(if (active) primary else surfaceLow)
        (micButton.getChildAt(0) as? ImageView)?.setColorFilter(if (active) Color.WHITE else primary)
    }

    /** The bubble the user's words go into while they speak. */
    private fun live(): TextView = liveBubble ?: addBubble("", mine = true).also { liveBubble = it }

    private fun addBubble(value: String, mine: Boolean): TextView {
        val bubble = TextView(ctx).apply {
            text = value
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            setTextColor(if (mine) Color.WHITE else onSurface)
            textDirection = View.TEXT_DIRECTION_FIRST_STRONG
            gravity = if (rtl) Gravity.RIGHT else Gravity.LEFT
            setLineSpacing(0f, 1.12f)
            val h = dp(14f).toInt()
            val v = dp(9f).toInt()
            setPadding(h, v, h, v)
            background = GradientDrawable().apply {
                cornerRadius = dp(18f)
                setColor(if (mine) primary else surfaceLow)
            }
        }
        // Like the chat: Shefi on the reading start side, the user opposite.
        val shefiSide = if (rtl) Gravity.RIGHT else Gravity.LEFT
        val userSide = if (rtl) Gravity.LEFT else Gravity.RIGHT
        messages.addView(
            bubble,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT,
            ).apply {
                gravity = if (mine) userSide else shefiSide
                topMargin = dp(8f).toInt()
                if (mine) {
                    if (rtl) rightMargin = dp(40f).toInt() else leftMargin = dp(40f).toInt()
                } else {
                    if (rtl) leftMargin = dp(24f).toInt() else rightMargin = dp(24f).toInt()
                }
            },
        )
        scrollDown()
        return bubble
    }

    private fun scrollDown() {
        scroll.post { scroll.fullScroll(View.FOCUS_DOWN) }
    }

    private fun circleButton(fill: Int, icon: Int, tint: Int, size: Float): FrameLayout =
        FrameLayout(ctx).apply {
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(fill)
            }
            addView(
                ImageView(ctx).apply {
                    setImageResource(icon)
                    setColorFilter(tint)
                },
                FrameLayout.LayoutParams(dp(size * 0.5f).toInt(), dp(size * 0.5f).toInt(), Gravity.CENTER),
            )
        }

    private fun show() {
        val card = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            val pad = dp(16f).toInt()
            setPadding(pad, pad, pad, pad)
            background = GradientDrawable().apply {
                cornerRadius = dp(28f)
                setColor(surface)
                setStroke(dp(1.5f).toInt(), primary and 0x55FFFFFF)
            }
            elevation = dp(12f)
        }

        // Header: the app's icon, the status, ✕. The manifest declares no
        // RTL support for native views (the UI is Flutter's), so rows are
        // ordered by hand.
        val header = LinearLayout(ctx).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setOnClickListener { openChat() }
        }
        val badge = ImageView(ctx).apply {
            setImageResource(R.mipmap.ic_launcher)
            scaleType = ImageView.ScaleType.CENTER_CROP
            outlineProvider = object : ViewOutlineProvider() {
                override fun getOutline(view: View, outline: Outline) {
                    outline.setRoundRect(0, 0, view.width, view.height, view.width * 0.28f)
                }
            }
            clipToOutline = true
        }
        status = TextView(ctx).apply {
            setTextColor(onSurface)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            typeface = Typeface.DEFAULT_BOLD
            gravity = if (rtl) Gravity.RIGHT else Gravity.LEFT
        }
        val closeButton = TextView(ctx).apply {
            text = "✕"
            setTextColor(muted)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
            val pad = dp(8f).toInt()
            setPadding(pad, pad, pad, pad)
            setOnClickListener { close() }
        }
        val gap = dp(12f).toInt()
        val statusParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        val badgeParams = LinearLayout.LayoutParams(dp(36f).toInt(), dp(36f).toInt())
        if (rtl) {
            statusParams.rightMargin = gap
            header.addView(closeButton)
            header.addView(status, statusParams)
            header.addView(badge, badgeParams)
        } else {
            statusParams.leftMargin = gap
            header.addView(badge, badgeParams)
            header.addView(status, statusParams)
            header.addView(closeButton)
        }
        card.addView(header)

        // The conversation, capped at a little under half the screen.
        messages = LinearLayout(ctx).apply { orientation = LinearLayout.VERTICAL }
        scroll = object : ScrollView(ctx) {
            private val cap = (ctx.resources.displayMetrics.heightPixels * 0.42f).toInt()
            override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
                super.onMeasure(
                    widthMeasureSpec,
                    View.MeasureSpec.makeMeasureSpec(cap, View.MeasureSpec.AT_MOST),
                )
            }
        }.apply {
            isVerticalScrollBarEnabled = false
            addView(messages)
        }
        card.addView(
            scroll,
            LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
                .apply { topMargin = dp(4f).toInt() },
        )

        // Input row: mic, text field, send.
        val row = LinearLayout(ctx).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }
        micButton = circleButton(surfaceLow, R.drawable.ic_stat_shefi, primary, 44f).apply {
            setOnClickListener {
                if (listening) idle() else {
                    input.clearFocus()
                    root?.let { hideKeyboard(it) }
                    setFocusable(false)
                    listen()
                }
            }
        }
        input = EditText(ctx).apply {
            hint = text("overlayHint", "Write to Shefi…")
            setHintTextColor(muted)
            setTextColor(onSurface)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
            textDirection = View.TEXT_DIRECTION_FIRST_STRONG
            gravity = (if (rtl) Gravity.RIGHT else Gravity.LEFT) or Gravity.CENTER_VERTICAL
            inputType = InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_CAP_SENTENCES
            imeOptions = EditorInfo.IME_ACTION_SEND
            maxLines = 3
            val h = dp(16f).toInt()
            setPadding(h, dp(10f).toInt(), h, dp(10f).toInt())
            background = GradientDrawable().apply {
                cornerRadius = dp(22f)
                setColor(surfaceLow)
            }
            setOnTouchListener { _, event ->
                if (event.action == MotionEvent.ACTION_UP && !hasFocus()) startTyping()
                false
            }
            setOnEditorActionListener { _, action, _ ->
                if (action == EditorInfo.IME_ACTION_SEND) {
                    sendTyped()
                    true
                } else {
                    false
                }
            }
        }
        val send = circleButton(primary, R.drawable.epw_ic_add, Color.WHITE, 44f).apply {
            // A plain arrow, pointing the way the text runs.
            removeAllViews()
            addView(
                TextView(ctx).apply {
                    text = if (rtl) "➤" else "➤"
                    scaleX = if (rtl) -1f else 1f
                    setTextColor(Color.WHITE)
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
                    gravity = Gravity.CENTER
                },
                FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT),
            )
            setOnClickListener { sendTyped() }
        }
        val button = dp(44f).toInt()
        val fieldParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f).apply {
            leftMargin = dp(8f).toInt()
            rightMargin = dp(8f).toInt()
        }
        if (rtl) {
            row.addView(send, LinearLayout.LayoutParams(button, button))
            row.addView(input, fieldParams)
            row.addView(micButton, LinearLayout.LayoutParams(button, button))
        } else {
            row.addView(micButton, LinearLayout.LayoutParams(button, button))
            row.addView(input, fieldParams)
            row.addView(send, LinearLayout.LayoutParams(button, button))
        }
        card.addView(
            row,
            LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
                .apply { topMargin = dp(12f).toInt() },
        )

        val frame = object : FrameLayout(ctx) {
            // Back while typing closes the keyboard and hands focus back.
            override fun dispatchKeyEvent(event: KeyEvent): Boolean {
                if (event.keyCode == KeyEvent.KEYCODE_BACK && event.action == KeyEvent.ACTION_UP) {
                    // In its own screen, back with no keyboard up ends it.
                    if (host != null && !input.hasFocus()) {
                        close()
                        return true
                    }
                    input.clearFocus()
                    hideKeyboard(this)
                    setFocusable(false)
                    return true
                }
                return super.dispatchKeyEvent(event)
            }
        }.apply {
            val side = dp(12f).toInt()
            val bottom = dp(20f).toInt()
            setPadding(side, 0, side, bottom)
            addView(
                card,
                FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.WRAP_CONTENT,
                    Gravity.BOTTOM,
                ),
            )
            // The keyboard's height, as bottom padding: the card sits on it.
            setOnApplyWindowInsetsListener { view, insets ->
                val ime = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    insets.getInsets(android.view.WindowInsets.Type.ime()).bottom
                } else {
                    @Suppress("DEPRECATION") insets.systemWindowInsetBottom
                }
                view.setPadding(side, 0, side, maxOf(bottom, ime + dp(8f).toInt()))
                insets
            }
        }

        host?.let { activity ->
            // A light dim, only now that the panel is up (the entry theme
            // has none, so an ordinary launch never flashes grey).
            activity.window.addFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND)
            activity.window.setDimAmount(0.25f)
            // The whole screen is the host's; a tap beside the card closes it.
            frame.isClickable = true
            frame.setOnClickListener { close() }
            card.isClickable = true
            activity.setContentView(
                frame,
                android.view.ViewGroup.LayoutParams(
                    android.view.ViewGroup.LayoutParams.MATCH_PARENT,
                    android.view.ViewGroup.LayoutParams.MATCH_PARENT,
                ),
            )
            root = frame
            return
        }

        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }
        params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.BOTTOM
            // The keyboard pushes the panel up rather than covering it.
            softInputMode = WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE
        }

        try {
            windows.addView(frame, params)
        } catch (e: Exception) {
            Log.w("ShefiOverlay", "Overlay refused", e)
            closed = true
            session.close()
            onClosed()
            return
        }
        root = frame
    }

    /** The header tapped: the full conversation, in the app. */
    private fun openChat() {
        val uri = Uri.Builder().scheme("easyplate").authority("open")
            .path("/widget/assistant")
            .appendQueryParameter("source", "wake")
            .build()
        try {
            ctx.startActivity(
                Intent(Intent.ACTION_VIEW, uri).setPackage(ctx.packageName)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
            )
        } catch (_: Exception) {
        }
        close()
    }

    companion object {
        /** Untouched this long, the conversation ends by itself. */
        private const val IDLE_MS = 60_000L
    }
}
