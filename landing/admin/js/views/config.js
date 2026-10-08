// Remote Config, the whole template: every parameter under the heading
// the app's תצורה tab gives it, edited in place and published at once.
import { t, currentLang } from "../i18n.js";
import { h, clear, spinner, button, busy, chips, select, input, textarea, field, toggle, modal, confirmDialog, toast, toastError, empty, debounce } from "../ui.js";
import { call } from "../api.js";

const GROUPS = [
  ["features", (n) => /^ff_/.test(n)],
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

function heading(name) {
  const lang = currentLang();
  const pick = (l) => (labels[l] ? (/^ff_/.test(name) ? labels[l].featureName[camel(name)] : labels[l].labels[name]) : undefined);
  return pick(lang) || pick("en") || pick("he") || name;
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
  const set = async (name, value) => {
    try { apply(await call("config.set", { name, value: String(value) })); toast(t("config.saved", { v: version }), "ok"); render(); } catch (e) { toastError(e); }
  };

  const row = (p) => {
    const isFlag = /^ff_/.test(p.name);
    let control;
    if (isFlag) control = chips([["0", t("config.flags.0")], ["1", t("config.flags.1")], ["2", t("config.flags.2")], ["3", t("config.flags.3")]], p.value, (v) => set(p.name, v));
    else if (p.valueType === "BOOLEAN") control = toggle(p.value === "true", (on) => set(p.name, on ? "true" : "false"));
    else if (p.valueType === "JSON") {
      const area = textarea({ value: p.value, style: { direction: "ltr", fontFamily: "ui-monospace, Menlo, monospace", fontSize: "12.5px" } });
      control = h("div.stack", area, h("div.row", button(t("common.save"), { kind: "small primary", onclick: () => { try { JSON.parse(area.value); } catch (_) { toast(t("common.invalidJson"), "error"); return; } set(p.name, area.value); } })));
    } else {
      const ctl = input({ value: p.value, type: p.valueType === "NUMBER" ? "number" : "text", step: "any", style: { direction: "ltr" } });
      const save = button("✓", { kind: "small primary", onclick: () => { if (ctl.value !== p.value) set(p.name, ctl.value); } });
      ctl.addEventListener("keydown", (e) => { if (e.key === "Enter") save.click(); });
      control = h("div.row", h("div.grow", ctl), save);
    }
    return h("div.card", h("div.row.between", h("div", h("h3", heading(p.name)), h("div.small.muted.mono", p.name, p.group ? ` · ${p.group}` : "")), button("✕", { kind: "ghost small", title: t("config.delete"), onclick: async () => {
      if (!(await confirmDialog({ title: t("config.delete"), text: `${t("config.confirmDelete", { name: p.name })} ${t("config.deleteHint")}` }))) return;
      try { apply(await call("config.delete", { name: p.name })); toast(t("common.deleted"), "ok"); render(); } catch (e) { toastError(e); }
    } })), p.description ? h("p.small.muted", p.description) : null, control);
  };

  const render = () => {
    clear(body);
    const inGroup = search ? params : params.filter((p) => { const g = GROUPS.find(([, test]) => test(p.name)); return g && g[0] === group; });
    let rows = inGroup;
    if (search) rows = rows.filter((p) => [p.name, p.description, heading(p.name), p.value].some((v) => String(v || "").toLowerCase().includes(search)));
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
      try { apply(await call("config.add", { name: name.value.trim(), valueType: type.value, value: value.value, description: description.value.trim(), group: groupCtl.value.trim() })); toast(t("config.saved", { v: version }), "ok"); c(); render(); } catch (e) { toastError(e); }
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
