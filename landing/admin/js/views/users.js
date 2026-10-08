// Every account, live: who is online right now, who holds a device
// session, who is Premium or blocked. One click opens the account.
import { db, collection, onSnapshot, query, limit } from "../firebase.js";
import { t, fmtNumber, fmtDate } from "../i18n.js";
import { h, clear, table, avatar, dot, badge, when, button, busy, chips, input, textarea, field, modal, toast, toastError, debounce } from "../ui.js";
import { isOnline, premiumActive, platformLabel } from "../data.js";
import { call } from "../api.js";

export async function mount({ view, actions }) {
  let users = [], sessions = {}, statuses = {}, entitlements = {};
  let filter = "all", search = "";
  const body = h("div");
  const count = h("span.muted.small");
  const searchBox = input({ placeholder: t("common.search"), oninput: debounce((e) => { search = e.target.value.trim().toLowerCase(); render(); }, 150) });
  view.append(
    h("div.toolbar", h("div.search", searchBox), chips([["all", t("users.filter.all")], ["online", t("users.filter.online")], ["premium", t("users.filter.premium")], ["disabled", t("users.filter.disabled")], ["session", t("users.filter.session")]], filter, (v) => { filter = v; render(); }), count),
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
        try { const r = await call("user.notifyAll", { title: title.value.trim(), body: text.value.trim() }); toast(t("users.broadcastSent", { items: r.items, sent: r.sent, failed: r.failed }), "ok"); c(); } catch (err) { toastError(err); }
      })); return b; }],
    });
    void close;
  });
  actions.append(broadcast);

  const render = () => {
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
    rows.sort((a, b) => Number(b.online) - Number(a.online) || ((b.lastSeenAt && b.lastSeenAt.toMillis ? b.lastSeenAt.toMillis() : 0) - (a.lastSeenAt && a.lastSeenAt.toMillis ? a.lastSeenAt.toMillis() : 0)));
    count.textContent = t("users.count", { n: fmtNumber(rows.length) });
    clear(body);
    body.append(table([
      { label: "", cell: (r) => dot(r.online) },
      { label: t("common.name"), cell: (r) => h("div.row", avatar(r.fullName, r.photoUrl, "sm"), h("div", h("div", r.fullName || t("common.unnamed")), h("div.small.muted", r.email || r.phoneNumber || r.uid))) },
      { label: t("common.status"), cell: (r) => h("div.row", r.premium ? badge(t("users.premium"), "mint") : badge(t("users.free")), r.disabled ? badge(t("users.disabled"), "red") : null) },
      { label: t("users.lastSeen"), cell: (r) => r.online ? badge(t("users.online"), "green") : when(r.lastSeenAt) },
      { label: t("users.device"), cell: (r) => h("span.small", platformLabel(r.platform), r.appVersion ? ` · ${r.appVersion}` : "") },
      { label: t("users.session"), cell: (r) => r.session ? h("span.small", platformLabel(r.session.platform), r.session.expiresAt ? ` · ${t("users.sessionUntil", { date: fmtDate(r.session.expiresAt, false) })}` : "") : h("span.small.muted", t("users.noSession")) },
      { label: t("users.joined"), cell: (r) => h("span.small", fmtDate(r.createdAt, false)) },
    ], rows, { onRow: (r) => { location.hash = `#/users/${r.uid}`; }, emptyText: t("common.nothingFound") }));
  };

  const subs = [
    onSnapshot(query(collection(db, "users"), limit(5000)), (snap) => { users = snap.docs.map((d) => ({ uid: d.id, ...d.data() })); render(); }, (err) => toastError(err)),
    onSnapshot(collection(db, "sessions"), (snap) => { sessions = Object.fromEntries(snap.docs.map((d) => [d.id, d.data()])); render(); }, () => {}),
    onSnapshot(collection(db, "account_status"), (snap) => { statuses = Object.fromEntries(snap.docs.map((d) => [d.id, d.data()])); render(); }, () => {}),
    onSnapshot(collection(db, "entitlements"), (snap) => { entitlements = Object.fromEntries(snap.docs.map((d) => [d.id, d.data()])); render(); }, () => {}),
  ];
  // The online column depends on the clock as much as on the data.
  const tick = setInterval(render, 30000);
  return () => { subs.forEach((u) => u()); clearInterval(tick); };
}
