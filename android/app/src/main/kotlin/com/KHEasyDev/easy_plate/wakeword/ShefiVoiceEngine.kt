package com.KHEasyDev.easy_plate.wakeword

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

/**
 * Where the floating panel's requests reach Shefi's Dart code
 * (`ShefiVoiceChannel` / `ShefiVoiceRunner`, the same agent and repositories
 * as the chat). Same design as the iOS ShefiVoiceBridge.swift.
 */
object ShefiVoiceEngine {
    const val CHANNEL = "easy_plate/shefi_voice"

    /** Set by MainActivity while its engine is alive. */
    var mainChannel: MethodChannel? = null
}

/**
 * One conversation of the floating panel. Its id keeps the turns together
 * on the Dart side, so a follow-up has its context. The app's own engine is
 * used when it exists (even with the app in the background), so two engines
 * never write the same Hive files at once; otherwise a headless engine runs
 * the `shefiVoiceMain` entry point in main.dart for the length of the
 * conversation and is destroyed when it ends.
 */
class ShefiVoiceSession(context: Context) {
    private val app = context.applicationContext
    private val handler = Handler(Looper.getMainLooper())
    val id: String = UUID.randomUUID().toString()
    private var channel: MethodChannel? = null
    private var headless: FlutterEngine? = null
    private var starting: MutableList<(MethodChannel?) -> Unit>? = null
    private var closed = false

    /** [onAnswer] runs once on the main thread; a null reply means none. */
    fun ask(text: String, onAnswer: (reply: String?, end: Boolean) -> Unit) {
        var done = false
        val finish = { reply: String?, end: Boolean ->
            if (!done) {
                done = true
                onAnswer(reply, end)
            }
        }
        handler.postDelayed({ finish(null, false) }, TIMEOUT_MS)
        withChannel { target ->
            if (target == null) {
                finish(null, false)
                return@withChannel
            }
            target.invokeMethod(
                "ask",
                mapOf("text" to text, "sessionId" to id),
                object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        when (result) {
                            is Map<*, *> -> finish(result["reply"] as? String, result["end"] == true)
                            is String -> finish(result, false)
                            else -> finish(null, false)
                        }
                    }
                    override fun error(code: String, message: String?, details: Any?) {
                        Log.w(TAG, "Shefi answered with an error: $code $message")
                        finish(null, false)
                    }
                    override fun notImplemented() = finish(null, false)
                },
            )
        }
    }

    fun close() {
        if (closed) return
        closed = true
        channel?.invokeMethod("end", mapOf("sessionId" to id))
        headless?.let { engine -> handler.postDelayed({ engine.destroy() }, 500) }
        headless = null
        channel = null
    }

    private fun withChannel(use: (MethodChannel?) -> Unit) {
        channel?.let { return use(it) }
        ShefiVoiceEngine.mainChannel?.let {
            channel = it
            return use(it)
        }
        starting?.let {
            it.add(use)
            return
        }
        val waiting = mutableListOf(use)
        starting = waiting
        val loader = FlutterInjector.instance().flutterLoader()
        try {
            loader.startInitialization(app)
            loader.ensureInitializationCompleteAsync(app, null, handler) {
                if (closed) return@ensureInitializationCompleteAsync
                val engine = FlutterEngine(app)
                headless = engine
                val created = MethodChannel(engine.dartExecutor.binaryMessenger, ShefiVoiceEngine.CHANNEL)
                created.setMethodCallHandler { call, result ->
                    if (call.method == "ready") {
                        channel = created
                        val queued = starting.orEmpty().toList()
                        starting = null
                        queued.forEach { it(created) }
                    }
                    result.success(null)
                }
                engine.dartExecutor.executeDartEntrypoint(
                    DartExecutor.DartEntrypoint(loader.findAppBundlePath(), "shefiVoiceMain"),
                )
            }
        } catch (e: Exception) {
            Log.w(TAG, "Headless Shefi failed to start", e)
            starting = null
            waiting.forEach { it(null) }
        }
    }

    companion object {
        private const val TAG = "ShefiVoice"
        private const val TIMEOUT_MS = 40_000L
    }
}
