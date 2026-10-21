// The support inbox: every conversation the app's support form (or Shefi
// on the user's behalf) opened, answered here the way the app's tickets
// tab answers it (a reply on the ticket plus an inbox item the trigger
// turns into a push). The whole thread shows in order — the user's
// follow-ups included — and the signature details the message carries
// (name, email, phone, build, device, language) are shown here, never in
// the user's chat.
import { db, collection, doc, onSnapshot, query, orderBy, limit, where, updateDoc, deleteDoc, writeBatch, arrayUnion, serverTimestamp, Timestamp } from "../firebase.js";
import { t, fmtNumber, fmtDate, toDate } from "../i18n.js";
import { h, clear, badge, when, button, busy, chips, textarea, field, modal, confirmDialog, toast, toastError, empty } from "../ui.js";

const TYPE_COLORS = { bug: "red", suggestion: "amber", account: "brand", billing: "green", sharing: "mint", recipes: "brand", other: "" };

function typeLabel(type) {
  const key = `tickets.types.${type}`;
  const label = t(key);
  return label === key ? type : label;
}

// Every line in the order it was written: opening message, the user's
// follow-ups and the administrator's replies.
function thread(tk) {
  const at = (v) => (toDate(v) || new Date(0)).getTime();
  const lines = [{ text: tk.message || "", at: at(tk.createdAt), admin: false, opening: true }];
  for (const r of tk.followUps || []) lines.push({ text: r.text || "", at: at(r.at), admin: false });
  for (const r of tk.replies || []) lines.push({ text: r.text || "", at: at(r.at), admin: true });
  return lines.sort((a, b) => a.at - b.at);
}

