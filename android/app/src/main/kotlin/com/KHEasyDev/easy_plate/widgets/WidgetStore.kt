package com.KHEasyDev.easy_plate.widgets

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import java.util.UUID

/**
 * What the app wrote for the widgets, and what the widgets wrote back.
 *
 * The snapshot (`lib/core/home_widgets/home_widgets_snapshot.dart`) is one
 * JSON document the app rewrites on every change; the widgets only read
 * it. The pending queue runs the other way: a line added from the quick-add
 * dialog or a tick on the list widget is appended here, drawn at once, and
 * applied by the app through its own repositories the next time it runs
 * (or right away, if it is alive — see [HomeWidgetsChannel.nudge]).
 */
object WidgetStore {
    private const val PREFS = "easy_plate_widgets"
    private const val KEY_SNAPSHOT = "snapshot"
    private const val KEY_PENDING = "pending"
    private const val KEY_CONFIG_PREFIX = "w_"

    fun prefs(context: Context): SharedPreferences =
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    // ---- Snapshot ---------------------------------------------------------

    fun writeSnapshot(context: Context, json: String) {
        prefs(context).edit().putString(KEY_SNAPSHOT, json).apply()
    }

    fun clearSnapshot(context: Context) {
        prefs(context).edit().remove(KEY_SNAPSHOT).remove(KEY_PENDING).apply()
    }

    /** The snapshot with the queue's optimistic changes laid over it. */
    fun snapshot(context: Context): WidgetSnapshot? {
        val raw = prefs(context).getString(KEY_SNAPSHOT, null) ?: return null
        val parsed = try {
            WidgetSnapshot.parse(JSONObject(raw))
        } catch (e: Exception) {
            return null
        }
        return parsed.applying(pending(context))
    }

    // ---- Pending queue ----------------------------------------------------

