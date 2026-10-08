// The support inbox: what the app's feedback form sends, answered here the
// way the app's tickets tab answers it (a reply on the ticket plus an
// inbox item the trigger turns into a push).
import { db, collection, doc, onSnapshot, query, orderBy, limit, updateDoc, deleteDoc, writeBatch, arrayUnion, serverTimestamp, Timestamp } from "../firebase.js";
import { t, fmtNumber, fmtDate } from "../i18n.js";
import { h, clear, badge, when, button, busy, chips, textarea, field, modal, confirmDialog, toast, toastError, empty } from "../ui.js";

export async function mount({ view, user }) {
  let tickets = [], filter = "unread";
  const list = h("div.list");
  const count = h("span.muted.small");
  view.append(h("div.toolbar", chips([["unread", t("tickets.unread")], ["all", t("tickets.all")]], filter, (v) => { filter = v; render(); }), count), list);

  const setRead = async (tk, read) => {
    try { await updateDoc(doc(db, "feedback", tk.id), { read, readAt: read ? serverTimestamp() : null }); } catch (e) { toastError(e); }
  };
  const reply = (tk) => {
    const text = textarea();
    modal({ title: `${t("tickets.reply")}: ${tk.authorName || ""}`, body: h("div.stack", h("p.small.muted.pre", tk.message), field(t("tickets.yourReply"), text)), actions: [(c) => button(t("common.cancel"), { onclick: c }), (c) => { const b = button(t("common.send"), { kind: "primary" }); b.addEventListener("click", busy(b, async () => {
      const body = text.value.trim();
      if (!body) return;
      try {
        const now = Timestamp.now();
        const batch = writeBatch(db);
        batch.update(doc(db, "feedback", tk.id), { replies: arrayUnion({ text: body, at: now }), repliedAt: serverTimestamp(), read: true, readAt: serverTimestamp() });
        batch.set(doc(collection(db, "notifications", tk.authorUid, "items")), { type: "adminReply", fromUid: user.uid, message: body, feedbackId: tk.id, feedbackExcerpt: String(tk.message || "").slice(0, 80), read: false, createdAt: now });
        await batch.commit();
        toast(t("tickets.sent"), "ok");
        c();
      } catch (e) { toastError(e); }
    })); return b; }] });
  };

  const render = () => {
    const rows = filter === "unread" ? tickets.filter((tk) => !tk.read) : tickets;
    count.textContent = t("tickets.count", { n: fmtNumber(rows.length) });
    const badgeEl = document.getElementById("ticketsBadge");
    if (badgeEl) { const unread = tickets.filter((tk) => !tk.read).length; badgeEl.hidden = !unread; badgeEl.textContent = String(unread); }
    clear(list);
    if (!rows.length) { list.append(empty(t("tickets.none"))); return; }
    for (const tk of rows) {
      list.append(h(`div.item${tk.read ? "" : ".unread"}`, h("div.body",
        h("div.row", badge(t(`tickets.types.${tk.type}`), tk.type === "bug" ? "red" : "amber"), h("a", { href: `#/users/${tk.authorUid}` }, tk.authorName || tk.authorEmail || tk.authorUid), h("span.small.muted", tk.authorEmail || ""), h("span.small.muted", `${t("tickets.appVersion")} ${tk.appVersion || "—"}`), when(tk.createdAt)),
        h("p.pre", tk.message),
        (tk.replies || []).length ? h("div.stack", h("div.small.muted", t("tickets.replies")), tk.replies.map((r) => h("div.small.pre", { style: { borderInlineStart: "2px solid var(--brand)", paddingInlineStart: "8px" } }, r.text, " ", h("span.muted", fmtDate(r.at))))) : null,
        h("div.row", button(t("tickets.reply"), { kind: "small primary", onclick: () => reply(tk) }), button(tk.read ? t("tickets.markUnread") : t("tickets.markRead"), { kind: "small", onclick: () => setRead(tk, !tk.read) }), button(t("common.delete"), { kind: "ghost small", onclick: async () => {
          if (!(await confirmDialog({ title: t("tickets.delete") }))) return;
          try { await deleteDoc(doc(db, "feedback", tk.id)); toast(t("common.deleted"), "ok"); } catch (e) { toastError(e); }
        } })),
      )));
    }
  };
  const unsub = onSnapshot(query(collection(db, "feedback"), orderBy("createdAt", "desc"), limit(500)), (snap) => { tickets = snap.docs.map((d) => ({ id: d.id, ...d.data() })); render(); }, toastError);
  return unsub;
}
