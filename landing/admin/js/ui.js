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

// Only an https picture from this project's own Storage bucket (either name,
// either URL form) or a Google account photo (lhN.googleusercontent.com) is
// loaded — the app's AuthorRow.trustedPhotoUrl and the rules'
// trustedPhotoUrl (firestore.rules). A profile's photoUrl is whatever its
// owner wrote; another bucket or a *.googleusercontent.com proxy can be a
// server whose owner reads who looked, and older documents still hold them.
const TRUSTED_PHOTO = /^https:\/\/(firebasestorage\.googleapis\.com\/v0\/b\/easy-plate\.(firebasestorage\.app|appspot\.com)\/o\/|storage\.googleapis\.com\/easy-plate\.(firebasestorage\.app|appspot\.com)\/|lh[0-9]+\.googleusercontent\.com\/)/;
export function trustedPhotoUrl(url) {
  const raw = String(url || "");
  if (raw.length > 2048 || !TRUSTED_PHOTO.test(raw)) return null;
  try {
    return new URL(raw).href;
  } catch (_) {
    return null;
  }
}

export function avatar(name, rawUrl, size = "") {
  const url = trustedPhotoUrl(rawUrl);
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
      wrap.append(h(`button.chip${String(v) === String(value) ? ".on" : ""}`, { type: "button", "aria-pressed": String(String(v) === String(value)), onclick: () => { value = v; render(); onChange(v); } }, label));
    }
  };
  render();
  return wrap;
}

