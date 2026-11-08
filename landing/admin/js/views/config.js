// Remote Config, the whole template: every parameter under the heading
// the app's תצורה tab gives it, edited in place and published at once.
import { t, currentLang, LANGS } from "../i18n.js";
import { h, clear, spinner, button, busy, chips, select, input, textarea, field, toggle, modal, confirmDialog, toast, toastError, empty, debounce } from "../ui.js";
import { call } from "../api.js";

// The five values of an ff_* flag, in the order the chips read (like the
// app's תצורה tab): hidden, free, Premium, coming soon, maintenance.
const FLAG_STATES = ["0", "2", "3", "1", "4"];

const GROUPS = [
  ["features", (n) => /^ff_/.test(n) || n === "admin_all_features"],
  ["ads", (n) => /^(ads_|quota_)/.test(n)],
  ["share", (n) => /^share_free_/.test(n)],
  ["tts", (n) => /^tts_/.test(n)],
  ["versions", (n) => /^(isProd|minimumVersion|latestVersion|iosAppStoreId)$/.test(n)],
  ["gemini", (n) => /^gemini_/.test(n)],
  ["other", () => true],
];

// A flag that opens into the flags under it: the card shows the parent's
// chips and, folded below, one card per child.
// Everything that decides whether a phone rings sits under התראות: the
// per-kind push flags, the invite push allowances and the shopping
// reminder. The children are never listed on their own, also not in a
// search: a hit on one opens its parent's fold.
const SUBFLAGS = [
  ["ff_notifications", "notifications", (n) => /^ff_push_/.test(n) || /^quota_invite_push_/.test(n) || n === "ff_shopping_reminder"],
];
const isSubflag = (name) => SUBFLAGS.some(([, , test]) => test(name));

// Parameters edited for both stores at once or for one of them. A platform
// value is a conditional value under IsAndroidProd / IsIosProd. A platform
// with none follows the "both" value.
const PLATFORM_SPLIT = new Set(["minimumVersion"]);

let labels = null;
async function loadLabels() {
  if (labels) return labels;
  try { labels = await (await fetch("/admin/labels.json", { cache: "no-store" })).json(); } catch (_) { labels = {}; }
  return labels;
}

function camel(key) {
  return key.replace(/^ff_/, "").replace(/_([a-z])/g, (_, c) => c.toUpperCase());
}

// The first sentence of a description, for a parameter with no label yet
// (labels come from the app's i18n files, so a server-only parameter such as
// quota_ai_proxy_daily has none). Long first sentences are cut at a word.
function firstSentence(text) {
  const s = String(text || "").trim().split(/(?<=[.!?。])\s/)[0].replace(/[.!?。]$/, "").trim();
  return s.length > 90 ? s.slice(0, 88).replace(/\s+\S*$/, "") + "…" : s;
}

function heading(p) {
  const name = p.name;
  const lang = currentLang();
  const pick = (l) => (labels[l] ? (/^ff_/.test(name) ? labels[l].featureName[camel(name)] : labels[l].labels[name]) : undefined);
  return pick(lang) || pick("en") || pick("he") || firstSentence(p.description) || name;
}

