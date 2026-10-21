package com.KHEasyDev.easy_plate.widgets

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import com.KHEasyDev.easy_plate.EntryActivity
import com.KHEasyDev.easy_plate.MainActivity

/**
 * Where a tap goes. Every tap into the app is a deep link on the app's
 * own scheme — `easyplate://open/widget/<action>?…` — which Flutter hands to
 * the router like any other link (see `HomeWidgetLaunch` on the Dart
 * side). Taps that stay on the home screen (a tick, the quick-add dialog)
 * go to native screens of their own.
 */
object WidgetIntents {
    private const val SCHEME = "easyplate://open/widget/"

    /**
     * EntryActivity and MainActivity are exported, so any installed app can
     * start them with `prompt` (an extra, or `?prompt=` on the widget link)
     * and have Shefi act on the user's account. Only intents this app built
     * itself carry [EXTRA_TRUST] with this per-install random token (kept in
     * private prefs, so no other app can read it); a prompt without it is
     * dropped and the panel / chat just opens.
     */
    const val EXTRA_TRUST = "com.KHEasyDev.easy_plate.TRUST"
    private const val TRUST_PREFS = "easy_plate_intent_trust"
    private const val TRUST_KEY = "token"

    /** What only the app's own intents may carry on a link. */
    private val UNTRUSTED_PARAMS = setOf("prompt", "voice")

    @Synchronized
    fun trustToken(context: Context): String {
        val prefs = context.applicationContext.getSharedPreferences(TRUST_PREFS, Context.MODE_PRIVATE)
        prefs.getString(TRUST_KEY, null)?.let { return it }
        val token = java.util.UUID.randomUUID().toString()
        prefs.edit().putString(TRUST_KEY, token).apply()
        return token
    }

    fun isTrusted(context: Context, intent: Intent?): Boolean {
        val given = try {
            intent?.getStringExtra(EXTRA_TRUST)
        } catch (_: Exception) {
            null // a malformed extras bundle from another app
        } ?: return false
        return given == trustToken(context)
    }

    /**
     * Drops `prompt` from an untrusted intent's link. Any link, not only
     * `easyplate://open/widget/…`: MainActivity is exported, so an explicit
     * intent skips the manifest's scheme/host filters, and Flutter's route
     * is the link's path + query alone (scheme and host are thrown away) —
     * `EASYPLATE://x/widget/assistant?prompt=…` or `easyplate://widget/…`
     * reached Dart's widget launch with the prompt intact. `voice` goes
     * too: `voice=1` opens Shefi listening, the microphone on, for any app
     * that asks. The app's own voice doors (the "שפי" icon, the Gemini
     * route, the wake word) mark their intents with the token. No other
     * link the app takes uses either name.
     */
    fun stripUntrustedPrompt(context: Context, intent: Intent?) {
        val uri = intent?.data ?: return
        if (uri.isOpaque) return // no query Flutter would read
        val names = try { uri.queryParameterNames } catch (_: Exception) { return }
        if (names.none { it in UNTRUSTED_PARAMS } || isTrusted(context, intent)) return
        val clean = uri.buildUpon().clearQuery()
        for (name in names) {
            if (name in UNTRUSTED_PARAMS) continue
            for (value in uri.getQueryParameters(name)) clean.appendQueryParameter(name, value)
        }
        intent.data = clean.build()
    }

    /**
     * Launch-intent extras the Flutter embedding itself reads off whatever
     * intent started MainActivity, before any of the app's code runs:
     * `route` becomes the initial route (go_router opens on it — so
     * `route=/widget/assistant?prompt=…` reached Shefi with the prompt and
     * no link for [stripUntrustedPrompt] to clean), `cached_engine_id` /
     * `background_mode` with a bad value crash the launch, `trace-to-file`
     * and the other engine switches are shell flags. The app never sets
     * any of them, so they go from every intent, trusted or not.
     */
    private val FLUTTER_LAUNCH_EXTRAS = arrayOf(
        "route", "dart_entrypoint", "dart_entrypoint_args", "background_mode",
        "cached_engine_id", "cached_engine_group_id", "destroy_engine_with_activity",
        "enable_state_restoration",
        "trace-startup", "start-paused", "disable-service-auth-codes", "endless-trace-buffer",
        "use-test-fonts", "enable-dart-profiling", "profile-startup", "enable-software-rendering",
        "skia-deterministic-rendering", "trace-skia", "trace-skia-allowlist", "trace-systrace",
        "trace-to-file", "profile-microtasks", "enable-impeller", "enable-vulkan-validation",
        "dump-skp-on-shader-compilation", "cache-sksl", "purge-persistent-cache",
        "verbose-logging", "vm-service-port", "dart-flags",
    )

