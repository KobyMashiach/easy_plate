// DOM helpers the views are built from: an element builder, modals,
// toasts, a confirm dialog and the few widgets every page repeats.
import { t, fmtAgo, fmtDate } from "./i18n.js";

// h("div.card", {onclick, title}, child, child…) — classes from the tag,
// attributes from the object, children as strings or nodes.
export function h(tag, attrs, ...children) {
  if (attrs !== null && typeof attrs === "object" && !(attrs instanceof Node) && !Array.isArray(attrs)) {
    // attrs given
  } else {
    children.unshift(attrs);
    attrs = {};
  }
  const [name, ...classes] = tag.split(".");
  const el = document.createElement(name || "div");
  if (classes.length) el.className = classes.join(" ");
  for (const [key, value] of Object.entries(attrs || {})) {
    if (value === undefined || value === null || value === false) continue;
    if (key === "class") el.className += (el.className ? " " : "") + value;
    else if (key === "style" && typeof value === "object") Object.assign(el.style, value);
    else if (key === "dataset") Object.assign(el.dataset, value);
    else if (key.startsWith("on") && typeof value === "function") el.addEventListener(key.slice(2).toLowerCase(), value);
    else if (key === "html") el.innerHTML = value;
    else if (key in el && typeof value !== "string") el[key] = value;
    else el.setAttribute(key, value === true ? "" : String(value));
  }
  append(el, children);
  return el;
}

export function append(el, children) {
  for (const child of children.flat(Infinity)) {
    if (child === null || child === undefined || child === false) continue;
    el.append(child instanceof Node ? child : document.createTextNode(String(child)));
  }
  return el;
}

export function clear(el) {
  while (el.firstChild) el.removeChild(el.firstChild);
  return el;
}

export function spinner() {
  return h("div.center", h("span.spinner"));
}

export function empty(text) {
  return h("div.empty", text || t("common.none"));
}

export function badge(text, color) {
  return h(`span.badge${color ? "." + color : ""}`, text);
}

export function dot(on) {
  return h(`span.dot${on ? ".on" : ""}`, { title: on ? t("users.online") : t("users.offline") });
}

export function initials(name) {
  const parts = String(name || "").trim().split(/\s+/).filter(Boolean);
  if (!parts.length) return "?";
  return (parts[0][0] + (parts[1] ? parts[1][0] : "")).toUpperCase();
}

export function avatar(name, url, size = "") {
  if (url) return h(`img.avatar${size ? "." + size : ""}`, { src: url, alt: "", loading: "lazy", referrerpolicy: "no-referrer", onerror: (e) => e.target.replaceWith(avatar(name, null, size)) });
  return h(`span.avatar${size ? "." + size : ""}`, initials(name));
}

export function when(d) {
  return h("span", { title: fmtDate(d) }, fmtAgo(d));
}

export function field(label, control, hint) {
  return h("div.field", h("label", label), control, hint ? h("span.small.muted", hint) : null);
}

export function input(attrs = {}) {
  return h("input.input", { type: "text", ...attrs });
}

export function textarea(attrs = {}) {
  return h("textarea.textarea", attrs);
}

export function select(options, attrs = {}) {
  const el = h("select.select", attrs);
  for (const option of options) {
    const [value, label] = Array.isArray(option) ? option : [option, option];
    el.append(h("option", { value, selected: attrs.value !== undefined && String(attrs.value) === String(value) }, label));
  }
  return el;
}

export function toggle(on, onChange) {
  const el = h(`button.switch${on ? ".on" : ""}`, { type: "button", role: "switch", "aria-checked": String(!!on) });
  el.addEventListener("click", () => {
    const next = !el.classList.contains("on");
    el.classList.toggle("on", next);
    el.setAttribute("aria-checked", String(next));
    onChange(next);
  });
  return el;
}

export function chips(options, value, onChange) {
  const wrap = h("div.chips");
  const render = () => {
    clear(wrap);
    for (const [v, label] of options) {
      wrap.append(h(`button.chip${String(v) === String(value) ? ".on" : ""}`, { type: "button", onclick: () => { value = v; render(); onChange(v); } }, label));
    }
  };
  render();
  return wrap;
}

export function multiChips(options, selected, onChange) {
  const set = new Set(selected || []);
  const wrap = h("div.chips");
  for (const [v, label] of options) {
    const btn = h(`button.chip${set.has(v) ? ".on" : ""}`, { type: "button" }, label);
    btn.addEventListener("click", () => {
      if (set.has(v)) set.delete(v);
      else set.add(v);
      btn.classList.toggle("on", set.has(v));
      onChange([...set]);
    });
    wrap.append(btn);
  }
  return wrap;
}

export function button(label, attrs = {}) {
  const { kind = "", ...rest } = attrs;
  return h(`button.btn${kind ? "." + kind.split(" ").join(".") : ""}`, { type: "button", ...rest }, label);
}

// Runs `fn` with the button disabled and a spinner in it.
export function busy(btn, fn) {
  return async (...args) => {
    if (btn.disabled) return;
    const label = btn.textContent;
    btn.disabled = true;
    btn.textContent = t("common.working");
    try {
      return await fn(...args);
    } finally {
      btn.disabled = false;
      btn.textContent = label;
    }
  };
}

