// One account: who they are, how they sign in, what they pay, what they
// own, what they wrote, what the AI cost — and every lever on it.
import { db, doc, collection, getDoc, getDocs, onSnapshot, query, where, orderBy, limit, Timestamp } from "../firebase.js";
import { t, fmtNumber, fmtMoney, fmtDate } from "../i18n.js";
import { h, clear, spinner, table, kv, avatar, dot, badge, when, button, busy, tabs, input, textarea, field, toggle, modal, confirmDialog, promptDialog, toast, toastError, copyText, empty } from "../ui.js";
import { isOnline, premiumActive, platformLabel, pricing, tally, costIls, isPersona, profiles } from "../data.js";
import { call } from "../api.js";

const COLLECTIONS = ["recipes", "books", "meal_plans", "grocery_lists", "preferences", "price_records", "receipts", "product_pricing"];
const SHARED = new Set(["recipes", "books", "meal_plans", "grocery_lists", "price_records", "receipts", "product_pricing"]);

// Firestore timestamps inside a mirrored document become a tagged string
// in the JSON editor, and come back as timestamps.
function toEditable(value) {
  if (value && typeof value.toDate === "function") return `__ts__${value.toDate().toISOString()}`;
  if (Array.isArray(value)) return value.map(toEditable);
  if (value && typeof value === "object") return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, toEditable(v)]));
  return value;
}
function fromEditable(value) {
  if (typeof value === "string" && value.startsWith("__ts__")) {
    const d = new Date(value.slice(6));
    return Number.isNaN(d.getTime()) ? value : Timestamp.fromDate(d);
  }
  if (Array.isArray(value)) return value.map(fromEditable);
  if (value && typeof value === "object") return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, fromEditable(v)]));
  return value;
}
// What the function needs: plain JSON. Timestamps are sent as ISO strings
// (the app's mirror writes dates that way too).
function plain(value) {
  if (value && typeof value.toDate === "function") return value.toDate().toISOString();
  if (value && typeof value.toMillis === "function") return new Date(value.toMillis()).toISOString();
  if (Array.isArray(value)) return value.map(plain);
  if (value && typeof value === "object") return Object.fromEntries(Object.entries(value).map(([k, v]) => [k, plain(v)]));
  return value;
}

function docTitle(d) {
  return d.title || d.name || d.fullName || d.productName || d.store || d.id || "";
}

