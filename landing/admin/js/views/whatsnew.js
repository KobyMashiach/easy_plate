// "What's new": one release per build, with a page for every feature the
// administrator picks from the feature flags. The app shows a returning
// account the pages of every published release between the build it last
// acknowledged and the one it runs; a fresh install sees none. The list is
// a live Firestore listener; every write goes through adminPanel
// (whatsnew.save / whatsnew.delete), which types and caps the document.
import { db, collection, onSnapshot, query, orderBy } from "../firebase.js";
import { t, currentLang, fmtDate, toDate } from "../i18n.js";
import { h, clear, badge, button, busy, chips, input, textarea, select, toggle, field, modal, confirmDialog, toast, toastError, empty, spinner } from "../ui.js";
import { call } from "../api.js";

const LANGS = ["he", "en", "ar", "fr", "ru"];

// Mirrors `whatsNewIcons` and `WhatsNewTargets` in the app
// (lib/features/whats_new/domain/whats_new_targets.dart): the app draws
// only what is on these lists.
const ICONS = ["auto_awesome", "new_releases", "celebration", "star", "lightbulb", "bolt", "restaurant_menu", "menu_book", "library_books", "calendar_today", "shopping_cart", "groups", "forum", "favorite", "timer", "local_fire_department", "monitor_heart", "image", "image_search", "share", "qr_code", "family_restroom", "receipt_long", "price_check", "notifications", "workspace_premium", "translate", "palette", "school", "feedback", "devices", "widgets", "mic", "record_voice_over", "smart_toy", "link", "video_library", "text_fields", "picture_as_pdf", "security"];
const TARGETS = ["", "tab:recipes", "tab:library", "tab:mealPlan", "tab:groceries", "tab:community", "ingestion", "assistant", "price_book", "settings", "preferences", "notification_settings", "account_menu", "notifications", "profile_edit", "sharing", "household", "join_code", "scan_code", "home_widgets", "wake_word", "support", "help", "premium", "tutorial"];

// A flag's default icon, so a picked feature starts with something fitting.
const DEFAULT_ICONS = {
  ff_books: "menu_book", ff_meal_plans: "calendar_today", ff_grocery_lists: "shopping_cart", ff_community: "groups",
  ff_ingest_text: "text_fields", ff_ingest_web_search: "image_search", ff_ingest_link: "link", ff_ingest_social_video: "video_library", ff_ingest_ai_request: "smart_toy", ff_ingest_file: "picture_as_pdf", ff_share_in: "share", ff_save_with_ai: "auto_awesome",
  ff_cook_mode: "local_fire_department", ff_cook_timers: "timer", ff_nutrition: "monitor_heart", ff_recipe_image_ai: "image", ff_recipe_image_search: "image_search", ff_grocery_from_recipe: "shopping_cart",
  ff_shared_recipes: "restaurant_menu", ff_forum: "forum", ff_likes: "favorite",
  ff_share_recipes: "share", ff_share_books: "share", ff_share_plans: "share", ff_share_grocery_lists: "share", ff_share_codes: "qr_code", ff_households: "family_restroom",
  ff_price_book: "price_check", ff_receipt_scan: "receipt_long", ff_grocery_cost: "price_check", ff_shopping_reminder: "notifications",
  ff_assistant: "smart_toy", ff_assistant_scoped: "smart_toy", ff_assistant_voice: "mic", ff_notifications: "notifications", ff_premium: "workspace_premium", ff_content_translation: "translate", ff_theming: "palette", ff_walkthrough: "school", ff_tutorial_book: "school", ff_feedback: "feedback",
  ff_single_session: "devices", ff_home_widgets: "widgets", ff_wake_word: "mic", ff_voice_assistants: "record_voice_over", ff_shefi_launcher: "smart_toy", ff_whats_new: "new_releases",
};

let labels = null;
async function loadLabels() {
  if (labels) return labels;
  try { labels = await (await fetch("/admin/labels.json", { cache: "no-store" })).json(); } catch (_) { labels = {}; }
  return labels;
}

function camel(key) {
  return key.replace(/^ff_/, "").replace(/_([a-z])/g, (_, c) => c.toUpperCase());
}

function flagName(key, lang = currentLang()) {
  const pick = (l) => (labels && labels[l] ? labels[l].featureName[camel(key)] : undefined);
  return pick(lang) || pick("en") || pick("he") || key;
}

