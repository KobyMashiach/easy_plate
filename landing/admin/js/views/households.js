// Pro Duo / Pro Family households: who owns one, who sits in it, and the
// two things the server lets the administrator do about it.
import { db, collection, getDocs, query, limit } from "../firebase.js";
import { t, fmtNumber, fmtDate } from "../i18n.js";
import { h, clear, spinner, avatar, badge, button, confirmDialog, toast, toastError, empty } from "../ui.js";
import { profiles } from "../data.js";
import { call } from "../api.js";

export async function mount({ view }) {
  const list = h("div.cards");
  const count = h("span.muted.small");
  view.append(h("div.toolbar", count), list);

  // A Firestore failure shows the console's error card instead of a spinner
  // for ever; a newer render (after an action) wins over a slower older one.
  let seq = 0;
  const render = async () => {
    const mine = ++seq;
    clear(list);
    list.append(spinner());
    let rows, names;
    try {
      const snap = await getDocs(query(collection(db, "households"), limit(500)));
      rows = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      names = await profiles(rows.flatMap((r) => r.memberUids || []));
    } catch (err) {
      if (mine !== seq) return;
      clear(list);
      list.append(h("div.card.error", err.message));
      console.error(err);
      return;
    }
    if (mine !== seq) return;
    clear(list);
    count.textContent = t("hh.count", { n: fmtNumber(rows.length) });
    if (!rows.length) { list.append(empty(t("hh.none"))); return; }
    for (const r of rows) {
      const members = (r.memberUids || []).map((uid) => {
        const p = names[uid] || {};
        const role = (r.members && r.members[uid] && r.members[uid].role) || (uid === r.ownerUid ? "owner" : "member");
        return h("div.row.between", h("div.row", avatar(p.fullName, p.photoUrl, "sm"), h("a", { href: `#/users/${uid}` }, p.fullName || uid), role === "owner" ? badge(t("hh.owner"), "mint") : null, r.members && r.members[uid] && r.members[uid].joinedAt ? h("span.small.muted", fmtDate(r.members[uid].joinedAt, false)) : null),
          role === "owner" ? null : button(t("hh.remove"), { kind: "ghost small", onclick: async () => {
            if (!(await confirmDialog({ title: t("hh.remove"), text: p.fullName || uid, danger: true, okLabel: t("hh.remove") }))) return;
            try { await call("household.removeMember", { hid: r.id, uid }); toast(t("hh.removed"), "ok"); render(); } catch (e) { toastError(e); }
          } }));
      });
      list.append(h("div.card.stack",
        h("div.row.between", h("h3", r.title || r.id), badge(((k) => (t(k) === k ? r.tier : t(k)))(`hh.tiers.${r.tier}`), "brand")),
        h("div.small.muted", `${t("hh.seats")}: ${(r.memberUids || []).length}/${r.seats || "?"} · ${t("hh.created")} ${fmtDate(r.createdAt, false)}`),
        h("div.stack", members),
        h("div.row", button(t("hh.dissolve"), { kind: "small danger", title: t("hh.dissolveHint"), onclick: async () => {
          if (!(await confirmDialog({ title: t("hh.dissolve"), text: t("hh.dissolveHint") }))) return;
          try { await call("household.dissolve", { hid: r.id }); toast(t("hh.dissolved"), "ok"); render(); } catch (e) { toastError(e); }
        } })),
      ));
    }
  };
  render();
  return () => {};
}
