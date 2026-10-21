// The administrator's notifications: everything sent (to everyone or to one
// account, from here, from the app's dashboard or by a template's schedule)
// and the templates that send on their own. Both lists are live Firestore
// listeners; every write goes through adminPanel (adminNotifications.js),
// which also works out when a template runs next, in Israel time.
import { db, collection, onSnapshot, query, orderBy, limit, getDocs } from "../firebase.js";
import { t, fmtNumber, fmtDate } from "../i18n.js";
import { h, clear, badge, when, button, busy, chips, input, textarea, select, toggle, field, modal, confirmDialog, toast, toastError, empty, debounce } from "../ui.js";
import { call } from "../api.js";

const KINDS = ["manual", "once", "daily", "weekly", "monthly"];
const SOURCE_COLORS = { console: "brand", app: "mint", template: "amber", schedule: "green" };

// The audience picker (it has its own search box). The same ceiling as the
// users page: one read of at most 5000 accounts, once per visit.
async function loadUsers() {
  const snap = await getDocs(query(collection(db, "users"), limit(5000)));
  return snap.docs
    .map((d) => ({ uid: d.id, name: d.get("fullName") || d.get("email") || d.get("phoneNumber") || d.id }))
    .filter((u) => !u.uid.startsWith("seed_"))
    .sort((a, b) => a.name.localeCompare(b.name));
}

// One user is just a picked list of one, so there is no separate choice;
// older rows and templates aimed at "user" still show and open as a list.
const TARGETS = ["all", "premium", "free", "users"];

// "Send to": everyone, Premium, free, a picked list, or one user. Returns the
// control and a read-out of what it is set to.
function audienceControl(users, { target = "all", uid = "", uids = [] } = {}) {
  const kind = select(TARGETS.map((k) => [k, t(`notif.targets.${k}`)]), { value: target === "user" ? "users" : target });
  const picked = new Set(target === "user" && uid ? [uid] : uids || []);
  const count = h("span.small.muted");
  const search = input({ placeholder: t("common.search") });
  const list = h("div.stack", { style: { maxHeight: "220px", overflowY: "auto", gap: "2px", border: "1px solid var(--line, rgba(127,127,127,.25))", borderRadius: "8px", padding: "6px 8px" } });
  const paint = () => {
    clear(list);
    const q = search.value.trim().toLowerCase();
    for (const u of users) {
      if (q && !u.name.toLowerCase().includes(q) && !u.uid.toLowerCase().includes(q)) continue;
      const box = h("input", { type: "checkbox", checked: picked.has(u.uid) });
      box.addEventListener("change", () => { if (box.checked) picked.add(u.uid); else picked.delete(u.uid); count.textContent = t("notif.pickedCount", { n: picked.size }); });
      list.append(h("label.row", { style: { gap: "6px" } }, box, u.name));
    }
    count.textContent = t("notif.pickedCount", { n: picked.size });
  };
  search.addEventListener("input", paint);
  paint();
  const manyField = field(t("notif.users"), h("div.stack", search, list, count));

  const sync = () => { manyField.hidden = kind.value !== "users"; };
  kind.addEventListener("change", sync);
  sync();
  return {
    el: h("div.stack", field(t("notif.target"), kind), manyField),
    value: () => ({ target: kind.value, uid: null, uids: kind.value === "users" ? [...picked] : null }),
    check() {
      if (kind.value === "users" && !picked.size) return t("notif.pickUsers");
      return null;
    },
  };
}

// "Every Sunday and Tuesday at 08:00", in the console's language.
function describe(schedule) {
  const s = schedule || { kind: "manual" };
  if (s.kind === "manual") return t("notif.kinds.manual");
  if (s.kind === "once") return t("notif.describe.once", { date: fmtDate(new Date(s.at)) });
  if (s.kind === "daily") return t("notif.describe.daily", { time: s.time });
  if (s.kind === "weekly") return t("notif.describe.weekly", { days: (s.weekdays || []).map((d) => t(`notif.days.${d}`)).join(", "), time: s.time });
  return t("notif.describe.monthly", { day: s.dayOfMonth, time: s.time });
}

// A datetime-local value for an instant, in the browser's own zone.
function localInputValue(ms) {
  const d = new Date(ms - new Date(ms).getTimezoneOffset() * 60000);
  return d.toISOString().slice(0, 16);
}

