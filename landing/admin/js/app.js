// The console's shell: sign-in gate, language, navigation and the hash
// router that mounts one view at a time.
import { watchAuth, signInWithGoogle, signOut, isAdminUser, db, collection, onSnapshot, query, where, limit } from "./firebase.js";
import { LANGS, detectLang, setLang, currentLang, onLangChange, t } from "./i18n.js";
import { h, clear, avatar, toast } from "./ui.js";
import * as dashboard from "./views/dashboard.js";
import * as users from "./views/users.js";
import * as user from "./views/user.js";
import * as community from "./views/community.js";
import * as recipes from "./views/recipes.js";
import * as personas from "./views/personas.js";
import * as households from "./views/households.js";
import * as tickets from "./views/tickets.js";
import * as config from "./views/config.js";
import * as audit from "./views/audit.js";
import * as seed from "./views/seed.js";
import * as stores from "./views/stores.js";
import * as notifications from "./views/notifications.js";
import * as whatsnew from "./views/whatsnew.js";

const ICONS = {
  dashboard: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="7" height="9" rx="1.5"/><rect x="14" y="3" width="7" height="5" rx="1.5"/><rect x="14" y="12" width="7" height="9" rx="1.5"/><rect x="3" y="16" width="7" height="5" rx="1.5"/></svg>',
  users: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="9" cy="8" r="4"/><path d="M2 21a7 7 0 0 1 14 0"/><circle cx="17" cy="9" r="3"/><path d="M22 20a5 5 0 0 0-6-4.9"/></svg>',
  community: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12a8 8 0 0 1-11.6 7.1L4 21l1.9-5.4A8 8 0 1 1 21 12z"/></svg>',
  recipes: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 19V5a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v14"/><path d="M4 19a2 2 0 0 0 2 2h14"/><path d="M8 7h8M8 11h8"/></svg>',
  personas: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/><path d="M19 3l2 2-2 2M5 3 3 5l2 2"/></svg>',
  households: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 11 12 3l9 8"/><path d="M5 10v10h14V10"/><path d="M10 20v-6h4v6"/></svg>',
  tickets: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="5" width="18" height="14" rx="2"/><path d="m3 7 9 6 9-6"/></svg>',
  config: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 6h10M18 6h2M4 12h2M10 12h10M4 18h8M16 18h4"/><circle cx="16" cy="6" r="2"/><circle cx="8" cy="12" r="2"/><circle cx="14" cy="18" r="2"/></svg>',
  seed: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 3v18M3 12h18"/><circle cx="12" cy="12" r="9"/></svg>',
  stores: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 3v12"/><path d="m7 10 5 5 5-5"/><path d="M4 17v2a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-2"/></svg>',
  notifications: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/></svg>',
  audit: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 8v4l3 2"/><circle cx="12" cy="12" r="9"/></svg>',
  whatsnew: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="m12 3 2.2 4.6 5 .7-3.6 3.5.9 5-4.5-2.4L7.5 16.8l.9-5L4.8 8.3l5-.7z"/></svg>',
};

const ROUTES = [
  { key: "dashboard", path: /^\/dashboard$/, view: dashboard },
  { key: "users", path: /^\/users$/, view: users },
  { key: "users", path: /^\/users\/([^/]+)$/, view: user, title: () => t("user.profile") },
  { key: "community", path: /^\/community(?:\/([^/]+))?$/, view: community },
  { key: "recipes", path: /^\/recipes$/, view: recipes },
  { key: "personas", path: /^\/personas$/, view: personas },
  { key: "seed", path: /^\/seed$/, view: seed },
  { key: "households", path: /^\/households$/, view: households },
  { key: "tickets", path: /^\/tickets$/, view: tickets },
  { key: "notifications", path: /^\/notifications$/, view: notifications },
  { key: "whatsnew", path: /^\/whatsnew$/, view: whatsnew },
  { key: "config", path: /^\/config$/, view: config },
  { key: "stores", path: /^\/stores$/, view: stores },
  { key: "audit", path: /^\/audit$/, view: audit },
];

let unmount = null;
let currentUser = null;
// Views mount asynchronously; a navigation that lands while an earlier one
// is still awaiting must win, and the earlier view's listeners must stop.
let mountSeq = 0;

function els() {
  return {
    gate: document.getElementById("gate"),
    shell: document.getElementById("shell"),
    nav: document.getElementById("nav"),
    view: document.getElementById("view"),
    title: document.getElementById("pageTitle"),
    actions: document.getElementById("pageActions"),
    me: document.getElementById("me"),
  };
}

// Open unread tickets, counted from their own bounded query (not the
// tickets page's newest 500), so the badge is right on every page and
// beyond 500 tickets. Shown as "99+" past the cap.
const UNREAD_CAP = 100;
let unreadTickets = 0;
let unreadCapped = false;
let stopUnread = null;
const unreadText = () => (unreadCapped ? `${UNREAD_CAP - 1}+` : String(unreadTickets));
function watchUnreadTickets() {
  if (stopUnread) return;
  stopUnread = onSnapshot(query(collection(db, "feedback"), where("read", "==", false), limit(UNREAD_CAP)), (snap) => {
    unreadTickets = snap.docs.filter((d) => d.get("status") !== "closed").length;
    unreadCapped = snap.size >= UNREAD_CAP && unreadTickets > 0;
    const el = document.getElementById("ticketsBadge");
    if (el) { el.hidden = !unreadTickets; el.textContent = unreadText(); }
  }, () => {});
}
function stopUnreadTickets() {
  if (stopUnread) { stopUnread(); stopUnread = null; }
  unreadTickets = 0;
  unreadCapped = false;
}