export async function mount({ view, actions }) {
  await loadLabels();
  let params = [], version = null, search = "", group = "features", state = "all";
  const body = h("div.stack");
  const info = h("span.muted.small");
  const groupChips = chips(GROUPS.map(([g]) => [g, t(`config.groups.${g}`)]), group, (g) => { group = g; render(); });
  const stateChips = chips([["all", t("config.filter.all")], ...FLAG_STATES.map((v) => [v, t(`config.flags.${v}`)])], state, (s) => { state = s; render(); });
  view.append(h("div.toolbar", h("div.search", input({ placeholder: t("config.search"), oninput: debounce((e) => { search = e.target.value.trim().toLowerCase(); render(); }, 120) })), info), groupChips, body);

  const apply = (result) => { params = result.parameters || []; version = result.version; info.textContent = `${t("config.version", { v: version || "?" })} · ${t("config.count", { n: params.length })}`; };
  // true when saved. A refused save leaves the template as it was, so the
  // caller puts its control back to the saved value.
  const set = async (name, value, platform) => {
    try { apply(await call("config.set", platform ? { name, value: String(value), platform } : { name, value: String(value) })); toast(t("config.saved"), "ok"); render(); return true; } catch (e) { toastError(e); return false; }
  };

  // One field per target: both stores, then Android and iOS. A store field
  // shows the value that store reads now. It is marked when it only follows
  // "both".
  const platformControl = (p) => {
    const own = p.platforms || {};
    const line = (platform, value, follows) => {
      const ctl = input({ value, type: "text", style: { direction: "ltr" } });
      const save = button("✓", { kind: "small primary" });
      save.addEventListener("click", busy(save, async () => { if (ctl.value.trim() && (ctl.value !== value || follows)) await set(p.name, ctl.value.trim(), platform); }));
      ctl.addEventListener("keydown", (e) => { if (e.key === "Enter") save.click(); });
      return h("div.row", h("div", { style: { minWidth: "110px" } }, h("b.small", t(`config.platforms.${platform}`)), follows ? h("div.small.muted", t("config.platforms.follows")) : null), h("div.grow", ctl), save);
    };
    return h("div.stack",
      line("both", p.value, false),
      line("android", own.android ?? p.value, own.android == null),
      line("ios", own.ios ?? p.value, own.ios == null),
      h("p.small.muted", t("config.platforms.hint")));
  };

  const row = (p, children = null) => {
    const isFlag = /^ff_/.test(p.name);
    let control;
    // Chips and switches show the new state on click; a failed save swaps in
    // a fresh control drawn from the saved value.
    const revert = (make) => { const fresh = make(); control.replaceWith(fresh); control = fresh; };
    const flagChips = () => chips(FLAG_STATES.map((v) => [v, t(`config.flags.${v}`)]), p.value, async (v) => { if (!(await set(p.name, v))) revert(flagChips); });
    const boolToggle = () => toggle(p.value === "true", async (on) => { if (!(await set(p.name, on ? "true" : "false"))) revert(boolToggle); });
    if (PLATFORM_SPLIT.has(p.name)) control = platformControl(p);
    else if (isFlag) control = flagChips();
    else if (p.valueType === "BOOLEAN") control = boolToggle();
    else if (p.valueType === "JSON") {
      const area = textarea({ value: p.value, style: { direction: "ltr", fontFamily: "ui-monospace, Menlo, monospace", fontSize: "12.5px" } });
      control = h("div.stack", area, h("div.row", ((b) => { b.addEventListener("click", busy(b, async () => { try { JSON.parse(area.value); } catch (_) { toast(t("common.invalidJson"), "error"); return; } await set(p.name, area.value); })); return b; })(button(t("common.save"), { kind: "small primary" }))));
    } else {
      const ctl = input({ value: p.value, type: p.valueType === "NUMBER" ? "number" : "text", step: "any", style: { direction: "ltr" } });
      const save = button("✓", { kind: "small primary" });
      save.addEventListener("click", busy(save, async () => { if (ctl.value !== p.value) await set(p.name, ctl.value); }));
      ctl.addEventListener("keydown", (e) => { if (e.key === "Enter") save.click(); });
      control = h("div.row", h("div.grow", ctl), save);
    }
    return h("div.card", h("div.row.between", h("div", h("h3", heading(p)), h("div.small.muted.mono", p.name, p.group ? ` · ${p.group}` : "")), button("✕", { kind: "ghost small", title: t("config.delete"), onclick: async () => {
      if (!(await confirmDialog({ title: t("config.delete"), text: `${t("config.confirmDelete", { name: p.name })} ${t("config.deleteHint")}` }))) return;
      try { apply(await call("config.delete", { name: p.name })); toast(t("common.deleted"), "ok"); render(); } catch (e) { toastError(e); }
    } })), p.description ? h("p.small.muted", p.description) : null, control, children ? subflags(p, children) : null);
  };

  // The fold under a parent flag. Remembers being open across re-renders
  // (every save re-renders), so a change inside it does not snap it shut.
  const opened = new Set();
  // Parents a search or state filter opened because a child matched.
  let forced = new Set();
  const subflags = (p, children) => {
    const [, key] = SUBFLAGS.find(([parent]) => parent === p.name);
    const counts = FLAG_STATES.map((v) => [v, children.filter((c) => c.value === v).length]).filter(([, n]) => n);
    const tally = counts.map(([v, n]) => `${n} ${t(`config.flags.${v}`)}`).join(" · ");
    const box = h("details.subflags", h("summary", h("span", t(`config.subflags.${key}`, { n: children.length })), h("span.small.muted", tally)), h("p.small.muted", t("config.subflags.hint")), h("div.cards", children.map((c) => row(c))));
    box.open = opened.has(p.name) || forced.has(p.name);
    box.addEventListener("toggle", () => { if (box.open) opened.add(p.name); else opened.delete(p.name); });
    return box;
  };

  const render = () => {
    clear(body);
    const filtering = Boolean(search) || (group === "features" && state !== "all");
    const matches = (p) => (!search || [p.name, p.description, heading(p), p.value].some((v) => String(v || "").toLowerCase().includes(search)))
      && (group !== "features" || state === "all" || search || p.value === state);
    const inGroup = search ? params : params.filter((p) => { const g = GROUPS.find(([, test]) => test(p.name)); return g && g[0] === group; });
    forced = new Set();
    const shown = [];
    for (const p of inGroup) {
      if (isSubflag(p.name)) continue;
      const entry = SUBFLAGS.find(([parent]) => parent === p.name);
      const kids = entry ? params.filter((c) => entry[2](c.name)) : [];
      const hits = filtering ? kids.filter(matches) : kids;
      if (!matches(p) && !hits.length) continue;
      if (filtering && hits.length) forced.add(p.name);
      // A filter that hit children shows just those; otherwise all of them.
      shown.push([p, kids.length ? (filtering && hits.length ? hits : kids) : null]);
    }
    // The parents (התראות) lead their group.
    shown.sort((a, b) => (b[1] ? 1 : 0) - (a[1] ? 1 : 0));
    if (group === "features" && !search) body.append(stateChips);
    if (group === "gemini") body.append(h("p.small.warn", t("config.deployNote")));
    if (!shown.length) { body.append(empty(t("common.nothingFound"))); return; }
    body.append(h("div.cards", shown.map(([p, kids]) => row(p, kids))));
  };

  const add = () => {
    const name = input({ placeholder: "my_parameter", style: { direction: "ltr" } });
    const type = select([["STRING", "STRING"], ["NUMBER", "NUMBER"], ["BOOLEAN", "BOOLEAN"], ["JSON", "JSON"]]);
    const value = input({ style: { direction: "ltr" } });
    const description = textarea();
    const groupCtl = input({ placeholder: "featureFlags", style: { direction: "ltr" } });
    modal({ title: t("config.add"), body: h("div.stack", h("p.small.muted", t("config.addHint")), field(t("config.name"), name), h("div.grid2", field(t("config.type"), type), field(t("config.value"), value)), field(t("config.description"), description), field(t("config.group"), groupCtl)), actions: [(c) => button(t("common.cancel"), { onclick: c }), (c) => { const b = button(t("common.add"), { kind: "primary" }); b.addEventListener("click", busy(b, async () => {
      if (!name.value.trim()) return;
      try { apply(await call("config.add", { name: name.value.trim(), valueType: type.value, value: value.value, description: description.value.trim(), group: groupCtl.value.trim() })); toast(t("config.saved"), "ok"); c(); render(); } catch (e) { toastError(e); }
    })); return b; }] });
  };
  // The shared translation cache (translateContent) is not Remote Config,
  // but it is the other server-side switch the app's content runs through:
  // a line whose cached translation is wrong, or was planted, is dropped
  // here and translated afresh on the next request.
  const purge = () => {
    const text = textarea({ placeholder: "1 כוס סוכר" });
    const lang = select([["", t("config.purge.allLangs")], ...Object.entries(LANGS)]);
    const result = h("div.stack");
    modal({ title: t("config.purge.title"), body: h("div.stack", h("p.small.muted", t("config.purge.hint")), field(t("config.purge.text"), text), field(t("config.purge.lang"), lang), result), actions: [(c) => button(t("common.cancel"), { onclick: c }), () => { const b = button(t("config.purge.run"), { kind: "danger" }); b.addEventListener("click", busy(b, async () => {
      const line = text.value.trim();
      if (!line) return;
      if (!(await confirmDialog({ title: t("config.purge.title"), text: t("config.purge.confirm", { lang: lang.value ? LANGS[lang.value] : t("config.purge.allLangs") }) }))) return;
      try {
        const r = await call("translation.purge", lang.value ? { text: line, lang: lang.value } : { text: line });
        const removed = r.removed || [];
        clear(result);
        if (!removed.length) { result.append(h("p.small.muted", t("config.purge.none"))); return; }
        result.append(h("p.small", t("config.purge.done", { n: removed.length })), ...removed.map((e) => h("div.small", h("b", `${LANGS[e.lang] || e.lang}: `), (e.texts || []).map((x) => (x.by === null ? x.text : `${x.text} (${x.by})`)).join(" · "))));
        toast(t("common.deleted"), "ok");
      } catch (e) { toastError(e); }
    })); return b; }] });
  };
  actions.append(button(t("config.add"), { kind: "small", onclick: add }), button(t("config.purge.title"), { kind: "small", onclick: purge }), button(t("common.refresh"), { kind: "small", onclick: () => load() }));

  const load = async () => {
    clear(body);
    body.append(spinner());
    try { apply(await call("config.get")); render(); } catch (e) { clear(body); body.append(h("div.card.error", e.message)); }
  };
  load();
  return () => {};
}