export async function mount({ view, actions }) {
  let tab = "sent", sent = [], templates = [], users = null, target = "all", search = "";
  const nameOf = (uid) => (users && users.find((u) => u.uid === uid)?.name) || uid;
  const ensureUsers = async () => (users ||= await loadUsers());

  const body = h("div.stack");
  const toolbar = h("div.toolbar");
  view.append(toolbar, body);

  // ---- compose / edit ------------------------------------------------------



  async function sendNow() {
    const audience = audienceControl(await ensureUsers());
    const titleCtl = input({ maxLength: 80 });
    const text = textarea({ rows: 4, maxLength: 1000 });
    modal({
      title: t("notif.sendNow"),
      body: h("div.stack", audience.el, field(t("common.title"), titleCtl), field(t("common.body"), text)),
      actions: [(c) => button(t("common.cancel"), { onclick: c }), (c) => {
        const b = button(t("common.send"), { kind: "primary" });
        b.addEventListener("click", busy(b, async () => {
          const message = text.value.trim();
          if (!message) return toast(t("notif.needBody"), "error");
          const problem = audience.check();
          if (problem) return toast(problem, "error");
          const { target, uids } = audience.value();
          if (!(await confirmDialog({ title: t("notif.sendNow"), text: audienceText({ target, uids }), danger: false }))) return;
          try {
            const r = await call("user.notifyAudience", { audience: target, ...(uids ? { uids } : {}), title: titleCtl.value.trim(), body: message });
            toast(t("users.broadcastSent", { items: r.items, sent: r.sent, failed: r.failed }), "ok");
            c();
          } catch (e) { toastError(e); }
        }));
        return b;
      }],
    });
  }

  async function editTemplate(tpl) {
    const s = (tpl && tpl.schedule) || { kind: "manual" };
    const nameCtl = input({ value: tpl?.name || "", maxLength: 80 });
    const titleCtl = input({ value: tpl?.title || "", maxLength: 80 });
    const text = textarea({ rows: 4, maxLength: 1000, value: tpl?.body || "" });
    const audience = audienceControl(await ensureUsers(), { target: tpl?.target || "all", uid: tpl?.uid, uids: tpl?.uids });
    const kindCtl = select(KINDS.map((k) => [k, t(`notif.kinds.${k}`)]), { value: s.kind });
    const atCtl = input({ type: "datetime-local", dir: "ltr", value: s.at ? localInputValue(s.at) : localInputValue(Date.now() + 3600000) });
    const timeCtl = input({ type: "time", dir: "ltr", value: s.time || "09:00" });
    const dayCtl = input({ type: "number", min: 1, max: 31, dir: "ltr", value: s.dayOfMonth || 1 });
    const chosen = new Set(s.weekdays || [0]);
    const dayBoxes = h("div.row", [0, 1, 2, 3, 4, 5, 6].map((d) => {
      const box = h("input", { type: "checkbox", checked: chosen.has(d) });
      box.addEventListener("change", () => { if (box.checked) chosen.add(d); else chosen.delete(d); });
      return h("label.row", { style: { gap: "4px" } }, box, t(`notif.days.${d}`));
    }));
    let enabled = tpl ? tpl.enabled !== false : true;
    const enabledCtl = toggle(enabled, (v) => { enabled = v; });
    // A one-off is an instant picked on this browser's clock; only the
    // repeating times are Israel wall-clock times on the server.
    const atField = field(t("notif.at"), atCtl);
    const timeField = field(t("notif.time"), timeCtl, t("notif.israelTime"));
    const daysField = field(t("notif.weekdays"), dayBoxes);
    const dayField = field(t("notif.dayOfMonth"), dayCtl, t("notif.dayOfMonthHint"));
    const sync = () => {
      const k = kindCtl.value;
      atField.hidden = k !== "once";
      timeField.hidden = !["daily", "weekly", "monthly"].includes(k);
      daysField.hidden = k !== "weekly";
      dayField.hidden = k !== "monthly";
    };
    kindCtl.addEventListener("change", sync);
    sync();
    modal({
      title: tpl ? t("notif.editTemplate") : t("notif.newTemplate"),
      wide: true,
      body: h("div.stack",
        field(t("notif.name"), nameCtl, t("notif.nameHint")),
        audience.el,
        field(t("common.title"), titleCtl), field(t("common.body"), text),
        // When, the time and the day side by side; they wrap on a narrow
        // screen, and the weekday boxes take a line of their own.
        h("div.row", { style: { alignItems: "flex-start", flexWrap: "wrap", gap: "12px" } },
          ...[field(t("notif.when"), kindCtl), atField, timeField, dayField].map((f) => { f.style.flex = "1 1 160px"; f.style.minWidth = "0"; return f; })),
        daysField,
        h("div.field.inline", enabledCtl, h("label", t("notif.enabled"))),
      ),
      actions: [(c) => button(t("common.cancel"), { onclick: c }), (c) => {
        const b = button(t("common.save"), { kind: "primary" });
        b.addEventListener("click", busy(b, async () => {
          const kind = kindCtl.value;
          const schedule = { kind };
          if (kind === "once") schedule.at = new Date(atCtl.value).getTime();
          if (["daily", "weekly", "monthly"].includes(kind)) schedule.time = timeCtl.value;
          if (kind === "weekly") schedule.weekdays = [...chosen];
          if (kind === "monthly") schedule.dayOfMonth = Number(dayCtl.value);
          if (!text.value.trim()) return toast(t("notif.needBody"), "error");
          const problem = audience.check();
          if (problem) return toast(problem, "error");
          const { target, uid, uids } = audience.value();
          try {
            const r = await call("notify.template.save", {
              ...(tpl ? { id: tpl.id } : {}),
              name: nameCtl.value.trim(), title: titleCtl.value.trim(), body: text.value.trim(),
              target, ...(uid ? { uid } : {}), ...(uids ? { uids } : {}),
              schedule, enabled,
            });
            toast(r.nextRunAt ? t("notif.savedNext", { date: fmtDate(new Date(r.nextRunAt)) }) : t("notif.saved"), "ok");
            c();
          } catch (e) { toastError(e); }
        }));
        return b;
      }],
    });
  }

  async function runTemplate(tpl) {
    if (!(await confirmDialog({ title: t("notif.sendTemplateNow", { name: tpl.name || tpl.title }), text: audienceText(tpl), danger: false }))) return;
    try {
      await call("notify.template.send", { id: tpl.id });
      toast(t("notif.sentOne"), "ok");
    } catch (e) { toastError(e); }
  }

  async function setEnabled(tpl, on) {
    try {
      await call("notify.template.save", { id: tpl.id, name: tpl.name, title: tpl.title, body: tpl.body, target: tpl.target, uid: tpl.uid || undefined, uids: tpl.uids || undefined, schedule: tpl.schedule, enabled: on });
    } catch (e) { toastError(e); }
  }

  // ---- lists ---------------------------------------------------------------

  function sourceBadge(source) {
    const key = `notif.sources.${source}`;
    return badge(t(key) === key ? source : t(key), SOURCE_COLORS[source] || "");
  }

  // Who a send or a template reaches, as a badge (or a link for one user).
  function targetCell(row) {
    if (row.target === "user") return h("a", { href: `#/users/${row.uid}` }, row.targetName || nameOf(row.uid));
    if (row.target === "users" && (row.uids || []).length === 1) return h("a", { href: `#/users/${row.uids[0]}` }, nameOf(row.uids[0]));
    if (row.target === "users") {
      const names = (row.uids || []).map(nameOf);
      return h("span.badge", { title: names.join(", ") }, t("notif.usersCount", { n: names.length }));
    }
    return badge(t(`notif.targets.${row.target || "all"}`), row.target === "premium" ? "mint" : row.target === "free" ? "amber" : "brand");
  }

  // The confirmation line before a send that reaches more than one account.
  function audienceText({ target, uids, uid }) {
    if (target === "user") return nameOf(uid);
    if (target === "users") return t("notif.confirmUsers", { n: (uids || []).length });
    return t(`notif.confirm.${target}`);
  }

  function renderSent() {
    const q = search.trim().toLowerCase();
    // "all" shows every row; "all-target" the sends to everyone; any other
    // value the sends to that audience.
    const rows = sent.filter((r) => target === "all" || (target === "all-target" ? r.target === "all" : target === "users" ? r.target === "users" || r.target === "user" : r.target === target))
      .filter((r) => !q || [r.title, r.body, r.targetName, r.uid].some((v) => String(v || "").toLowerCase().includes(q)));
    const list = h("div.list");
    if (!rows.length) list.append(empty(t("notif.noneSent")));
    for (const r of rows) {
      const counts = r.target !== "user" && r.sent !== null
        ? h("span.small.muted", t("notif.counts", { items: fmtNumber(r.items || 0), sent: fmtNumber(r.sent || 0), failed: fmtNumber(r.failed || 0) }))
        : null;
      list.append(h("div.item", h("div.body",
        h("div.row", targetCell(r), sourceBadge(r.source), when(r.at), counts, r.error ? badge(t("notif.failed"), "red") : null),
        r.title ? h("b", r.title) : null,
        h("p.pre", r.body),
        r.error ? h("p.small.error", r.error) : null,
      )));
    }
    return list;
  }

  function renderTemplates() {
    const list = h("div.list");
    if (!templates.length) list.append(empty(t("notif.noTemplates")));
    for (const tpl of templates) {
      list.append(h("div.item", h("div.body",
        h("div.row", h("b", tpl.name || tpl.title || "—"), targetCell(tpl), tpl.enabled === false ? badge(t("notif.disabled"), "amber") : badge(t("notif.active"), "green")),
        h("div.small.muted", describe(tpl.schedule)),
        h("div.small.muted", [
          tpl.nextRunAt ? t("notif.next", { date: fmtDate(tpl.nextRunAt) }) : null,
          tpl.lastRunAt ? t("notif.last", { date: fmtDate(tpl.lastRunAt) }) : null,
          tpl.runs ? t("notif.runs", { n: fmtNumber(tpl.runs) }) : null,
        ].filter(Boolean).join(" · ")),
        tpl.title ? h("div", h("b", tpl.title)) : null,
        h("p.pre", tpl.body),
        h("div.row",
          button(t("notif.sendNowShort"), { kind: "small primary", onclick: () => runTemplate(tpl) }),
          button(t("common.edit"), { kind: "small", onclick: () => editTemplate(tpl) }),
          button(tpl.enabled === false ? t("notif.enable") : t("notif.disable"), { kind: "small", onclick: () => setEnabled(tpl, tpl.enabled === false) }),
          button(t("common.delete"), { kind: "ghost small", onclick: async () => {
            if (!(await confirmDialog({ title: t("notif.deleteTemplate") }))) return;
            try { await call("notify.template.delete", { id: tpl.id }); toast(t("common.deleted"), "ok"); } catch (e) { toastError(e); }
          } }),
        ),
      )));
    }
    return list;
  }

  function render() {
    clear(toolbar);
    toolbar.append(chips([["sent", t("notif.tabSent")], ["templates", t("notif.tabTemplates")]], tab, (v) => { tab = v; render(); }));
    if (tab === "sent") {
      toolbar.append(chips([["all", t("notif.filterAll")], ...TARGETS.map((k) => [k === "all" ? "all-target" : k, t(`notif.targets.${k}`)])], target, (v) => { target = v; render(); }));
      const box = input({ placeholder: t("common.search"), value: search });
      // Only the list is redrawn while typing: the field keeps its focus and caret.
      box.addEventListener("input", debounce(() => { search = box.value; renderBody(); }, 150));
      toolbar.append(box);
    }
    renderBody();
  }

  // A snapshot (a send or a scheduled run landing) redraws the list only,
  // never the toolbar the admin may be typing in.
  function renderBody() {
    clear(body);
    body.append(tab === "sent" ? renderSent() : renderTemplates());
  }

  clear(actions);
  actions.append(
    ((b) => { b.addEventListener("click", busy(b, sendNow)); return b; })(button(t("notif.sendNow"), { kind: "primary" })),
    button(t("notif.newTemplate"), { onclick: () => editTemplate(null) }),
  );

  const unsubSent = onSnapshot(query(collection(db, "admin_notifications"), orderBy("at", "desc"), limit(500)), (snap) => {
    sent = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    if (tab === "sent") renderBody();
  }, toastError);
  const unsubTemplates = onSnapshot(query(collection(db, "notification_templates"), orderBy("updatedAt", "desc"), limit(200)), (snap) => {
    templates = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    if (tab === "templates") renderBody();
  }, toastError);
  ensureUsers().then(() => renderBody()).catch(() => {});
  render();
  return () => { unsubSent(); unsubTemplates(); };
}
