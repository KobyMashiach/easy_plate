// Every account, live: who is online right now, who holds a device
// session, who is Premium or blocked. One click opens the account.
import { db, collection, onSnapshot, query, limit } from "../firebase.js";
import { t, fmtNumber, fmtDate } from "../i18n.js";
import { h, clear, table, avatar, dot, badge, when, button, busy, chips, input, textarea, field, modal, confirmDialog, toast, toastError, debounce } from "../ui.js";
import { isOnline, premiumActive, platformLabel } from "../data.js";
import { call } from "../api.js";

// Rows drawn at once; the rest come on "show more". The filters, the
// search and the count still run over every account.
const PAGE = 200;

const millisOf = (v) => (v && typeof v.toMillis === "function" ? v.toMillis() : 0);

// "1.0.10" after "1.0.7": a version is compared part by part as numbers
// (a build suffix "+14" counts as one more part).
function versionParts(v) {
  return String(v || "").split(/[.+-]/).map((x) => parseInt(x, 10)).map((n) => (Number.isFinite(n) ? n : 0));
}

function compare(x, y) {
  if (Array.isArray(x)) {
    for (let i = 0; i < Math.max(x.length, y.length); i++) {
      const d = (x[i] || 0) - (y[i] || 0);
      if (d) return d;
    }
    return 0;
  }
  if (typeof x === "number") return x - y;
  return String(x).localeCompare(String(y), undefined, { sensitivity: "base" });
}

// What each sortable column orders by; null or "" = nothing to sort on.
const SORTS = {
  name: (r) => r.fullName || r.email || r.phoneNumber || "",
  status: (r) => (r.disabled ? 2 : r.premium ? 0 : 1),
  lastSeen: (r) => (r.online ? Number.MAX_SAFE_INTEGER : millisOf(r.lastSeenAt) || null),
  device: (r) => String(r.platform || "").toLowerCase() || null,
  version: (r) => (r.appVersion ? versionParts(r.appVersion) : null),
  session: (r) => (r.session ? millisOf(r.session.expiresAt) || 1 : null),
  joined: (r) => millisOf(r.createdAt) || null,
};

