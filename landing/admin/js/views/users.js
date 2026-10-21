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

export async function mount({ view, actions }) {
  let users = [], sessions = {}, statuses = {}, entitlements = {};
  let filter = "all", search = "", shown = PAGE;
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
    rows.sort((a, b) => Number(b.online) - Number(a.online)
      || (a.online ? String(a.fullName || a.uid).localeCompare(String(b.fullName || b.uid)) : millis(b.lastSeenAt) - millis(a.lastSeenAt)));
    count.textContent = t("users.count", { n: fmtNumber(rows.length) });
    const page = rows.slice(0, shown);
    const signature = JSON.stringify([rows.length, page.map((r) => [r.uid, r.online, r.premium, r.disabled, r.fullName, r.email, r.phoneNumber, r.photoUrl, r.platform, r.appVersion,
      r.session ? [r.session.platform, millis(r.session.expiresAt)] : null, millis(r.createdAt), r.online ? 0 : millis(r.lastSeenAt)])]);
    if (!force && signature === drawn) return;
    drawn = signature;
    clear(body);
    body.append(table([
      { label: "", cell: (r) => dot(r.online) },
      { label: t("common.name"), cell: (r) => h("div.row", avatar(r.fullName, r.photoUrl, "sm"), h("div", h("div", r.fullName || t("common.unnamed")), h("div.small.muted", r.email || r.phoneNumber || r.uid))) },
      { label: t("common.status"), cell: (r) => h("div.row", r.premium ? badge(t("users.premium"), "mint") : badge(t("users.free")), r.disabled ? badge(t("users.disabled"), "red") : null) },
      { label: t("users.lastSeen"), cell: (r) => r.online ? badge(t("users.online"), "green") : when(r.lastSeenAt) },
      { label: t("users.device"), cell: (r) => h("span.small", platformLabel(r.platform), r.appVersion ? ` · ${r.appVersion}` : "") },
      { label: t("users.session"), cell: (r) => r.session ? h("span.small", platformLabel(r.session.platform), r.session.expiresAt ? ` · ${t("users.sessionUntil", { date: fmtDate(r.session.expiresAt, false) })}` : "") : h("span.small.muted", t("users.noSession")) },
      { label: t("users.joined"), cell: (r) => h("span.small", fmtDate(r.createdAt, false)) },
    ], page, { onRow: (r) => { location.hash = `#/users/${r.uid}`; }, emptyText: t("common.nothingFound") }));
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
