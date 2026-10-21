// Remote Config, the whole template: every parameter under the heading
// the app's תצורה tab gives it, edited in place and published at once.
import { t, currentLang } from "../i18n.js";
import { h, clear, spinner, button, busy, chips, select, input, textarea, field, toggle, modal, confirmDialog, toast, toastError, empty, debounce } from "../ui.js";
import { call } from "../api.js";

const GROUPS = [
  ["features", (n) => /^ff_/.test(n) || n === "admin_all_features"],
  ["ads", (n) => /^(ads_|quota_)/.test(n)],
  ["share", (n) => /^share_free_/.test(n)],
  ["tts", (n) => /^tts_/.test(n)],
  ["versions", (n) => /^(isProd|minimumVersion|latestVersion|iosAppStoreId)$/.test(n)],
  ["gemini", (n) => /^gemini_/.test(n)],
  ["other", () => true],
];

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
  const stateChips = chips([["all", t("config.filter.all")], ["0", t("config.flags.0")], ["1", t("config.flags.1")], ["2", t("config.flags.2")], ["3", t("config.flags.3")]], state, (s) => { state = s; render(); });
  view.append(h("div.toolbar", h("div.search", input({ placeholder: t("config.search"), oninput: debounce((e) => { search = e.target.value.trim().toLowerCase(); render(); }, 120) })), info), groupChips, body);

  const apply = (result) => { params = result.parameters || []; version = result.version; info.textContent = `${t("config.version", { v: version || "?" })} · ${t("config.count", { n: params.length })}`; };
  // true when saved. A refused save leaves the template as it was, so the
  // caller puts its control back to the saved value.
  const set = async (name, value) => {
    try { apply(await call("config.set", { name, value: String(value) })); toast(t("config.saved"), "ok"); render(); return true; } catch (e) { toastError(e); return false; }
  };

  const row = (p) => {
    const isFlag = /^ff_/.test(p.name);
    let control;
    // Chips and switches show the new state on click; a failed save swaps in
    // a fresh control drawn from the saved value.
    const revert = (make) => { const fresh = make(); control.replaceWith(fresh); control = fresh; };
    const flagChips = () => chips([["0", t("config.flags.0")], ["1", t("config.flags.1")], ["2", t("config.flags.2")], ["3", t("config.flags.3")]], p.value, async (v) => { if (!(await set(p.name, v))) revert(flagChips); });
    const boolToggle = () => toggle(p.value === "true", async (on) => { if (!(await set(p.name, on ? "true" : "false"))) revert(boolToggle); });
    if (isFlag) control = flagChips();
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
    } })), p.description ? h("p.small.muted", p.description) : null, control);
  };

  const render = () => {
    clear(body);
    const inGroup = search ? params : params.filter((p) => { const g = GROUPS.find(([, test]) => test(p.name)); return g && g[0] === group; });
    let rows = inGroup;
    if (search) rows = rows.filter((p) => [p.name, p.description, heading(p), p.value].some((v) => String(v || "").toLowerCase().includes(search)));
    if (group === "features" && state !== "all" && !search) rows = rows.filter((p) => p.value === state);
    if (group === "features" && !search) body.append(stateChips);
    if (group === "gemini") body.append(h("p.small.warn", t("config.deployNote")));
    if (!rows.length) { body.append(empty(t("common.nothingFound"))); return; }
    body.append(h("div.cards", rows.map(row)));
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
  actions.append(button(t("config.add"), { kind: "small", onclick: add }), button(t("common.refresh"), { kind: "small", onclick: () => load() }));

  const load = async () => {
    clear(body);
    body.append(spinner());
    try { apply(await call("config.get")); render(); } catch (e) { clear(body); body.append(h("div.card.error", e.message)); }
  };
  load();
  return () => {};
}