export function multiChips(options, selected, onChange) {
  const set = new Set(selected || []);
  const wrap = h("div.chips");
  for (const [v, label] of options) {
    const btn = h(`button.chip${set.has(v) ? ".on" : ""}`, { type: "button", "aria-pressed": String(set.has(v)) }, label);
    btn.addEventListener("click", () => {
      if (set.has(v)) set.delete(v);
      else set.add(v);
      btn.classList.toggle("on", set.has(v));
      btn.setAttribute("aria-pressed", String(set.has(v)));
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

// A column with `sort` (a key) gets a clickable heading when `onSort` is
// given: `sort` ({key, dir: "asc"|"desc"}) marks the active one with an
// arrow, and a click hands the key back to the caller, which reorders.
export function table(columns, rows, { onRow, emptyText, sort = null, onSort = null } = {}) {
  if (!rows.length) return empty(emptyText);
  const heading = (c) => {
    if (!c.sort || !onSort) return h(`th${c.num ? ".num" : ""}`, c.label);
    const active = sort && sort.key === c.sort;
    const th = h(`th.sortable${c.num ? ".num" : ""}${active ? ".sorted" : ""}`, { "aria-sort": active ? (sort.dir === "asc" ? "ascending" : "descending") : "none", tabIndex: 0 },
      h("span", c.label), h("span.sort-arrow", active ? (sort.dir === "asc" ? "▲" : "▼") : "↕"));
    th.addEventListener("click", () => onSort(c.sort));
    th.addEventListener("keydown", (e) => { if (e.key === "Enter" || e.key === " ") { e.preventDefault(); onSort(c.sort); } });
    return th;
  };
  const thead = h("thead", h("tr", columns.map(heading)));
  const tbody = h("tbody");
  for (const row of rows) {
    const tr = h(`tr${onRow ? ".clickable" : ""}`, columns.map((c) => h(`td${c.num ? ".num" : ""}${c.cls ? "." + c.cls : ""}`, c.cell(row))));
    if (onRow) {
      tr.addEventListener("click", (e) => { if (!e.target.closest("button, a, input, select")) onRow(row); });
      // Reachable from the keyboard too: Tab to the row, Enter or Space opens it.
      tr.tabIndex = 0;
      tr.addEventListener("keydown", (e) => {
        if ((e.key === "Enter" || e.key === " ") && e.target === tr) {
          e.preventDefault();
          onRow(row);
        }
      });
    }
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

const FOCUSABLE = 'a[href], button:not([disabled]), input:not([disabled]):not([type="hidden"]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])';

// Escape and Tab belong to the dialog on top; one underneath waits its turn.
function onTop(back) {
  return modals().lastElementChild === back;
}

let modalSeq = 0;
export function modal({ title, body, actions = [], wide = false, onClose }) {
  const back = h("div.modal-back");
  const titleId = `modal-title-${++modalSeq}`;
  const box = h(`div.modal${wide ? ".wide" : ""}`, { role: "dialog", "aria-modal": "true", "aria-labelledby": titleId, tabindex: "-1" });
  // Focus goes back where it came from when the dialog closes.
  const opener = document.activeElement;
  let closed = false;
  const close = () => {
    if (closed) return;
    closed = true;
    back.remove();
    document.removeEventListener("keydown", onKey);
    if (opener && typeof opener.focus === "function" && document.contains(opener)) opener.focus();
    if (onClose) onClose();
  };
  const onKey = (e) => {
    if (!onTop(back)) return;
    if (e.key === "Escape") { e.preventDefault(); close(); return; }
    if (e.key !== "Tab") return;
    // Tab cycles inside the dialog instead of escaping to the page behind.
    const items = [...box.querySelectorAll(FOCUSABLE)].filter((el) => !el.hidden && el.offsetParent !== null);
    if (!items.length) { e.preventDefault(); box.focus(); return; }
    const first = items[0], last = items[items.length - 1];
    if (e.shiftKey && (document.activeElement === first || !box.contains(document.activeElement))) { e.preventDefault(); last.focus(); }
    else if (!e.shiftKey && (document.activeElement === last || !box.contains(document.activeElement))) { e.preventDefault(); first.focus(); }
  };
  document.addEventListener("keydown", onKey);
  back.addEventListener("click", (e) => { if (e.target === back) close(); });
  box.append(h("div.row.between", h("h2", { id: titleId }, title), button("✕", { kind: "ghost icon", onclick: close, "aria-label": t("common.close") })));
  box.append(typeof body === "function" ? body(close) : body);
  if (actions.length) box.append(h("div.actions", actions.map((a) => (typeof a === "function" ? a(close) : a))));
  back.append(box);
  modals().append(back);
  const first = box.querySelector("input, textarea, select, button.primary");
  setTimeout(() => { if (!closed) (first || box).focus(); }, 30);
  return close;
}

export function confirmDialog({ title, text, danger = true, okLabel }) {
  return new Promise((resolve) => {
    const close = modal({
      title,
      body: h("div.stack", text ? h("p", text) : null, danger ? h("p.small.warn", t("common.irreversible")) : null),
      actions: [
        button(t("common.cancel"), { onclick: () => { resolve(false); close(); } }),
        // Settle before closing: close() fires onClose, and a promise keeps
        // its first value — the other order answered "cancel" to every OK.
        button(okLabel || (danger ? t("common.yesDelete") : t("common.confirm")), { kind: danger ? "danger" : "primary", onclick: () => { resolve(true); close(); } }),
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
  const wrap = h("div.tabs", { role: "tablist" });
  const render = () => {
    clear(wrap);
    for (const [key, label] of items) wrap.append(h(`button${key === active ? ".active" : ""}`, { type: "button", role: "tab", "aria-selected": String(key === active), onclick: () => { active = key; render(); onChange(key); } }, label));
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

// ---- emoji picker ----
// A small button in the corner of a text field that opens a grid of
// emoji, by group; a pick goes in at the caret (replacing a selection),
// within the field's maxLength. The panel is fixed-positioned on the
// page so a scrolling dialog does not clip it; Escape or a click outside
// closes it (Escape does not close the dialog behind it).
// One line per emoji: the emoji, then the words a search finds it by
// (English and Hebrew). A group is [tab icon, lines].
const EMOJI = [
  ["😀", `😀 smile grin happy חיוך שמח
😃 smile happy joy חיוך שמח
😄 smile laugh happy חיוך צחוק שמח
😁 grin beam teeth חיוך שיניים
😆 laugh lol צחוק
😅 sweat laugh relief צחוק הקלה זיעה
😂 tears joy laugh lol צחוק דמעות
🤣 rofl laugh lol צחוק מתגלגל
😊 blush smile happy חיוך סמוק
😇 angel innocent halo מלאך תמים
🙂 smile slight חיוך
😉 wink קריצה
😍 love heart eyes אהבה מאוהב לב
🥰 love hearts adore אהבה לבבות
😘 kiss love נשיקה
😋 yum tasty delicious טעים יאמי
😛 tongue לשון
😜 wink tongue crazy לשון קריצה
🤪 crazy zany silly משוגע מטורף
😎 cool sunglasses מגניב משקפיים
🤩 star struck wow מדהים כוכבים
🥳 party celebrate birthday מסיבה חגיגה יום הולדת
😏 smirk חיוך ערמומי
🤗 hug hugs חיבוק
🤔 think thinking hmm חושב מתלבט
🤭 oops giggle אופס
😶 speechless silent שותק
🙄 eye roll גלגול עיניים
😴 sleep tired שינה עייף
😮 wow surprised open mouth וואו מופתע
😲 shocked astonished המום
🥺 pleading please puppy בבקשה מתחנן
😢 sad cry tear עצוב דמעה
😭 crying sob בוכה
😤 huff frustrated עצבני
😡 angry mad כועס
🤯 mind blown מפוצץ
😱 scream scared fear צרחה מפחד
🤤 drool hungry ריור רעב
😷 sick mask חולה מסכה`],
  ["👍", `👍 like thumbs up yes ok לייק אגודל כן
👎 dislike thumbs down no דיסלייק לא
👌 ok perfect אוקיי מושלם
✌️ peace victory שלום ניצחון
🤞 fingers crossed luck hope בהצלחה מחזיק אצבעות
🤟 love you אוהב
🤘 rock רוק
🤙 call me shaka תתקשר
👋 wave hello bye hi שלום היי ביי נפנוף
👏 clap applause bravo כפיים מחיאות כל הכבוד
🙌 hooray raise hands celebrate הידד יש
🫶 heart hands love לב ידיים אהבה
👐 open hands ידיים פתוחות
🤲 palms up ידיים
🙏 please thanks pray תודה בבקשה תפילה
💪 strong muscle power חזק שריר כוח
👆 up point למעלה
👇 down point למטה
👉 right point ימינה
👈 left point שמאלה
☝️ one point attention אחד שימו לב
✋ stop hand עצור
🤚 raised hand יד
🖐️ hand five יד
✍️ write writing כתיבה
🫡 salute הצדעה`],
  ["❤️", `❤️ red heart love לב אדום אהבה
🧡 orange heart לב כתום
💛 yellow heart לב צהוב
💚 green heart לב ירוק
💙 blue heart לב כחול
💜 purple heart לב סגול
🤍 white heart לב לבן
🖤 black heart לב שחור
🤎 brown heart לב חום
💖 sparkling heart לב נוצץ
💗 growing heart לב
💓 beating heart לב פועם
💞 hearts love לבבות
💕 two hearts love לבבות
💘 cupid heart arrow לב חץ
💝 heart gift ribbon לב מתנה
❣️ heart exclamation לב
💔 broken heart לב שבור
❤️‍🔥 heart fire לב בוער`],
  ["🍕", `🍏 green apple תפוח ירוק
🍎 apple red תפוח
🍊 orange תפוז
🍋 lemon לימון
🍌 banana בננה
🍉 watermelon אבטיח
🍇 grapes ענבים
🍓 strawberry תות
🫐 blueberries אוכמניות
🍒 cherries דובדבן
🍑 peach אפרסק
🥭 mango מנגו
🍍 pineapple אננס
🥥 coconut קוקוס
🥝 kiwi קיווי
🍅 tomato עגבניה
🥑 avocado אבוקדו
🥦 broccoli ברוקולי
🥬 lettuce leafy greens חסה עלים
🥒 cucumber מלפפון
🌶️ hot pepper chili spicy פלפל חריף
🫑 bell pepper פלפל
🌽 corn תירס
🥕 carrot גזר
🧄 garlic שום
🧅 onion בצל
🥔 potato תפוח אדמה
🍠 sweet potato בטטה
🥐 croissant קרואסון
🥖 baguette bread באגט לחם
🍞 bread לחם
🥨 pretzel בייגלה
🧀 cheese גבינה
🥚 egg ביצה
🍳 cooking fried egg pan בישול ביצה מחבת
🥞 pancakes פנקייק
🧇 waffle וופל
🥓 bacon בייקון
🥩 meat steak בשר סטייק
🍗 chicken leg עוף
🍖 meat bone בשר
🌭 hot dog נקניקיה
🍔 burger hamburger המבורגר
🍟 fries צ'יפס
🍕 pizza פיצה
🥪 sandwich כריך סנדוויץ'
🌮 taco טאקו
🌯 burrito wrap בוריטו טורטיה
🥗 salad סלט
🥘 pan stew paella תבשיל
🍝 pasta spaghetti פסטה ספגטי
🍜 noodles ramen soup נודלס ראמן מרק
🍲 pot stew soup סיר מרק תבשיל
🍛 curry rice קארי
🍣 sushi סושי
🍱 bento box בנטו
🥟 dumpling כיסון
🍤 shrimp שרימפס
🍚 rice אורז
🍰 cake slice עוגה
🎂 birthday cake עוגת יום הולדת
🧁 cupcake קאפקייק
🥧 pie פאי
🍫 chocolate שוקולד
🍬 candy ממתק סוכריה
🍩 donut סופגניה דונאט
🍪 cookie עוגיה
🍯 honey דבש
☕ coffee קפה
🍵 tea תה
🥤 drink cup שתיה
🍷 wine יין
🥂 cheers toast לחיים
🍽️ plate dinner meal צלחת ארוחה
🥄 spoon כף
🔪 knife סכין`],
  ["🎉", `🎉 party tada celebrate מסיבה חגיגה
🎊 confetti קונפטי
🎈 balloon בלון
🎁 gift present מתנה
🎀 ribbon bow סרט
🏆 trophy win גביע ניצחון
🥇 first gold medal מקום ראשון מדליה
⭐ star כוכב
🌟 glowing star כוכב
✨ sparkles new נצנצים
💫 dizzy star כוכב
🔥 fire hot lit אש חם
💥 boom collision בום
🎯 target goal מטרה
🚀 rocket launch new רקטה השקה
📣 megaphone announce כרוז הודעה
📢 loudspeaker announcement רמקול הכרזה
🔔 bell notification פעמון התראה
🛒 cart shopping grocery עגלה קניות
🛍️ shopping bags קניות
📅 calendar date יומן תאריך
⏰ alarm clock time שעון מעורר
⏳ hourglass wait שעון חול המתנה
📱 phone mobile app טלפון אפליקציה
💡 idea tip רעיון טיפ
📌 pin נעץ
📝 note memo פתק
📖 book recipe ספר מתכון`],
  ["✅", `✅ check done yes וי בוצע
☑️ checkbox תיבה
✔️ check mark וי
❌ cross no wrong איקס לא
⚠️ warning attention אזהרה שימו לב
❗ exclamation important חשוב
❓ question שאלה
💯 hundred perfect מאה מושלם
🆕 new חדש
🆓 free חינם
🔝 top למעלה
➡️ right arrow חץ ימינה
⬅️ left arrow חץ שמאלה
⬆️ up arrow חץ למעלה
⬇️ down arrow חץ למטה
🔄 refresh update רענון עדכון
➕ plus add פלוס
➖ minus מינוס
💲 dollar price מחיר
💰 money כסף
🟢 green circle עיגול ירוק
🟡 yellow circle עיגול צהוב
🔴 red circle עיגול אדום
🔵 blue circle עיגול כחול
🟣 purple circle עיגול סגול`],
].map(([icon, lines]) => [icon, lines.split("\n").map((line) => {
  const [emoji, ...words] = line.trim().split(" ");
  return { emoji, words: words.join(" ").toLowerCase() };
})]);

export function insertAtCaret(field, text) {
  const max = field.maxLength > 0 ? field.maxLength : Infinity;
  const start = field.selectionStart ?? field.value.length;
  const end = field.selectionEnd ?? field.value.length;
  if (field.value.length - (end - start) + text.length > max) return false;
  field.value = field.value.slice(0, start) + text + field.value.slice(end);
  const at = start + text.length;
  field.focus();
  field.setSelectionRange(at, at);
  field.dispatchEvent(new Event("input", { bubbles: true }));
  return true;
}

export function withEmoji(field) {
  let panel = null;
  const trigger = h("button.emoji-btn", { type: "button", "aria-label": t("common.emoji"), title: t("common.emoji"), "aria-haspopup": "true", "aria-expanded": "false" }, "🙂");
  const close = () => {
    if (!panel) return;
    panel.remove();
    panel = null;
    trigger.setAttribute("aria-expanded", "false");
    document.removeEventListener("mousedown", outside, true);
    document.removeEventListener("keydown", onKey, true);
  };
  const outside = (e) => { if (panel && !panel.contains(e.target) && e.target !== trigger) close(); };
  const onKey = (e) => { if (e.key === "Escape") { e.preventDefault(); e.stopPropagation(); close(); trigger.focus(); } };
  const open = () => {
    let group = 0;
    panel = h("div.emoji-panel", { role: "dialog", "aria-label": t("common.emoji") });
    const search = h("input.emoji-search", { type: "search", placeholder: t("common.emojiSearch"), "aria-label": t("common.emojiSearch") });
    const tabs = h("div.emoji-tabs");
    const grid = h("div.emoji-grid");
    const cell = (e) => h("button.emoji-cell", { type: "button", title: e.words.split(" ").slice(0, 3).join(" "), onclick: () => { if (!insertAtCaret(field, e.emoji)) toast(t("common.tooLong"), "error"); } }, e.emoji);
    // A search looks across every group (each word of the query must start
    // a keyword); an empty one shows the picked group's tab.
    const paint = () => {
      clear(tabs); clear(grid);
      const q = search.value.trim().toLowerCase().split(/\s+/).filter(Boolean);
      tabs.hidden = q.length > 0;
      EMOJI.forEach(([icon], i) => tabs.append(h(`button.emoji-tab${i === group ? ".on" : ""}`, { type: "button", onclick: () => { group = i; paint(); } }, icon)));
      const list = q.length
        ? EMOJI.flatMap(([, items]) => items).filter((e) => q.every((w) => (" " + e.words).includes(" " + w)))
        : EMOJI[group][1];
      if (!list.length) grid.append(h("div.small.muted.emoji-none", t("common.nothingFound")));
      for (const e of list) grid.append(cell(e));
    };
    search.addEventListener("input", paint);
    // Enter puts in the first match.
    search.addEventListener("keydown", (e) => { if (e.key === "Enter") { e.preventDefault(); grid.querySelector(".emoji-cell")?.click(); } });
    paint();
    panel.append(search, tabs, grid);
    document.body.append(panel);
    // Under the button, kept on screen (16px gutter).
    const r = trigger.getBoundingClientRect();
    const w = panel.offsetWidth, ph = panel.offsetHeight;
    const left = Math.min(Math.max(16, r.right - w), window.innerWidth - w - 16);
    const top = r.bottom + 6 + ph > window.innerHeight - 16 ? Math.max(16, r.top - 6 - ph) : r.bottom + 6;
    Object.assign(panel.style, { left: `${left}px`, top: `${top}px` });
    trigger.setAttribute("aria-expanded", "true");
    search.focus();
    document.addEventListener("mousedown", outside, true);
    document.addEventListener("keydown", onKey, true);
  };
  // Keep the caret where it was: the button must not take focus on press.
  trigger.addEventListener("mousedown", (e) => e.preventDefault());
  trigger.addEventListener("click", () => (panel ? close() : open()));
  const wrap = h(`div.emoji-wrap${field.tagName === "TEXTAREA" ? ".area" : ""}`, field, trigger);
  // The panel is on <body>: remove it with the dialog.
  new MutationObserver((_, obs) => { if (!document.contains(wrap)) { close(); obs.disconnect(); } }).observe(document.body, { childList: true, subtree: true });
  return wrap;
}