    fun stripFlutterLaunchExtras(intent: Intent?) {
        intent ?: return
        try {
            for (key in FLUTTER_LAUNCH_EXTRAS) intent.removeExtra(key)
        } catch (_: Exception) {
            // A bundle that will not unparcel (another app's malformed
            // extras) would throw again inside Flutter: drop it whole.
            intent.replaceExtras(null as android.os.Bundle?)
        }
    }

    fun open(context: Context, action: String, vararg params: Pair<String, String?>): PendingIntent {
        val builder = Uri.parse(SCHEME + action).buildUpon()
        for ((key, value) in params) if (!value.isNullOrEmpty()) builder.appendQueryParameter(key, value)
        val uri = builder.build()
        val intent = Intent(Intent.ACTION_VIEW, uri, context, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        return PendingIntent.getActivity(
            context,
            uri.toString().hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /**
     * The Shefi widget opens the floating panel over the home screen (the
     * same one "Hey Shefi" and the Gemini route show, hosted by
     * EntryActivity so it needs no "display over other apps"), not the
     * app's chat: the panel's header is the way into the full chat.
     */
    fun assistant(context: Context, voice: Boolean, prompt: String? = null): PendingIntent {
        val intent = Intent(context, EntryActivity::class.java).apply {
            action = EntryActivity.ACTION_SHEFI_PANEL
            putExtra(EntryActivity.EXTRA_VOICE, voice)
            if (!prompt.isNullOrBlank()) putExtra(EntryActivity.EXTRA_PROMPT, prompt)
            putExtra(EXTRA_TRUST, trustToken(context))
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        return PendingIntent.getActivity(
            context,
            ("shefi_panel:$voice:${prompt ?: ""}").hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    fun grocery(context: Context, listId: String?, add: Boolean = false) =
        open(context, "grocery", "list" to listId, "add" to if (add) "1" else null)

    fun plan(context: Context, planId: String?) = open(context, "plan", "plan" to planId)

    fun settings(context: Context) = open(context, "settings")

    /** The quick-add dialog, on the home screen, for [listId]. */
    fun quickAdd(context: Context, widgetId: Int, listId: String?, voice: Boolean = false): PendingIntent {
        val intent = Intent(context, WidgetQuickAddActivity::class.java).apply {
            putExtra(WidgetQuickAddActivity.EXTRA_WIDGET_ID, widgetId)
            putExtra(WidgetQuickAddActivity.EXTRA_LIST_ID, listId)
            putExtra(WidgetQuickAddActivity.EXTRA_VOICE, voice)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            // Distinct data so two widgets' intents never collapse into one.
            data = Uri.parse("easyplate-widget://quick-add/$widgetId?voice=$voice")
        }
        return PendingIntent.getActivity(
            context,
            ("quick-add-$widgetId-$voice").hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /** The widget's own settings screen. */
    fun configure(context: Context, widgetId: Int): PendingIntent {
        val intent = Intent(context, WidgetConfigActivity::class.java).apply {
            putExtra(android.appwidget.AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            putExtra(WidgetConfigActivity.EXTRA_RECONFIGURE, true)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
            data = Uri.parse("easyplate-widget://configure/$widgetId")
        }
        return PendingIntent.getActivity(
            context,
            ("configure-$widgetId").hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /** The broadcast template a list row's tick fills in. */
    fun toggleTemplate(context: Context, widgetId: Int): PendingIntent {
        val intent = Intent(context, WidgetActionReceiver::class.java).apply {
            action = WidgetActionReceiver.ACTION_TOGGLE
            data = Uri.parse("easyplate-widget://toggle/$widgetId")
        }
        return PendingIntent.getBroadcast(
            context,
            ("toggle-$widgetId").hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE,
        )
    }
}
