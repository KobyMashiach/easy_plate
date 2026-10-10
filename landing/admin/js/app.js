// The console's shell: sign-in gate, language, navigation and the hash
// router that mounts one view at a time.
import { watchAuth, signInWithGoogle, signOut, isAdminUser } from "./firebase.js";
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
  audit: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 8v4l3 2"/><circle cx="12" cy="12" r="9"/></svg>',
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
  { key: "config", path: /^\/config$/, view: config },
  { key: "stores", path: /^\/stores$/, view: stores },
  { key: "audit", path: /^\/audit$/, view: audit },
];

let unmount = null;
let currentUser = null;

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

function renderNav() {
  const { nav } = els();
  clear(nav);
  const route = location.hash.slice(1) || "/dashboard";
  for (const key of ["dashboard", "stores", "users", "seed", "community", "recipes", "personas", "households", "tickets", "config", "audit"]) {
    const a = h(`a${route.startsWith("/" + key) ? ".active" : ""}`, { href: `#/${key}`, html: ICONS[key] });
    a.append(h("span", t(`nav.${key}`)));
    if (key === "tickets") a.append(h("span.badge.brand", { id: "ticketsBadge", hidden: true }));
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
  try {
    unmount = await route.view.mount({ view, actions, params, user: currentUser, setTitle: (s) => { title.textContent = s; } });
  } catch (err) {
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
      if (!isAdminUser(user)) {
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
  document.getElementById("navToggle").addEventListener("click", () => document.querySelector(".sidebar").classList.toggle("open"));
  window.addEventListener("hashchange", () => { if (currentUser) mount(); });

  watchAuth(async (user) => {
    const splash = document.getElementById("splash");
    if (splash) splash.remove();
    if (user && !isAdminUser(user)) {
      await signOut();
      currentUser = null;
      showGate(t("gate.notAdmin"));
      return;
    }
    currentUser = user;
    if (user) showShell(user);
    else {
      if (unmount) { try { unmount(); } catch (_) {} unmount = null; }
      showGate();
    }
  });
}

init();