export async function mount({ view, params, setTitle }) {
  const uid = params[0];
  const persona = isPersona(uid);
  let user = null, ent = null, status = null, session = null, auth = undefined, household = null;
  const head = h("div.card");
  const tabWrap = h("div");
  const body = h("div.stack");
  view.append(head, tabWrap, body);
  const prices = await pricing();

  const [entSnap, statusSnap, sessionSnap, hh, pub] = await Promise.all([
    getDoc(doc(db, "entitlements", uid)), getDoc(doc(db, "account_status", uid)), getDoc(doc(db, "sessions", uid)),
    getDocs(query(collection(db, "households"), where("memberUids", "array-contains", uid), limit(1))),
    persona ? getDoc(doc(db, "seed_personas", uid)) : getDoc(doc(db, "public_profiles", uid)),
  ]);
  ent = entSnap.exists() ? entSnap.data() : null;
  status = statusSnap.exists() ? statusSnap.data() : null;
  session = sessionSnap.exists() ? sessionSnap.data() : null;
  household = hh.empty ? null : { id: hh.docs[0].id, ...hh.docs[0].data() };
  const publicProfile = pub.exists() ? pub.data() : null;

  const renderHead = () => {
    clear(head);
    const now = Date.now();
    const name = (user && user.fullName) || (publicProfile && (publicProfile.fullName || publicProfile.name)) || t("common.unnamed");
    const photo = (user && user.photoUrl) || (publicProfile && publicProfile.photoUrl) || null;
    setTitle(name);
    const online = isOnline(user, now);
    head.append(h("div.row.between",
      h("div.row", avatar(name, photo, "lg"), h("div",
        h("h3", h("span.row", dot(online), name, persona ? badge(t("users.persona"), "brand") : null)),
        h("div.small.muted", [user && user.email, user && user.phoneNumber].filter(Boolean).join(" · ") || "—"),
        h("div.row.small", h("span.mono.muted", uid), button(t("common.copy"), { kind: "ghost small", onclick: () => copyText(uid) })),
        h("div.row", premiumActive(ent, now) ? badge(t("users.premium"), "mint") : badge(t("users.free")), status && status.disabled ? badge(t("users.disabled"), "red") : null, online ? badge(t("users.online"), "green") : h("span.small.muted", `${t("users.lastSeen")}: `, when(user && user.lastSeenAt))),
      )),
      persona ? null : h("div.row",
        button(t("user.notify"), { kind: "small", onclick: notify }),
        status && status.disabled ? button(t("user.enable"), { kind: "small", onclick: enable }) : button(t("user.disable"), { kind: "small danger", onclick: disable }),
        button(t("user.kick"), { kind: "small", title: t("user.kickHint"), onclick: kick, disabled: !session }),
        button(t("user.delete"), { kind: "small danger", title: t("user.deleteHint"), onclick: remove }),
      ),
    ));
    if (status && status.disabled) head.append(h("p.warn", t("user.disabledBanner", { message: status.message || "" })));
  };

  async function notify() {
    const titleCtl = input({ placeholder: "EasyPlate" });
    const text = textarea();
    modal({ title: t("user.notify"), body: h("div.stack", field(t("common.title"), titleCtl), field(t("common.body"), text)), actions: [(c) => button(t("common.cancel"), { onclick: c }), (c) => { const b = button(t("common.send"), { kind: "primary" }); b.addEventListener("click", busy(b, async () => { if (!text.value.trim()) return; try { await call("user.notify", { uid, title: titleCtl.value.trim(), body: text.value.trim() }); toast(t("user.notified"), "ok"); c(); } catch (e) { toastError(e); } })); return b; }] });
  }
  async function disable() {
    const message = await promptDialog({ title: t("user.disable"), label: t("user.blockMessage"), multiline: true, okLabel: t("user.disable") });
    if (message === null) return;
    try { await call("user.disable", { uid, message }); status = { disabled: true, message }; renderHead(); toast(t("common.done"), "ok"); } catch (e) { toastError(e); }
  }
  async function enable() {
    try { await call("user.enable", { uid }); status = { disabled: false, message: "" }; renderHead(); toast(t("common.done"), "ok"); } catch (e) { toastError(e); }
  }
  async function kick() {
    if (!(await confirmDialog({ title: t("user.kick"), text: t("user.kickHint"), danger: false, okLabel: t("user.kick") }))) return;
    try { await call("user.kick", { uid }); session = null; renderHead(); toast(t("user.kicked"), "ok"); } catch (e) { toastError(e); }
  }
  async function remove() {
    if (!(await confirmDialog({ title: t("user.delete"), text: t("user.deleteHint") }))) return;
    try { await call("user.delete", { uid }); toast(t("common.deleted"), "ok"); location.hash = "#/users"; } catch (e) { toastError(e); }
  }

  // ---- tabs ----
  const TABS = [["overview", t("user.profile")], ["content", t("user.content")], ["ai", t("user.usage")], ["community", t("nav.community")], ["sharing", t("user.shared")], ["inbox", t("user.inbox")], ["tickets", t("user.feedback")]];
  let active = "overview";
  tabWrap.append(tabs(persona ? TABS.filter(([k]) => k === "community" || k === "overview") : TABS, active, (k) => { active = k; renderTab(); }));

  async function renderTab() {
    clear(body);
    body.append(spinner());
    try {
      const section = await ({ overview, content, ai, community, sharing, inbox, tickets })[active]();
      clear(body);
      body.append(section);
    } catch (err) {
      clear(body);
      body.append(h("div.card.error", err.message));
      console.error(err);
    }
  }

  async function overview() {
    if (auth === undefined && !persona) {
      try { auth = (await call("user.auth", { uid })).auth; } catch (_) { auth = null; }
    }
    const now = Date.now();
    const entCard = h("div.card", h("h2", t("user.entitlement")));
    entCard.append(kv([
      [t("common.status"), premiumActive(ent, now) ? badge(t("users.premium"), "mint") : badge(t("users.free"))],
      [t("user.premiumUntil"), ent && ent.premiumUntil ? fmtDate(ent.premiumUntil) : "—"],
      [t("user.source"), ent && ent.source], ["Product", ent && ent.productId], [t("user.adminLock"), ent && ent.adminLock ? t("common.yes") : t("common.no")],
      [t("user.household"), household ? h("a", { href: "#/households" }, household.title || household.id) : null],
    ]));
    if (!persona) entCard.append(h("div.row", button(t("user.setPremium"), { kind: "small primary", onclick: grantPremium }), ent && ent.premium ? button(t("user.removePremium"), { kind: "small danger", onclick: removePremium }) : null));

    const profileCard = h("div.card", h("h2", t("user.profile")), kv([
      [t("user.fullName"), user && user.fullName], [t("common.email"), user && user.email], [t("common.phone"), user && user.phoneNumber],
      [t("user.created"), user && fmtDate(user.createdAt)], [t("common.platform"), user && platformLabel(user.platform)], [t("user.appVersion"), user && user.appVersion],
      [t("users.lastSeen"), user && fmtDate(user.lastSeenAt)], [t("user.pushToken"), user && user.pushToken ? h("span.mono.small", String(user.pushToken).slice(0, 24) + "…") : "—"],
      persona ? [t("personas.bio"), publicProfile && publicProfile.bio] : undefined,
    ]), persona ? null : button(t("user.editProfile"), { kind: "small", onclick: editProfile }));

    // An ID token lives an hour from the last refresh Firebase recorded.
    const tokenUntil = auth && auth.lastRefreshAt ? new Date(new Date(auth.lastRefreshAt).getTime() + 3600 * 1000) : null;
    const tokenLive = tokenUntil && tokenUntil.getTime() > now;
    const authCard = persona ? null : h("div.card", h("h2", t("user.auth")), auth ? h("div.stack", kv([
      [t("user.providers"), (auth.providers || []).join(", ") || "—"], [t("common.status"), auth.disabled ? badge(t("user.disabledYes"), "red") : badge(t("user.disabledNo"), "green")],
      [t("user.created"), fmtDate(auth.createdAt)], [t("user.lastSignIn"), fmtDate(auth.lastSignInAt)], [t("user.lastRefresh"), fmtDate(auth.lastRefreshAt)],
      [t("user.tokenUntil"), tokenUntil ? h("span.row", fmtDate(tokenUntil), tokenLive ? badge(t("user.tokenLive"), "green") : badge(t("user.tokenExpired"), "amber")) : null],
      [t("user.tokensValidAfter"), fmtDate(auth.tokensValidAfter)],
    ]), h("p.small.muted", t("user.tokenHint"))) : h("p.muted", t("user.noAuth")));

    const sessionCard = persona ? null : h("div.card", h("h2", t("users.session")), session ? kv([
      [t("users.device"), platformLabel(session.platform)], ["Device id", h("span.mono.small", session.deviceId)], [t("user.created"), fmtDate(session.startedAt)], [t("user.expires"), session.expiresAt ? fmtDate(session.expiresAt) : "∞"], [t("users.lastSeen"), fmtDate(session.lastSeenAt)],
    ]) : h("p.muted", t("users.noSession")));

    return h("div.cards", profileCard, entCard, authCard, sessionCard);
  }

  async function grantPremium() {
    const until = input({ type: "date" });
    const lock = toggle(true, () => {});
    modal({ title: t("user.setPremium"), body: h("div.stack", field(t("user.premiumUntil"), until, t("user.premiumForever")), h("div.field.inline", lock, h("label", t("user.adminLock")))), actions: [(c) => button(t("common.cancel"), { onclick: c }), (c) => { const b = button(t("common.save"), { kind: "primary" }); b.addEventListener("click", busy(b, async () => {
      try {
        const ms = until.value ? new Date(`${until.value}T23:59:59`).getTime() : undefined;
        await call("user.entitlement", { uid, premium: true, premiumUntil: ms, adminLock: lock.classList.contains("on") });
        ent = { ...(ent || {}), premium: true, premiumUntil: ms ? Timestamp.fromMillis(ms) : null, source: "admin", adminLock: lock.classList.contains("on") };
        renderHead(); renderTab(); toast(t("common.saved"), "ok"); c();
      } catch (e) { toastError(e); }
    })); return b; }] });
  }
  async function removePremium() {
    if (!(await confirmDialog({ title: t("user.removePremium"), danger: true, okLabel: t("user.removePremium") }))) return;
    try { await call("user.entitlement", { uid, premium: false, adminLock: true }); ent = { ...(ent || {}), premium: false, premiumUntil: null, source: "admin", adminLock: true }; renderHead(); renderTab(); toast(t("common.saved"), "ok"); } catch (e) { toastError(e); }
  }
  async function editProfile() {
    const name = input({ value: (user && user.fullName) || "" });
    const photo = input({ value: (user && user.photoUrl) || "" });
    modal({ title: t("user.editProfile"), body: h("div.stack", field(t("user.fullName"), name), field(t("user.photoUrl"), photo)), actions: [(c) => button(t("common.cancel"), { onclick: c }), (c) => { const b = button(t("common.save"), { kind: "primary" }); b.addEventListener("click", busy(b, async () => {
      try { await call("user.profile", { uid, fullName: name.value.trim(), photoUrl: photo.value.trim() }); toast(t("common.saved"), "ok"); c(); } catch (e) { toastError(e); }
    })); return b; }] });
  }

  // ---- content ----
  async function content() {
    const wrap = h("div.stack", h("p.small.muted", t("user.contentHint")));
    const roots = [["users", t("user.root.users")]];
    if (household) roots.push(["households", t("user.root.households")]);
    let root = household ? "households" : "users";
    let col = "recipes";
    const list = h("div");
    const render = async () => {
      clear(list);
      list.append(spinner());
      const rootId = root === "households" ? household.id : uid;
      const available = root === "households" ? COLLECTIONS.filter((c) => SHARED.has(c)) : COLLECTIONS;
      if (!available.includes(col)) col = available[0];
      const snap = await getDocs(query(collection(db, root, rootId, col), limit(500)));
      const docs = snap.docs.map((d) => ({ id: d.id, ...d.data() }));
      clear(list);
      list.append(h("div.toolbar", tabs(available.map((c) => [c, t(`user.collections.${c}`)]), col, (c) => { col = c; render(); }), h("span.muted.small", t("user.items", { n: docs.length }))));
      list.append(table([
        { label: t("common.title"), cell: (d) => h("div", h("div", docTitle(d) || t("common.unnamed")), h("div.small.muted.mono", d.id)) },
        { label: t("common.date"), cell: (d) => h("span.small", fmtDate(d.updatedAt || d.createdAt)) },
        { label: t("common.actions"), cell: (d) => h("div.row", button(t("user.editJson"), { kind: "small", onclick: () => editJson(root, rootId, col, d) }), button(t("common.delete"), { kind: "small danger", onclick: async () => {
          if (!(await confirmDialog({ title: `${t("common.delete")}: ${docTitle(d)}` }))) return;
          try { await call("user.content.delete", { root, rootId, collection: col, id: d.id }); toast(t("common.deleted"), "ok"); render(); } catch (e) { toastError(e); }
        } })) },
      ], docs));
    };
    wrap.append(h("div.row", roots.length > 1 ? tabs(roots, root, (r) => { root = r; render(); }) : null), list);
    render();
    return wrap;
  }

  function editJson(root, rootId, col, d) {
    const { id, ...rest } = d;
    const area = textarea({ value: JSON.stringify(toEditable({ id, ...rest }), null, 2), style: { minHeight: "60vh", fontFamily: "ui-monospace, Menlo, monospace", fontSize: "12.5px", direction: "ltr" } });
    modal({ title: `${t("user.editJson")}: ${docTitle(d)}`, wide: true, body: area, actions: [(c) => button(t("common.cancel"), { onclick: c }), (c) => { const b = button(t("common.save"), { kind: "primary" }); b.addEventListener("click", busy(b, async () => {
      let parsed;
      try { parsed = JSON.parse(area.value); } catch (_) { toast(t("common.invalidJson"), "error"); return; }
      try { await call("user.content.set", { root, rootId, collection: col, id, data: plain(fromEditable(parsed)) }); toast(t("common.saved"), "ok"); c(); renderTab(); } catch (e) { toastError(e); }
    })); return b; }] });
  }

  // ---- AI ----
  async function ai() {
    const [usageSnap, callsSnap] = await Promise.all([
      getDoc(doc(db, "ai_usage", uid)),
      getDocs(query(collection(db, "ai_calls"), where("uid", "==", uid), orderBy("at", "desc"), limit(40))).catch(() => ({ docs: [] })),
    ]);
    if (!usageSnap.exists()) return h("div.card", h("p.muted", t("user.noUsage")));
    const u = usageSnap.data();
    const models = Object.entries(u.models || {}).map(([k, v]) => ({ key: k, tally: tally(v) }));
    const kinds = Object.entries(u.kinds || {}).map(([k, v]) => ({ key: k, tally: tally(v) }));
    const cost = costIls(u.models, prices);
    return h("div.stack",
      h("div.tiles", h("div.tile.accent", h("div.label", t("dash.aiCost")), h("div.value", fmtMoney(cost))), h("div.tile", h("div.label", t("dash.aiCalls")), h("div.value", fmtNumber(tally(u.totals).calls))), h("div.tile", h("div.label", t("dash.tokens")), h("div.value", fmtNumber(tally(u.totals).total))), h("div.tile", h("div.label", t("users.lastSeen")), h("div.value.small", fmtDate(u.lastCallAt)))),
      h("div.grid2",
        h("div.card", h("h2", t("dash.byModel")), table([{ label: t("user.model"), cell: (r) => r.key.replace(/_/g, ".") }, { label: t("dash.calls"), num: true, cell: (r) => fmtNumber(r.tally.calls) }, { label: t("dash.tokens"), num: true, cell: (r) => fmtNumber(r.tally.total) }], models)),
        h("div.card", h("h2", t("dash.byKind")), table([{ label: t("user.kind"), cell: (r) => r.key }, { label: t("dash.calls"), num: true, cell: (r) => fmtNumber(r.tally.calls) }, { label: t("dash.tokens"), num: true, cell: (r) => fmtNumber(r.tally.total) }], kinds)),
      ),
      h("div.card", h("h2", t("user.recentCalls")), table([
        { label: t("user.when"), cell: (d) => h("span.small", fmtDate(d.at)) }, { label: "fn", cell: (d) => h("span.small", d.fn) }, { label: t("user.model"), cell: (d) => h("span.small", d.model) }, { label: t("user.kind"), cell: (d) => d.kind },
        { label: t("user.statusCol"), cell: (d) => badge(String(d.status), d.status === 200 ? "green" : "red") }, { label: t("user.ms"), num: true, cell: (d) => fmtNumber(d.ms) }, { label: t("dash.tokens"), num: true, cell: (d) => d.cacheHit ? "cache" : fmtNumber(d.totalTokens) },
      ], callsSnap.docs.map((d) => d.data()))),
    );
  }

  // ---- community ----
  async function community() {
    const [posts, recipes] = await Promise.all([
      getDocs(query(collection(db, "forum_posts"), where("authorUid", "==", uid), limit(200))),
      getDocs(query(collection(db, "shared_recipes"), where("authorUid", "==", uid), limit(200))),
    ]);
    return h("div.grid2",
      h("div.card", h("h2", t("user.posts")), table([
        { label: t("common.title"), cell: (p) => h("a", { href: `#/community/${p.id}` }, p.title) }, { label: t("forum.replies", { n: "" }).trim(), num: true, cell: (p) => fmtNumber(p.replyCount || 0) }, { label: "♥", num: true, cell: (p) => fmtNumber(p.likeCount || 0) }, { label: t("common.date"), cell: (p) => h("span.small", fmtDate(p.createdAt, false)) },
      ], posts.docs.map((d) => ({ id: d.id, ...d.data() })).sort((a, b) => (b.createdAt?.toMillis?.() || 0) - (a.createdAt?.toMillis?.() || 0)))),
      h("div.card", h("h2", t("user.sharedRecipes")), table([
        { label: t("common.title"), cell: (p) => h("a", { href: "#/recipes" }, p.title) }, { label: "♥", num: true, cell: (p) => fmtNumber(p.likeCount || 0) }, { label: t("common.date"), cell: (p) => h("span.small", fmtDate(p.createdAt, false)) },
      ], recipes.docs.map((d) => ({ id: d.id, ...d.data() })))),
    );
  }

  // ---- sharing ----
  async function sharing() {
    const [cr, cc, codes, invOut, invIn] = await Promise.all([
      getDocs(query(collection(db, "collab_recipes"), where("memberUids", "array-contains", uid), limit(200))),
      getDocs(query(collection(db, "collab_containers"), where("memberUids", "array-contains", uid), limit(200))),
      getDocs(query(collection(db, "share_codes"), where("ownerUid", "==", uid), limit(200))),
      getDocs(query(collection(db, "share_invites"), where("ownerUid", "==", uid), limit(200))),
      getDocs(query(collection(db, "share_invites"), where("targetUid", "==", uid), limit(200))),
    ]);
    const rows = (snap) => snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    const members = (r) => `${(r.memberUids || []).length} · ${r.ownerUid === uid ? t("user.owner") : (r.members && r.members[uid]) || ""}`;
    return h("div.stack",
      h("div.grid2",
        h("div.card", h("h2", t("user.collabRecipes")), table([{ label: t("common.title"), cell: (r) => r.title || r.id }, { label: t("user.members"), cell: members }], rows(cr))),
        h("div.card", h("h2", t("user.collabContainers")), table([{ label: t("common.title"), cell: (r) => r.title || r.name || r.id }, { label: t("user.kind2"), cell: (r) => r.kind }, { label: t("user.members"), cell: members }], rows(cc))),
      ),
      h("div.grid2",
        h("div.card", h("h2", t("user.shareCodes")), table([{ label: t("common.id"), cell: (r) => h("span.mono", r.id) }, { label: t("user.kind2"), cell: (r) => `${r.kind} · ${r.role}` }, { label: t("user.uses"), num: true, cell: (r) => fmtNumber(r.uses || 0) }, { label: t("common.status"), cell: (r) => r.revoked ? badge(t("user.revoked"), "red") : h("span.small", `${t("user.expires")} ${fmtDate(r.expiresAt, false)}`) }], rows(codes))),
        h("div.card", h("h2", t("user.invites")), table([{ label: t("user.kind2"), cell: (r) => r.kind || "recipe" }, { label: t("user.role"), cell: (r) => r.role }, { label: t("common.status"), cell: (r) => badge(r.status, r.status === "accepted" ? "green" : r.status === "declined" ? "red" : "amber") }, { label: "", cell: (r) => h("span.small.muted", r.ownerUid === uid ? "→" : "←") }], [...rows(invOut), ...rows(invIn)])),
      ),
    );
  }

  async function inbox() {
    const snap = await getDocs(query(collection(db, "notifications", uid, "items"), orderBy("createdAt", "desc"), limit(50)));
    return h("div.card", table([
      { label: t("user.when"), cell: (d) => h("span.small", fmtDate(d.createdAt)) }, { label: t("user.kind2"), cell: (d) => badge(d.type, d.read ? "" : "brand") }, { label: t("common.body"), cell: (d) => h("span.small", d.title ? `${d.title} — ` : "", d.message || d.body || d.excerpt || "") },
    ], snap.docs.map((d) => d.data())));
  }

  async function tickets() {
    const snap = await getDocs(query(collection(db, "feedback"), where("authorUid", "==", uid), limit(100)));
    return h("div.card", table([
      { label: t("user.when"), cell: (d) => h("span.small", fmtDate(d.createdAt)) }, { label: t("user.kind2"), cell: (d) => badge(t(`tickets.types.${d.type}`), d.type === "bug" ? "red" : "amber") }, { label: t("common.body"), cell: (d) => h("span.small.pre", d.message) }, { label: t("tickets.replied"), cell: (d) => (d.replies || []).length ? badge(String(d.replies.length), "green") : "—" },
    ], snap.docs.map((d) => d.data()).sort((a, b) => (b.createdAt?.toMillis?.() || 0) - (a.createdAt?.toMillis?.() || 0))));
  }

  // Live: the online dot and the last-seen stamp follow the heartbeat.
  let hadUser = false;
  const unsub = onSnapshot(doc(db, "users", uid), (snap) => {
    user = snap.exists() ? { uid, ...snap.data() } : null;
    renderHead();
    // The first tab may have been drawn before the document arrived.
    if (user && !hadUser && active === "overview") renderTab();
    hadUser = hadUser || !!user;
  }, (err) => { console.error(err); renderHead(); });
  const tick = setInterval(renderHead, 30000);
  renderHead();
  renderTab();
  return () => { unsub(); clearInterval(tick); };
}