export async function mount({ view, user }) {
  let tickets = [], filter = "unread";
  const list = h("div.list");
  const count = h("span.muted.small");
  view.append(h("div.toolbar", chips([["unread", t("tickets.unread")], ["all", t("tickets.all")], ["closed", t("tickets.closed")]], filter, (v) => { filter = v; render(); }), count), list);

  // Closing ends the conversation: the user's chat locks and the ticket
  // moves under "closed" on both sides. Reopening undoes it.
  const setClosed = async (tk, closed) => {
    if (closed && !(await confirmDialog({ title: t("tickets.close"), text: t("tickets.closeConfirm", { name: tk.authorName || tk.authorUid }), danger: false }))) return;
    try {
      await updateDoc(doc(db, "feedback", tk.id), { status: closed ? "closed" : "open", closedAt: closed ? serverTimestamp() : null, updatedAt: serverTimestamp(), ...(closed ? { read: true, readAt: serverTimestamp() } : {}) });
      toast(closed ? t("tickets.closedNow") : t("tickets.reopenedNow"), "ok");
    } catch (e) { toastError(e); }
  };
  const setRead = async (tk, read) => {
    try { await updateDoc(doc(db, "feedback", tk.id), { read, readAt: read ? serverTimestamp() : null }); } catch (e) { toastError(e); }
  };
  const reply = (tk) => {
    const text = textarea({ rows: 4 });
    const last = thread(tk).filter((l) => !l.admin).pop();
    modal({ title: `${t("tickets.reply")}: ${tk.authorName || ""}`, body: h("div.stack", h("p.small.muted.pre", last ? last.text : tk.message), field(t("tickets.yourReply"), text)), actions: [(c) => button(t("common.cancel"), { onclick: c }), (c) => { const b = button(t("common.send"), { kind: "primary" }); b.addEventListener("click", busy(b, async () => {
      const body = text.value.trim();
      if (!body) return;
      try {
        const now = Timestamp.now();
        const batch = writeBatch(db);
        batch.update(doc(db, "feedback", tk.id), { replies: arrayUnion({ text: body, at: now }), repliedAt: serverTimestamp(), updatedAt: serverTimestamp(), userUnread: true, read: true, readAt: serverTimestamp() });
        batch.set(doc(collection(db, "notifications", tk.authorUid, "items")), { type: "adminReply", fromUid: user.uid, message: body, feedbackId: tk.id, feedbackExcerpt: String(tk.message || "").slice(0, 80), read: false, createdAt: now });
        await batch.commit();
        toast(t("tickets.sent"), "ok");
        c();
      } catch (e) { toastError(e); }
    })); return b; }] });
  };

  const detailsBlock = (tk) => {
    const details = tk.details && typeof tk.details === "object" ? Object.entries(tk.details).filter(([, v]) => typeof v === "string" && v.trim()) : [];
    if (!details.length) return null;
    const box = h("details", h("summary.small.muted", t("tickets.details")));
    box.append(h("div.small.mono", { style: { direction: "ltr", textAlign: "left" } }, details.map(([k, v]) => h("div", `${t(`tickets.detailKeys.${k}`) === `tickets.detailKeys.${k}` ? k : t(`tickets.detailKeys.${k}`)}: ${v}`))));
    return box;
  };

  const render = () => {
    const isClosed = (tk) => tk.status === "closed";
    const rows = filter === "closed" ? tickets.filter(isClosed) : filter === "unread" ? tickets.filter((tk) => !tk.read && !isClosed(tk)) : tickets.filter((tk) => !isClosed(tk));
    count.textContent = t("tickets.count", { n: fmtNumber(rows.length) });
    clear(list);
    if (!rows.length) { list.append(empty(t("tickets.none"))); return; }
    for (const tk of rows) {
      const lines = thread(tk);
      list.append(h(`div.item${tk.read ? "" : ".unread"}`, h("div.body",
        h("div.row", badge(typeLabel(tk.type), TYPE_COLORS[tk.type] || ""), tk.status === "closed" ? badge(t("tickets.closedBadge"), "") : null, tk.source === "shefi" ? badge(t("tickets.viaShefi"), "mint") : null, h("a", { href: `#/users/${tk.authorUid}` }, tk.authorName || tk.authorEmail || tk.authorUid), h("span.small.muted", tk.authorEmail || ""), h("span.small.muted", `${t("tickets.appVersion")} ${tk.appVersion || "—"}`), when(tk.createdAt), tk.updatedAt && toDate(tk.updatedAt) && toDate(tk.updatedAt).getTime() !== (toDate(tk.createdAt) || new Date(0)).getTime() ? h("span.small.muted", `${t("tickets.updated")} ${fmtDate(toDate(tk.updatedAt))}`) : null),
        h("div.stack", { style: { gap: "6px" } }, lines.map((l) => h(l.admin ? "div.small.pre" : "p.pre", { style: l.admin ? { borderInlineStart: "2px solid var(--brand)", paddingInlineStart: "8px" } : { margin: 0 } }, l.admin ? h("span.muted", `${t("tickets.you")} · ${fmtDate(new Date(l.at))}: `) : (l.opening ? null : h("span.muted.small", `${t("tickets.user")} · ${fmtDate(new Date(l.at))}: `)), l.text))),
        detailsBlock(tk),
        h("div.row", tk.status === "closed" ? button(t("tickets.reopen"), { kind: "small", onclick: () => setClosed(tk, false) }) : button(t("tickets.reply"), { kind: "small primary", onclick: () => reply(tk) }), tk.status === "closed" ? null : button(t("tickets.close"), { kind: "small", onclick: () => setClosed(tk, true) }), button(tk.read ? t("tickets.markUnread") : t("tickets.markRead"), { kind: "small", onclick: () => setRead(tk, !tk.read) }), button(t("common.delete"), { kind: "ghost small", onclick: async () => {
          if (!(await confirmDialog({ title: t("tickets.delete") }))) return;
          try { await deleteDoc(doc(db, "feedback", tk.id)); toast(t("common.deleted"), "ok"); } catch (e) { toastError(e); }
        } })),
      )));
    }
  };
  // The newest 500, plus every unread one even when it is older than that
  // (the default "unread" filter must not lose a ticket past the window).
  let recent = [], unread = [];
  const merge = () => {
    const byId = new Map(recent.map((tk) => [tk.id, tk]));
    for (const tk of unread) if (!byId.has(tk.id)) byId.set(tk.id, tk);
    tickets = [...byId.values()].sort((a, b) => (toDate(b.createdAt) || new Date(0)).getTime() - (toDate(a.createdAt) || new Date(0)).getTime());
    render();
  };
  const subs = [
    onSnapshot(query(collection(db, "feedback"), orderBy("createdAt", "desc"), limit(500)), (snap) => { recent = snap.docs.map((d) => ({ id: d.id, ...d.data() })); merge(); }, toastError),
    onSnapshot(query(collection(db, "feedback"), where("read", "==", false), limit(500)), (snap) => { unread = snap.docs.map((d) => ({ id: d.id, ...d.data() })); merge(); }, () => {}),
  ];
  return () => subs.forEach((u) => u());
}