function renderNav() {
  const { nav } = els();
  clear(nav);
  const route = location.hash.slice(1) || "/dashboard";
  for (const key of ["dashboard", "stores", "users", "seed", "community", "recipes", "personas", "households", "tickets", "notifications", "whatsnew", "config", "audit"]) {
    const here = route.startsWith("/" + key);
    const a = h(`a${here ? ".active" : ""}`, { href: `#/${key}`, html: ICONS[key], ...(here ? { "aria-current": "page" } : {}) });
    a.append(h("span", t(`nav.${key}`)));
    if (key === "tickets") a.append(h("span.badge.brand", { id: "ticketsBadge", hidden: !unreadTickets }, unreadText()));
    nav.append(a);
  }
}

function langOptions(selectEl) {
  clear(selectEl);
  for (const [code, name] of Object.entries(LANGS)) selectEl.append(h("option", { value: code, selected: code === currentLang() }, name));
}

async function mount() {
  const { view, title, actions } = els();
  if (unmount) {
    try { unmount(); } catch (_) {}
    unmount = null;
  }
  clear(view);
  clear(actions);
  const path = location.hash.slice(1) || "/dashboard";
  const route = ROUTES.find((r) => r.path.test(path));
  if (!route) {
    location.hash = "#/dashboard";
    return;
  }
  const params = path.match(route.path).slice(1);
  title.textContent = route.title ? route.title() : t(`nav.${route.key}`);
  renderNav();
  document.querySelector(".sidebar").classList.remove("open");
  const seq = ++mountSeq;
  try {
    const stop = await route.view.mount({ view, actions, params, user: currentUser, setTitle: (s) => { if (seq === mountSeq) title.textContent = s; } });
    if (seq !== mountSeq) {
      // Superseded while mounting: tear it down instead of leaking it.
      if (typeof stop === "function") { try { stop(); } catch (_) {} }
      return;
    }
    unmount = stop;
  } catch (err) {
    if (seq !== mountSeq) return;
    console.error(err);
    view.append(h("div.card.error", err.message || t("common.error")));
  }
}

function showGate(message) {
  const { gate, shell } = els();
  shell.hidden = true;
  gate.hidden = false;
  const err = document.getElementById("gateError");
  err.hidden = !message;
  err.textContent = message || "";
}

function showShell(user) {
  const { gate, shell, me } = els();
  gate.hidden = true;
  shell.hidden = false;
  clear(me);
  me.append(avatar(user.displayName || user.email, user.photoURL, "sm"), h("span.ellipsis", user.email));
  watchUnreadTickets();
  mount();
}

function init() {
  setLang(detectLang());
  const gateLang = document.getElementById("gateLang");
  const langSel = document.getElementById("langSel");
  langOptions(gateLang);
  langOptions(langSel);
  const onPick = (e) => { setLang(e.target.value); langOptions(gateLang); langOptions(langSel); };
  gateLang.addEventListener("change", onPick);
  langSel.addEventListener("change", onPick);
  onLangChange(() => { if (currentUser) mount(); });

  document.getElementById("gateSignIn").addEventListener("click", async () => {
    const btn = document.getElementById("gateSignIn");
    btn.disabled = true;
    try {
      const user = await signInWithGoogle();
      if (!(await isAdminUser(user))) {
        await signOut();
        showGate(t("gate.notAdmin"));
      }
    } catch (err) {
      const code = err && err.code ? String(err.code) : "";
      if (code === "auth/unauthorized-domain") showGate(t("gate.unauthorizedDomain"));
      else if (code !== "auth/popup-closed-by-user" && code !== "auth/cancelled-popup-request") showGate(t("gate.failed", { reason: code || err.message }));
    } finally {
      btn.disabled = false;
    }
  });
  document.getElementById("signOut").addEventListener("click", () => signOut());
  const navToggle = document.getElementById("navToggle");
  navToggle.setAttribute("aria-expanded", "false");
  navToggle.addEventListener("click", () => navToggle.setAttribute("aria-expanded", String(document.querySelector(".sidebar").classList.toggle("open"))));
  window.addEventListener("hashchange", () => { if (currentUser) mount(); });

  let authGen = 0;
  watchAuth(async (user) => {
    // A sign-out (or another account) while the admin check below is in
    // flight makes this callback stale: it must not open the shell.
    const gen = ++authGen;
    const splash = document.getElementById("splash");
    if (splash) splash.remove();
    if (user) {
      let admin;
      try {
        admin = await isAdminUser(user);
      } catch (err) {
        if (gen !== authGen) return;
        currentUser = null;
        showGate(t("gate.failed", { reason: err?.code || "network" }));
        return;
      }
      if (gen !== authGen) return;
      if (!admin) {
        await signOut();
        currentUser = null;
        showGate(t("gate.notAdmin"));
        return;
      }
    }
    currentUser = user;
    if (user) showShell(user);
    else {
      // A mount still awaiting must not install listeners after sign-out.
      mountSeq++;
      stopUnreadTickets();
      if (unmount) { try { unmount(); } catch (_) {} unmount = null; }
      showGate();
    }
  });
}

init();