export async function mount({ view, actions }) {
  let users = [], sessions = {}, statuses = {}, entitlements = {};
  let filter = "all", search = "", shown = PAGE;
  // A heading click sorts by that column; a second click on it reverses.
  // null = the default order (online first, then last seen).
  let sort = null;
  const onSort = (key) => {
    sort = sort && sort.key === key ? { key, dir: sort.dir === "asc" ? "desc" : "asc" } : { key, dir: "asc" };
    shown = PAGE;
    render(true);
  };
  const body = h("div");
  const count = h("span.muted.small");
  const refilter = () => { shown = PAGE; render(true); };
  const searchBox = input({ placeholder: t("common.search"), oninput: debounce((e) => { search = e.target.value.trim().toLowerCase(); refilter(); }, 150) });
  view.append(
    h("div.toolbar", h("div.search", searchBox), chips([["all", t("users.filter.all")], ["online", t("users.filter.online")], ["premium", t("users.filter.premium")], ["disabled", t("users.filter.disabled")], ["session", t("users.filter.session")]], filter, (v) => { filter = v; refilter(); }), count),
    h("p.small.muted", t("users.hint")),
    body,
  );

  const broadcast = button(t("users.broadcast"), { kind: "small" });
  broadcast.addEventListener("click", () => {
    const title = input({ placeholder: "EasyPlate" });
    const text = textarea({ placeholder: "" });
    const close = modal({
      title: t("users.broadcastTitle"),
      body: h("div.stack", field(t("common.title"), title), field(t("common.body"), text)),
      actions: [(c) => button(t("common.cancel"), { onclick: c }), (c) => { const b = button(t("common.send"), { kind: "primary" }); b.addEventListener("click", busy(b, async () => {
        if (!text.value.trim()) return;
        // A push to every account: one more explicit yes, as the notifications page asks.
        if (!(await confirmDialog({ title: t("users.broadcastTitle"), text: t("notif.confirm.all"), danger: false }))) return;
        try { const r = await call("user.notifyAll", { title: title.value.trim(), body: text.value.trim() }); toast(t("users.broadcastSent", { items: r.items, sent: r.sent, failed: r.failed }), "ok"); c(); } catch (err) { toastError(err); }
      })); return b; }],
    });
    void close;
  });
  actions.append(broadcast);

  const millis = (v) => (v && typeof v.toMillis === "function" ? v.toMillis() : 0);
  // What the visible table shows. A presence heartbeat only moves an
  // online account's lastSeenAt, which nothing on screen depends on, so
  // the table is rebuilt only when this changes (or the clock ticks).
  let drawn = "";
  const render = (force = false) => {
    const now = Date.now();
    let rows = users.map((u) => ({
      ...u,
      online: isOnline(u, now),
      session: sessions[u.uid] || null,
      disabled: !!(statuses[u.uid] && statuses[u.uid].disabled),
      premium: premiumActive(entitlements[u.uid], now),
    }));
    if (filter === "online") rows = rows.filter((r) => r.online);
    if (filter === "premium") rows = rows.filter((r) => r.premium);
    if (filter === "disabled") rows = rows.filter((r) => r.disabled);
    if (filter === "session") rows = rows.filter((r) => r.session);
    if (search) rows = rows.filter((r) => [r.fullName, r.email, r.phoneNumber, r.uid].some((v) => String(v || "").toLowerCase().includes(search)));
    // Online accounts by name (their lastSeenAt moves every heartbeat and
    // would shuffle the rows); the rest by when they were last seen.
    const byDefault = (a, b) => Number(b.online) - Number(a.online)
      || (a.online ? String(a.fullName || a.uid).localeCompare(String(b.fullName || b.uid)) : millis(b.lastSeenAt) - millis(a.lastSeenAt));
    if (!sort) rows.sort(byDefault);
    else {
      const key = SORTS[sort.key];
      const sign = sort.dir === "asc" ? 1 : -1;
      // Rows with nothing to sort on stay at the bottom either way.
      rows.sort((a, b) => {
        const x = key(a), y = key(b);
        const xe = x === null || x === "", ye = y === null || y === "";
        if (xe || ye) return xe === ye ? byDefault(a, b) : xe ? 1 : -1;
        return sign * compare(x, y) || byDefault(a, b);
      });
    }
    count.textContent = t("users.count", { n: fmtNumber(rows.length) });
    const page = rows.slice(0, shown);
    const signature = JSON.stringify([sort, rows.length, page.map((r) => [r.uid, r.online, r.premium, r.disabled, r.fullName, r.email, r.phoneNumber, r.photoUrl, r.platform, r.appVersion,
      r.session ? [r.session.platform, millis(r.session.expiresAt)] : null, millis(r.createdAt), r.online ? 0 : millis(r.lastSeenAt)])]);
    if (!force && signature === drawn) return;
    drawn = signature;
    clear(body);
    body.append(table([
      { label: "", cell: (r) => dot(r.online) },
      { label: t("common.name"), sort: "name", cell: (r) => h("div.row", avatar(r.fullName, r.photoUrl, "sm"), h("div", h("div", r.fullName || t("common.unnamed")), h("div.small.muted", r.email || r.phoneNumber || r.uid))) },
      { label: t("common.status"), sort: "status", cell: (r) => h("div.row", r.premium ? badge(t("users.premium"), "mint") : badge(t("users.free")), r.disabled ? badge(t("users.disabled"), "red") : null) },
      { label: t("users.lastSeen"), sort: "lastSeen", cell: (r) => r.online ? badge(t("users.online"), "green") : when(r.lastSeenAt) },
      { label: t("users.device"), sort: "device", cell: (r) => h("span.small", platformLabel(r.platform)) },
      { label: t("users.version"), sort: "version", cell: (r) => r.appVersion ? h("span.small.mono", r.appVersion) : h("span.small.muted", "—") },
      { label: t("users.session"), sort: "session", cell: (r) => r.session ? h("span.small", platformLabel(r.session.platform), r.session.expiresAt ? ` · ${t("users.sessionUntil", { date: fmtDate(r.session.expiresAt, false) })}` : "") : h("span.small.muted", t("users.noSession")) },
      { label: t("users.joined"), sort: "joined", cell: (r) => h("span.small", fmtDate(r.createdAt, false)) },
    ], page, { sort, onSort, onRow: (r) => { location.hash = `#/users/${r.uid}`; }, emptyText: t("common.nothingFound") }));
    if (rows.length > page.length) body.append(h("div.center", button(`${t("common.showMore")} (${fmtNumber(rows.length - page.length)})`, { kind: "small", onclick: () => { shown += PAGE; render(true); } })));
  };
  // The four listeners answer within the same moment; one table for all
  // of them rather than four in a row.
  let pending = false;
  let forceNext = false;
  const schedule = (force = false) => { forceNext = forceNext || force; if (pending) return; pending = true; requestAnimationFrame(() => { pending = false; const f = forceNext; forceNext = false; render(f); }); };

  // Each listener is bounded like the users one and applies only the
  // documents that changed (a heartbeat is one change, not 5000 copies).
  const byId = new Map();
  const follow = (name, apply, onError = () => {}) => onSnapshot(query(collection(db, name), limit(5000)), (snap) => {
    for (const ch of snap.docChanges()) {
      if (ch.type === "removed") byId.get(name).delete(ch.doc.id);
      else byId.get(name).set(ch.doc.id, ch.doc.data());
    }
    apply(byId.get(name));
    schedule();
  }, onError);
  ["users", "sessions", "account_status", "entitlements"].forEach((n) => byId.set(n, new Map()));
  const subs = [
    follow("users", (m) => { users = Array.from(m, ([uid, d]) => ({ uid, ...d })); }, (err) => toastError(err)),
    follow("sessions", (m) => { sessions = Object.fromEntries(m); }),
    follow("account_status", (m) => { statuses = Object.fromEntries(m); }),
    follow("entitlements", (m) => { entitlements = Object.fromEntries(m); }),
  ];
  // The online column and the "last seen" ages depend on the clock.
  const tick = setInterval(() => schedule(true), 30000);
  return () => { subs.forEach((u) => u()); clearInterval(tick); };
}