export function table(columns, rows, { onRow, emptyText } = {}) {
  if (!rows.length) return empty(emptyText);
  const thead = h("thead", h("tr", columns.map((c) => h(`th${c.num ? ".num" : ""}`, c.label))));
  const tbody = h("tbody");
  for (const row of rows) {
    const tr = h(`tr${onRow ? ".clickable" : ""}`, columns.map((c) => h(`td${c.num ? ".num" : ""}${c.cls ? "." + c.cls : ""}`, c.cell(row))));
    if (onRow) tr.addEventListener("click", (e) => { if (!e.target.closest("button, a, input, select")) onRow(row); });
    tbody.append(tr);
  }
  return h("div.table-wrap", h("table", thead, tbody));
}

export function kv(pairs) {
  const dl = h("dl.kv");
  // A row that does not apply is passed as undefined (or null) and skipped.
  for (const pair of pairs) {
    if (!Array.isArray(pair)) continue;
    const [k, v] = pair;
    if (v === undefined) continue;
    dl.append(h("dt", k), h("dd", v === null || v === "" ? "—" : v));
  }
  return dl;
}

// ---- modals ----
const modals = () => document.getElementById("modals");

export function modal({ title, body, actions = [], wide = false, onClose }) {
  const back = h("div.modal-back");
  const box = h(`div.modal${wide ? ".wide" : ""}`, { role: "dialog", "aria-modal": "true" });
  const close = () => {
    back.remove();
    document.removeEventListener("keydown", onKey);
    if (onClose) onClose();
  };
  const onKey = (e) => { if (e.key === "Escape") close(); };
  document.addEventListener("keydown", onKey);
  back.addEventListener("click", (e) => { if (e.target === back) close(); });
  box.append(h("div.row.between", h("h2", title), button("✕", { kind: "ghost icon", onclick: close, "aria-label": t("common.close") })));
  box.append(typeof body === "function" ? body(close) : body);
  if (actions.length) box.append(h("div.actions", actions.map((a) => (typeof a === "function" ? a(close) : a))));
  back.append(box);
  modals().append(back);
  const first = box.querySelector("input, textarea, select, button.primary");
  if (first) setTimeout(() => first.focus(), 30);
  return close;
}

export function confirmDialog({ title, text, danger = true, okLabel }) {
  return new Promise((resolve) => {
    const close = modal({
      title,
      body: h("div.stack", text ? h("p", text) : null, danger ? h("p.small.warn", t("common.irreversible")) : null),
      actions: [
        button(t("common.cancel"), { onclick: () => { close(); resolve(false); } }),
        button(okLabel || (danger ? t("common.yesDelete") : t("common.confirm")), { kind: danger ? "danger" : "primary", onclick: () => { close(); resolve(true); } }),
      ],
      onClose: () => resolve(false),
    });
  });
}

export function promptDialog({ title, label, multiline = false, value = "", placeholder = "", okLabel, extra }) {
  return new Promise((resolve) => {
    const ctl = multiline ? textarea({ value, placeholder }) : input({ value, placeholder });
    let done = false;
    const close = modal({
      title,
      body: h("div.stack", field(label, ctl), extra || null),
      actions: [
        button(t("common.cancel"), { onclick: () => close() }),
        button(okLabel || t("common.confirm"), { kind: "primary", onclick: () => { done = true; close(); resolve(ctl.value.trim()); } }),
      ],
      onClose: () => { if (!done) resolve(null); },
    });
    if (!multiline) ctl.addEventListener("keydown", (e) => { if (e.key === "Enter") { done = true; close(); resolve(ctl.value.trim()); } });
  });
}

// ---- toasts ----
export function toast(text, kind = "") {
  const el = h(`div.toast${kind ? "." + kind : ""}`, text);
  document.getElementById("toasts").append(el);
  setTimeout(() => el.remove(), kind === "error" ? 7000 : 3500);
}

export function toastError(err) {
  console.error(err);
  toast(err && err.message ? t("err.generic", { message: err.message }) : t("common.error"), "error");
}

// ---- small bits ----
export function bars(points, { label, max } = {}) {
  const top = max || Math.max(1, ...points.map((p) => p.value));
  return h("div.bars", points.map((p) => h("div.bar", { style: { height: `${Math.max(2, (p.value / top) * 100)}%` }, "data-tip": `${p.label}: ${label ? label(p.value) : p.value}` })));
}

export function hbars(entries, fmt) {
  const top = Math.max(1, ...entries.map(([, v]) => v));
  return h("div", entries.map(([k, v]) => h("div.hbar", h("span.ellipsis", { title: k }, k || "—"), h("div.track", h("div.fill", { style: { width: `${(v / top) * 100}%` } })), h("span.n", fmt ? fmt(v) : v))));
}

export function tabs(items, active, onChange) {
  const wrap = h("div.tabs");
  const render = () => {
    clear(wrap);
    for (const [key, label] of items) wrap.append(h(`button${key === active ? ".active" : ""}`, { type: "button", onclick: () => { active = key; render(); onChange(key); } }, label));
  };
  render();
  return wrap;
}

export function debounce(fn, ms = 200) {
  let timer;
  return (...args) => {
    clearTimeout(timer);
    timer = setTimeout(() => fn(...args), ms);
  };
}

export function copyText(text) {
  navigator.clipboard?.writeText(text).then(() => toast(t("common.copied"), "ok")).catch(() => {});
}