    fun pending(context: Context): List<PendingAction> {
        val raw = prefs(context).getString(KEY_PENDING, null) ?: return emptyList()
        return try {
            val array = JSONArray(raw)
            (0 until array.length()).mapNotNull { i ->
                array.optJSONObject(i)?.let { PendingAction.parse(it) }
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    fun pendingJson(context: Context): String = prefs(context).getString(KEY_PENDING, "[]") ?: "[]"

    @Synchronized
    fun enqueue(context: Context, action: PendingAction) {
        val list = pending(context) + action
        prefs(context).edit().putString(KEY_PENDING, PendingAction.encode(list)).apply()
    }

    @Synchronized
    fun removePending(context: Context, ids: Collection<String>) {
        val remaining = pending(context).filterNot { it.id in ids }
        prefs(context).edit().putString(KEY_PENDING, PendingAction.encode(remaining)).apply()
    }

    // ---- Per-widget configuration ----------------------------------------

    fun config(context: Context, widgetId: Int): WidgetConfig {
        val raw = prefs(context).getString(KEY_CONFIG_PREFIX + widgetId, null)
            ?: return WidgetConfig()
        return try {
            WidgetConfig.parse(JSONObject(raw))
        } catch (e: Exception) {
            WidgetConfig()
        }
    }

    fun writeConfig(context: Context, widgetId: Int, config: WidgetConfig) {
        prefs(context).edit().putString(KEY_CONFIG_PREFIX + widgetId, config.encode()).apply()
    }

    fun removeConfig(context: Context, widgetIds: IntArray) {
        val editor = prefs(context).edit()
        for (id in widgetIds) editor.remove(KEY_CONFIG_PREFIX + id)
        editor.apply()
    }
}

/** One widget's own settings, over the app's defaults. */
data class WidgetConfig(
    /** `app`, `system`, `light` or `dark`; null follows the app's defaults. */
    val appearance: String? = null,
    val listId: String? = null,
    val planId: String? = null,
    /** Whether the Shefi button opens listening; null follows the defaults. */
    val voice: Boolean? = null,
    val showChecked: Boolean = false,
) {
    fun encode(): String = JSONObject().apply {
        put("appearance", appearance)
        put("listId", listId)
        put("planId", planId)
        if (voice != null) put("voice", voice)
        put("showChecked", showChecked)
    }.toString()

    companion object {
        fun parse(json: JSONObject) = WidgetConfig(
            appearance = json.optString("appearance").ifEmpty { null },
            listId = json.optString("listId").ifEmpty { null },
            planId = json.optString("planId").ifEmpty { null },
            voice = if (json.has("voice")) json.optBoolean("voice") else null,
            showChecked = json.optBoolean("showChecked", false),
        )
    }
}

data class PendingAction(
    val id: String,
    val type: String,
    val listId: String?,
    val name: String? = null,
    val itemId: String? = null,
    val checked: Boolean? = null,
    val at: Long = System.currentTimeMillis(),
) {
    fun toJson(): JSONObject = JSONObject().apply {
        put("id", id)
        put("type", type)
        put("listId", listId)
        put("name", name)
        put("itemId", itemId)
        if (checked != null) put("checked", checked)
        put("at", at)
    }

    companion object {
        fun add(listId: String?, name: String) =
            PendingAction(UUID.randomUUID().toString(), "add", listId, name = name)

        fun toggle(listId: String, itemId: String, checked: Boolean) =
            PendingAction(UUID.randomUUID().toString(), "toggle", listId, itemId = itemId, checked = checked)

        fun parse(json: JSONObject): PendingAction? {
            val id = json.optString("id").ifEmpty { return null }
            val type = json.optString("type").ifEmpty { return null }
            return PendingAction(
                id = id,
                type = type,
                listId = json.optString("listId").ifEmpty { null },
                name = json.optString("name").ifEmpty { null },
                itemId = json.optString("itemId").ifEmpty { null },
                checked = if (json.has("checked")) json.optBoolean("checked") else null,
                at = json.optLong("at", 0L),
            )
        }

        fun encode(actions: List<PendingAction>): String =
            JSONArray().apply { actions.forEach { put(it.toJson()) } }.toString()
    }
}

// ---- The snapshot ---------------------------------------------------------

data class WidgetItem(val id: String, val name: String, val qty: String, val checked: Boolean, val pending: Boolean = false)

data class WidgetList(val id: String, val name: String, val items: List<WidgetItem>) {
    val total get() = items.size
    val checked get() = items.count { it.checked }
    val remaining get() = total - checked
}

data class WidgetMealItem(val id: String, val label: String, val recipeId: String?)
data class WidgetMeal(val id: String, val name: String, val items: List<WidgetMealItem>)
data class WidgetPlan(val id: String, val name: String, val days: List<List<WidgetMeal>>) {
    fun today(): List<WidgetMeal> = days.getOrElse(todayIndex()) { emptyList() }

    companion object {
        /** Sunday is 0, as in the app's plans. */
        fun todayIndex(): Int = Calendar.getInstance().get(Calendar.DAY_OF_WEEK) - 1
    }
}

data class WidgetDefaults(val listId: String?, val planId: String?, val voice: Boolean, val appearance: String)

data class WidgetSnapshot(
    val signedIn: Boolean,
    /** `enabled`, `comingSoon`, `locked` or `hidden`. */
    val access: String,
    /** Shefi's own gate: a free account sees "Premium only" on the Shefi widget. */
    val assistantAccess: String,
    val lang: String,
    val rtl: Boolean,
    val dark: Boolean,
    val defaults: WidgetDefaults,
    val strings: Map<String, String>,
    val weekdays: List<String>,
    val prompts: List<String>,
    val lists: List<WidgetList>,
    val plans: List<WidgetPlan>,
) {
    val enabled get() = signedIn && access == "enabled"

    fun s(key: String, fallback: String = key): String = strings[key] ?: fallback

    fun list(id: String?): WidgetList? =
        lists.firstOrNull { it.id == id }
            ?: lists.firstOrNull { it.id == defaults.listId }
            ?: lists.firstOrNull()

    fun plan(id: String?): WidgetPlan? =
        plans.firstOrNull { it.id == id }
            ?: plans.firstOrNull { it.id == defaults.planId }
            ?: plans.firstOrNull()

    fun todayLabel(): String = weekdays.getOrNull(WidgetPlan.todayIndex()) ?: ""

    /** The queue, drawn as if the app had already applied it. */
    fun applying(actions: List<PendingAction>): WidgetSnapshot {
        if (actions.isEmpty()) return this
        val lists = lists.map { list ->
            var items = list.items
            for (action in actions) {
                val target = action.listId ?: defaults.listId ?: this.lists.firstOrNull()?.id
                if (target != list.id) continue
                items = when (action.type) {
                    "add" -> items + WidgetItem(action.id, action.name ?: "", "", checked = false, pending = true)
                    "toggle" -> items.map {
                        if (it.id == action.itemId) it.copy(checked = action.checked ?: !it.checked) else it
                    }
                    else -> items
                }
            }
            list.copy(items = items)
        }
        return copy(lists = lists)
    }

    companion object {
        fun parse(json: JSONObject): WidgetSnapshot {
            val strings = mutableMapOf<String, String>()
            json.optJSONObject("s")?.let { s ->
                for (key in s.keys()) strings[key] = s.optString(key)
            }
            val defaultsJson = json.optJSONObject("defaults")
            val defaults = WidgetDefaults(
                listId = defaultsJson?.optString("listId")?.ifEmpty { null },
                planId = defaultsJson?.optString("planId")?.ifEmpty { null },
                voice = defaultsJson?.optBoolean("voice", false) ?: false,
                appearance = defaultsJson?.optString("appearance")?.ifEmpty { null } ?: "app",
            )
            return WidgetSnapshot(
                signedIn = json.optBoolean("signedIn", false),
                access = json.optString("access", "enabled"),
                assistantAccess = json.optString("assistantAccess", "enabled"),
                lang = json.optString("lang", "en"),
                rtl = json.optBoolean("rtl", false),
                dark = json.optBoolean("dark", false),
                defaults = defaults,
                strings = strings,
                weekdays = json.optJSONArray("weekdays").toStrings(),
                prompts = json.optJSONArray("prompts").toStrings(),
                lists = json.optJSONArray("lists").objects().map { l ->
                    WidgetList(
                        id = l.optString("id"),
                        name = l.optString("name"),
                        items = l.optJSONArray("items").objects().map { i ->
                            WidgetItem(i.optString("id"), i.optString("name"), i.optString("qty"), i.optBoolean("checked"))
                        },
                    )
                },
                plans = json.optJSONArray("plans").objects().map { p ->
                    WidgetPlan(
                        id = p.optString("id"),
                        name = p.optString("name"),
                        days = p.optJSONArray("days").let { days ->
                            (0 until (days?.length() ?: 0)).map { d ->
                                days!!.optJSONArray(d).objects().map { m ->
                                    WidgetMeal(
                                        id = m.optString("id"),
                                        name = m.optString("name"),
                                        items = m.optJSONArray("items").objects().map { it ->
                                            WidgetMealItem(it.optString("id"), it.optString("label"), it.optString("recipeId").ifEmpty { null })
                                        },
                                    )
                                }
                            }
                        },
                    )
                },
            )
        }

        private fun JSONArray?.toStrings(): List<String> =
            this?.let { a -> (0 until a.length()).map { a.optString(it) } } ?: emptyList()

        private fun JSONArray?.objects(): List<JSONObject> =
            this?.let { a -> (0 until a.length()).mapNotNull { a.optJSONObject(it) } } ?: emptyList()
    }
}