function textIn(map, lang = currentLang()) {
  if (!map || typeof map !== "object") return "";
  return map[lang] || map.en || map.he || Object.values(map).find(Boolean) || "";
}

function flagState(value) {
  const key = `config.flags.${value}`;
  return t(key) === key ? value : t(key);
}

// A date-only input value, in the browser's zone.
function dateInputValue(ms) {
  const d = new Date(ms - new Date(ms).getTimezoneOffset() * 60000);
  return d.toISOString().slice(0, 10);
}

export async function mount({ view, actions }) {
  await loadLabels();
  let releases = [], flags = null;
  const body = h("div.stack");
  view.append(body);

  // The flags, named and with their console state, for the checklist.
  const ensureFlags = async () => {
    if (flags) return flags;
    const result = await call("config.get");
    flags = (result.parameters || []).filter((p) => /^ff_/.test(p.name)).map((p) => ({ key: p.name, value: p.value, description: p.description || "" }));
    flags.sort((a, b) => flagName(a.key).localeCompare(flagName(b.key)));
    return flags;
  };

  // ---- editor --------------------------------------------------------------

  async function edit(release) {
    let all;
    try { all = await ensureFlags(); } catch (e) { toastError(e); return; }
    const isNew = !release;
    const draft = {
      versionCode: release ? release.versionCode : (releases && releases[0] ? releases[0].versionCode + 1 : 1),
      version: release ? release.version : "",
      releasedAt: release && release.releasedAt ? toDate(release.releasedAt).getTime() : Date.now(),
      isPublished: release ? release.isPublished === true : false,
      features: release ? (release.features || []).map((f) => ({ ...f, title: { ...(f.title || {}) }, description: { ...(f.description || {}) } })) : [],
    };
    const picked = () => draft.features;
    const find = (key) => draft.features.find((f) => f.featureKey === key);

    const versionCtl = input({ type: "number", min: 1, step: 1, value: String(draft.versionCode), style: { direction: "ltr" }, disabled: !isNew });
    const nameCtl = input({ value: draft.version, placeholder: "1.2.0", style: { direction: "ltr" } });
    const dateCtl = input({ type: "date", value: dateInputValue(draft.releasedAt), style: { direction: "ltr" } });
    const publishedCtl = toggle(draft.isPublished, (on) => { draft.isPublished = on; });

    const searchCtl = input({ placeholder: t("common.search") });
    const checklist = h("div.stack", { style: { maxHeight: "260px", overflowY: "auto", gap: "4px", border: "1px solid var(--line, rgba(127,127,127,.25))", borderRadius: "8px", padding: "6px 8px" } });
    const pages = h("div.stack");

    const paintChecklist = () => {
      clear(checklist);
      const q = searchCtl.value.trim().toLowerCase();
      for (const flag of all) {
        if (q && !flagName(flag.key).toLowerCase().includes(q) && !flag.key.includes(q) && !flag.description.toLowerCase().includes(q)) continue;
        const box = h("input", { type: "checkbox", checked: !!find(flag.key) });
        box.addEventListener("change", () => {
          if (box.checked) draft.features.push({ featureKey: flag.key, title: {}, description: {}, imageUrl: "", iconName: DEFAULT_ICONS[flag.key] || "auto_awesome", targetRoute: "", sortOrder: draft.features.length });
          else draft.features = draft.features.filter((f) => f.featureKey !== flag.key);
          paintPages();
        });
        checklist.append(h("label.row", { style: { gap: "8px", alignItems: "center" } }, box, h("span", flagName(flag.key)), h("span.small.muted.mono", flag.key), badge(flagState(flag.value), flag.value === "2" ? "green" : flag.value === "3" ? "brand" : flag.value === "1" ? "amber" : "red")));
      }
      if (!checklist.children.length) checklist.append(empty(t("common.nothingFound")));
    };

    const pageCard = (f, index) => {
      let lang = currentLang();
      const titleCtl = input({ maxLength: 200 });
      const descCtl = textarea({ rows: 3, maxLength: 2000 });
      const syncInputs = () => { titleCtl.value = f.title[lang] || ""; descCtl.value = f.description[lang] || ""; titleCtl.dir = descCtl.dir = ["he", "ar"].includes(lang) ? "rtl" : "ltr"; };
      titleCtl.addEventListener("input", () => { f.title[lang] = titleCtl.value; paintLangChips(); });
      descCtl.addEventListener("input", () => { f.description[lang] = descCtl.value; paintLangChips(); });
      const langRow = h("div");
      const paintLangChips = () => {
        clear(langRow);
        langRow.append(chips(LANGS.map((l) => [l, `${l.toUpperCase()}${f.title[l] || f.description[l] ? " ✓" : ""}`]), lang, (v) => { lang = v; syncInputs(); paintLangChips(); }));
      };
      paintLangChips();
      syncInputs();

      const translate = button(t("whatsnew.translate"), { kind: "small" });
      translate.addEventListener("click", busy(translate, async () => {
        const title = (f.title[lang] || "").trim();
        const description = (f.description[lang] || "").trim();
        if (!title && !description) return toast(t("whatsnew.needText"), "error");
        try {
          const r = await call("whatsnew.translate", { title, description, from: lang });
          for (const l of LANGS) {
            if (r.title && r.title[l]) f.title[l] = r.title[l];
            if (r.description && r.description[l]) f.description[l] = r.description[l];
          }
          paintLangChips();
          toast(t("whatsnew.translated"), "ok");
        } catch (e) { toastError(e); }
      }));

      const iconCtl = select(ICONS.map((i) => [i, i]), { value: f.iconName || "auto_awesome", style: { direction: "ltr" } });
      iconCtl.addEventListener("change", () => { f.iconName = iconCtl.value; });
      const targetCtl = select(TARGETS.map((r) => [r, r ? (t(`whatsnew.targets.${r}`) === `whatsnew.targets.${r}` ? r : t(`whatsnew.targets.${r}`)) : t("whatsnew.noTarget")]), { value: f.targetRoute || "", style: { direction: "ltr" } });
      targetCtl.addEventListener("change", () => { f.targetRoute = targetCtl.value; });
      const imageCtl = input({ value: f.imageUrl || "", placeholder: "https://…", style: { direction: "ltr" } });
      imageCtl.addEventListener("input", () => { f.imageUrl = imageCtl.value.trim(); });

      const move = (delta) => {
        const to = index + delta;
        if (to < 0 || to >= draft.features.length) return;
        const list = draft.features;
        [list[index], list[to]] = [list[to], list[index]];
        paintPages();
      };

      return h("div.card", { style: { padding: "12px 14px" } },
        h("div.row.between",
          h("div.row", { style: { gap: "8px" } }, h("b", `${index + 1}. ${flagName(f.featureKey)}`), h("span.small.muted.mono", f.featureKey)),
          h("div.row", { style: { gap: "4px" } },
            button("↑", { kind: "ghost small", title: t("whatsnew.moveUp"), onclick: () => move(-1), disabled: index === 0 }),
            button("↓", { kind: "ghost small", title: t("whatsnew.moveDown"), onclick: () => move(1), disabled: index === draft.features.length - 1 }),
            button("✕", { kind: "ghost small", title: t("common.delete"), onclick: () => { draft.features = draft.features.filter((x) => x !== f); paintChecklist(); paintPages(); } }),
          ),
        ),
        h("div.row.between", { style: { alignItems: "center" } }, langRow, translate),
        field(t("whatsnew.featureTitle"), titleCtl, t("whatsnew.featureTitleHint")),
        field(t("whatsnew.featureDescription"), descCtl),
        h("div.grid2", field(t("whatsnew.icon"), iconCtl), field(t("whatsnew.target"), targetCtl, t("whatsnew.targetHint"))),
        field(t("whatsnew.image"), imageCtl, t("whatsnew.imageHint")),
      );
    };

    const paintPages = () => {
      clear(pages);
      draft.features.forEach((f, i) => { f.sortOrder = i; });
      if (!draft.features.length) { pages.append(h("p.small.muted", t("whatsnew.pickHint"))); return; }
      pages.append(h("h3", t("whatsnew.pages", { n: draft.features.length })));
      draft.features.forEach((f, i) => pages.append(pageCard(f, i)));
    };

    searchCtl.addEventListener("input", paintChecklist);
    paintChecklist();
    paintPages();

    modal({
      title: isNew ? t("whatsnew.newRelease") : t("whatsnew.editRelease", { v: draft.version || draft.versionCode }),
      wide: true,
      body: h("div.stack",
        h("div.grid3",
          field(t("whatsnew.versionCode"), versionCtl, t("whatsnew.versionCodeHint")),
          field(t("whatsnew.version"), nameCtl, t("whatsnew.versionHint")),
          field(t("whatsnew.releasedAt"), dateCtl),
        ),
        field(t("whatsnew.published"), publishedCtl, t("whatsnew.publishedHint")),
        h("h3", t("whatsnew.features")),
        h("p.small.muted", t("whatsnew.featuresHint")),
        h("div.search", searchCtl),
        checklist,
        pages,
      ),
      actions: [(c) => button(t("common.cancel"), { onclick: c }), (c) => {
        const b = button(t("common.save"), { kind: "primary" });
        b.addEventListener("click", busy(b, async () => {
          const versionCode = Number(versionCtl.value);
          const version = nameCtl.value.trim();
          if (!Number.isInteger(versionCode) || versionCode < 1) return toast(t("whatsnew.badCode"), "error");
          if (!/^\d+(\.\d+){0,3}$/.test(version)) return toast(t("whatsnew.badVersion"), "error");
          if (!draft.features.length) return toast(t("whatsnew.needFeatures"), "error");
          const missing = draft.features.filter((f) => !Object.values(f.title).some((v) => v && v.trim()));
          if (missing.length) return toast(t("whatsnew.needTitle", { name: flagName(missing[0].featureKey) }), "error");
          if (isNew && (releases || []).some((r) => r.versionCode === versionCode)) return toast(t("whatsnew.codeExists"), "error");
          const releasedAt = dateCtl.value ? new Date(`${dateCtl.value}T12:00:00`).getTime() : Date.now();
          try {
            await call("whatsnew.save", { versionCode, version, releasedAt, isPublished: draft.isPublished, features: draft.features });
            toast(t("common.done"), "ok");
            c();
          } catch (e) { toastError(e); }
        }));
        return b;
      }],
    });
  }

  async function setPublished(release, on) {
    try {
      await call("whatsnew.save", { versionCode: release.versionCode, version: release.version, releasedAt: release.releasedAt ? toDate(release.releasedAt).getTime() : Date.now(), isPublished: on, features: release.features || [] });
      toast(on ? t("whatsnew.publishedNow") : t("whatsnew.unpublishedNow"), "ok");
    } catch (e) { toastError(e); }
  }

  async function remove(release) {
    if (!(await confirmDialog({ title: t("whatsnew.deleteRelease", { v: release.version }) }))) return;
    try { await call("whatsnew.delete", { versionCode: release.versionCode }); toast(t("common.deleted"), "ok"); } catch (e) { toastError(e); }
  }

  // ---- list ----------------------------------------------------------------

  function render() {
    clear(body);
    if (releases === null) { body.append(spinner()); return; }
    body.append(h("p.small.muted", t("whatsnew.intro")));
    if (!releases.length) { body.append(empty(t("whatsnew.none"))); return; }
    const list = h("div.list");
    for (const r of releases) {
      const features = r.features || [];
      list.append(h("div.item", h("div.body",
        h("div.row", h("b", `${r.version}`), h("span.small.muted.mono", t("whatsnew.build", { n: r.versionCode })), r.isPublished ? badge(t("whatsnew.publishedBadge"), "green") : badge(t("whatsnew.draft"), "amber"), r.releasedAt ? h("span.small.muted", fmtDate(toDate(r.releasedAt), false)) : null),
        h("div.small.muted", t("whatsnew.pages", { n: features.length })),
        h("ul", { style: { margin: "4px 0 0", paddingInlineStart: "18px" } }, features.map((f) => h("li", h("span", textIn(f.title) || flagName(f.featureKey)), h("span.small.muted.mono", ` · ${f.featureKey}`), f.targetRoute ? h("span.small.muted", ` → ${f.targetRoute}`) : null))),
        h("div.row",
          button(t("common.edit"), { kind: "small", onclick: () => edit(r) }),
          button(r.isPublished ? t("whatsnew.unpublish") : t("common.publish"), { kind: r.isPublished ? "small" : "small primary", onclick: () => setPublished(r, !r.isPublished) }),
          button(t("common.delete"), { kind: "ghost small", onclick: () => remove(r) }),
        ),
      )));
    }
    body.append(list);
  }

  clear(actions);
  actions.append(button(t("whatsnew.newRelease"), { kind: "primary", onclick: () => edit(null) }));

  releases = null;
  render();
  const unsub = onSnapshot(query(collection(db, "whats_new_releases"), orderBy("versionCode", "desc")), (snap) => {
    releases = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    render();
  }, (err) => { releases = []; render(); toastError(err); });
  return () => unsub();
}
