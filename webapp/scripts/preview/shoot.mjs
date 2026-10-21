// Screenshots of every web-app route, phone and desktop, against the local
// emulators — the web half of the native/web parity harness.
//
//   npm run preview:shoot                 everything (starts what is not running)
//   node scripts/preview/shoot.mjs --dark            also out/web-dark/
//   node scripts/preview/shoot.mjs --only recipes    routes whose path contains "recipes"
//   node scripts/preview/shoot.mjs --no-seed         keep the emulators' current data
//   node scripts/preview/shoot.mjs --household       seed with a Pro Family household
//   node scripts/preview/shoot.mjs --compare-only    rebuild out/compare.html only
//
// What it does: starts the Firebase emulators (auth, firestore, storage —
// project demo-easyplate, firebase.json here) unless they already answer,
// seeds them (seed.mjs), serves a stub for the Cloud Functions, runs the
// Vite dev server in emulator mode (VITE_EMULATORS=1), drives headless
// Chrome over the DevTools protocol (Node's built-in WebSocket, no npm
// dependency) and writes
//   out/web/<route>.png          390×844 @2x, full page
//   out/web/<route>.top.png      390×844 @2x, first viewport
//   out/web-desktop/<route>.png  1440×900, first viewport
//   out/web/report.json          per route: final URL, errors, settle time
// Nothing here talks to production: the app's emulator mode uses a demo-*
// project and local hosts only, and the functions origin is the stub below.
import { spawn, spawnSync } from "node:child_process";
import { copyFileSync, existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { createServer } from "node:http";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { customToken, loadSample, PORTS, seed } from "./seed.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const webapp = join(here, "../..");
const repo = join(webapp, "..");
// PREVIEW_OUT lets parallel runs keep their own shots (default out/).
const OUT = process.env.PREVIEW_OUT || join(here, "out");
const VITE_PORT = 5188;
const BASE = `http://127.0.0.1:${VITE_PORT}/app`;
const CHROME = process.env.CHROME_BIN || "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
// The emulators need Java 21+. PREVIEW_JAVA_HOME wins; then the JDK 21 this
// harness was built with, if it is still there; then the shell's JAVA_HOME.
const BUNDLED_JDK = "/private/tmp/claude-502/-Users-koby-development-easy-plate/1f84c502-89a2-445b-9690-43a94447646f/scratchpad/jdk/jdk-21.0.12.1+1/Contents/Home";
const JAVA_HOME = process.env.PREVIEW_JAVA_HOME || (existsSync(BUNDLED_JDK) ? BUNDLED_JDK : process.env.JAVA_HOME);

const args = process.argv.slice(2);
const flag = (name) => args.includes(`--${name}`);
const opt = (name) => {
  const i = args.indexOf(`--${name}`);
  return i >= 0 ? args[i + 1] : null;
};

const children = [];
async function cleanup() {
  const waits = [];
  for (const c of children.splice(0)) {
    if (c.exitCode !== null) continue;
    // The emulators shut down cleanly on SIGINT to the CLI itself (it stops
    // its Java children); Chrome and Vite go with SIGTERM to their group.
    const emulators = c.spawnargs.includes("emulators:start");
    waits.push(new Promise((r) => (c.once("exit", r), setTimeout(r, 15000))));
    try {
      if (emulators) c.kill("SIGINT");
      else process.kill(-c.pid, "SIGTERM");
    } catch (_) {
      try {
        c.kill("SIGTERM");
      } catch (_) {
        /* gone */
      }
    }
  }
  await Promise.all(waits);
}
process.on("SIGINT", () => {
  cleanup().then(() => process.exit(130));
});

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
async function answers(url) {
  try {
    await fetch(url, { signal: AbortSignal.timeout(1500) });
    return true;
  } catch (_) {
    return false;
  }
}
async function waitFor(url, what, timeoutMs = 120_000) {
  const t0 = Date.now();
  while (Date.now() - t0 < timeoutMs) {
    if (await answers(url)) return;
    await sleep(500);
  }
  throw new Error(`${what} did not come up at ${url}`);
}

// ── Emulators ────────────────────────────────────────────────────────────
async function ensureEmulators() {
  const up = await Promise.all([PORTS.auth, PORTS.firestore, PORTS.storage].map((p) => answers(`http://127.0.0.1:${p}/`)));
  if (up.every(Boolean)) {
    console.log("emulators: already running");
    return;
  }
  if (up.some(Boolean)) throw new Error("Only some emulators answer (a previous run still shutting down?): stop them (`pkill -f emulators:start`) and run again.");
  // The emulator refuses rules outside its config folder: copy the repo's.
  mkdirSync(join(here, ".emulator"), { recursive: true });
  copyFileSync(join(repo, "firestore.rules"), join(here, ".emulator/firestore.rules"));
  copyFileSync(join(repo, "storage.rules"), join(here, ".emulator/storage.rules"));
  const env = { ...process.env, JAVA_HOME, PATH: `${JAVA_HOME}/bin:${process.env.PATH}` };
  const log = join(OUT, "emulators.log");
  mkdirSync(OUT, { recursive: true });
  const { openSync } = await import("node:fs");
  const fd = openSync(log, "w");
  const child = spawn("firebase", ["emulators:start", "--only", "auth,firestore,storage", "--project", "demo-easyplate", "--config", "firebase.json"], {
    cwd: here,
    env,
    stdio: ["ignore", fd, fd],
    detached: true,
  });
  children.push(child);
  console.log(`emulators: starting (log ${log})`);
  try {
    await waitFor(`http://127.0.0.1:${PORTS.auth}/`, "Auth emulator");
  } catch (e) {
    console.error(readFileSync(log, "utf8").split("\n").slice(-12).join("\n"));
    throw e;
  }
  await waitFor(`http://127.0.0.1:${PORTS.firestore}/`, "Firestore emulator");
  await waitFor(`http://127.0.0.1:${PORTS.storage}/`, "Storage emulator");
}

// ── Cloud Functions stub ─────────────────────────────────────────────────
// The few calls a page makes on load get a plausible answer; anything else
// is a clean 503 the pages already handle. Prices are sample values.
const SAMPLE_PLANS = {
  enabled: true,
  flag: 2,
  plans: [
    { priceId: "price_pro_month", lookupKey: "pro_monthly", tier: "pro", seats: 1, interval: "month", intervalCount: 1, amount: 2490, currency: "ils", name: "Easy Plate Pro", description: null, introCoupon: null, introAmount: null },
    { priceId: "price_pro_year", lookupKey: "pro_yearly", tier: "pro", seats: 1, interval: "year", intervalCount: 1, amount: 19900, currency: "ils", name: "Easy Plate Pro", description: null, introCoupon: null, introAmount: null },
    { priceId: "price_duo_year", lookupKey: "duo_yearly", tier: "duo", seats: 2, interval: "year", intervalCount: 1, amount: 27900, currency: "ils", name: "Easy Plate Pro Duo", description: null, introCoupon: null, introAmount: null },
    { priceId: "price_family_year", lookupKey: "family_yearly", tier: "family", seats: 6, interval: "year", intervalCount: 1, amount: 34900, currency: "ils", name: "Easy Plate Pro Family", description: null, introCoupon: null, introAmount: null },
  ],
};
function startFunctionsStub() {
  return new Promise((resolve) => {
    const server = createServer((req, res) => {
      res.setHeader("Access-Control-Allow-Origin", "*");
      res.setHeader("Access-Control-Allow-Headers", "*");
      res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
      if (req.method === "OPTIONS") return res.end();
      let body = "";
      req.on("data", (c) => (body += c));
      req.on("end", () => {
        const fn = (req.url || "").split("/")[3] || "";
        let json = {};
        try {
          json = JSON.parse(body || "{}");
        } catch (_) {
          /* not JSON */
        }
        res.setHeader("Content-Type", "application/json");
        if (fn === "webBilling" && json.action === "plans") return res.end(JSON.stringify(SAMPLE_PLANS));
        if (fn === "priceStats") return res.end(JSON.stringify({ ok: true }));
        res.statusCode = 503;
        res.end(JSON.stringify({ error: { code: "unavailable", message: `preview stub: ${fn} is not emulated` } }));
      });
    });
    server.on("error", () => resolve(null)); // already served (an earlier run)
    server.listen(PORTS.functions, "127.0.0.1", () => resolve(server));
  });
}

// ── Vite (emulator mode) ─────────────────────────────────────────────────
async function ensureVite() {
  if (await answers(`${BASE}/`)) {
    console.log(`vite: reusing the server on :${VITE_PORT} (it must have been started with VITE_EMULATORS=1)`);
    return;
  }
  spawnSync("node", ["scripts/split-i18n.mjs"], { cwd: webapp, stdio: "ignore" });
  const child = spawn("npx", ["vite", "--port", String(VITE_PORT), "--strictPort", "--host", "127.0.0.1"], {
    cwd: webapp,
    env: { ...process.env, VITE_EMULATORS: "1" },
    stdio: "ignore",
    detached: true,
  });
  children.push(child);
  await waitFor(`${BASE}/`, "Vite dev server", 60_000);
  console.log(`vite: ${BASE} (emulator mode)`);
}

// ── Chrome over the DevTools protocol ────────────────────────────────────
class Cdp {
  constructor(ws) {
    this.ws = ws;
    this.id = 0;
    this.pending = new Map();
    this.handlers = new Set();
    ws.addEventListener("message", (ev) => {
      const msg = JSON.parse(typeof ev.data === "string" ? ev.data : Buffer.from(ev.data).toString());
      if (msg.id && this.pending.has(msg.id)) {
        const { resolve, reject } = this.pending.get(msg.id);
        this.pending.delete(msg.id);
        msg.error ? reject(new Error(`${msg.error.message} ${msg.error.data || ""}`)) : resolve(msg.result);
      } else if (msg.method) {
        for (const h of this.handlers) h(msg);
      }
    });
  }
  static async connect(url) {
    const ws = new WebSocket(url);
    await new Promise((res, rej) => {
      ws.addEventListener("open", res, { once: true });
      ws.addEventListener("error", rej, { once: true });
    });
    return new Cdp(ws);
  }
  send(method, params = {}, sessionId) {
    const id = ++this.id;
    this.ws.send(JSON.stringify({ id, method, params, ...(sessionId ? { sessionId } : {}) }));
    return new Promise((resolve, reject) => this.pending.set(id, { resolve, reject }));
  }
  on(h) {
    this.handlers.add(h);
    return () => this.handlers.delete(h);
  }
}

async function launchChrome() {
  const profile = mkdtempSync(join(tmpdir(), "easyplate-preview-chrome-"));
  const child = spawn(
    CHROME,
    ["--headless=new", "--remote-debugging-port=0", `--user-data-dir=${profile}`, "--no-first-run", "--no-default-browser-check", "--hide-scrollbars", "--disable-extensions", "--lang=he-IL", "--force-color-profile=srgb", "about:blank"],
    { stdio: "ignore", detached: true },
  );
  children.push(child);
  let port = null;
  for (let i = 0; i < 100 && !port; i++) {
    await sleep(100);
    try {
      port = readFileSync(join(profile, "DevToolsActivePort"), "utf8").split("\n")[0];
    } catch (_) {
      /* not yet */
    }
  }
  if (!port) throw new Error("Chrome did not start (DevToolsActivePort missing)");
  const { webSocketDebuggerUrl } = await (await fetch(`http://127.0.0.1:${port}/json/version`)).json();
  return { cdp: await Cdp.connect(webSocketDebuggerUrl), profile };
}

const IPHONE_UA =
  "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1";

async function openPage(cdp, { width, height, dpr, mobile, dark }) {
  // A browser context of its own: its own cookies, storage and — what
  // matters — its own connection pool, so no earlier page's Firestore
  // streams can hold the six connections Chrome allows per host.
  const { browserContextId } = await cdp.send("Target.createBrowserContext", { disposeOnDetach: true });
  const { targetId } = await cdp.send("Target.createTarget", { url: "about:blank", browserContextId });
  const { sessionId } = await cdp.send("Target.attachToTarget", { targetId, flatten: true });
  const s = (m, p) => cdp.send(m, p, sessionId);
  await s("Page.enable");
  await s("Runtime.enable");
  const metrics = { width, height, deviceScaleFactor: dpr, mobile, screenWidth: width, screenHeight: height };
  await s("Emulation.setDeviceMetricsOverride", metrics);
  if (mobile) {
    await s("Emulation.setTouchEmulationEnabled", { enabled: true, maxTouchPoints: 5 });
    await s("Emulation.setUserAgentOverride", { userAgent: IPHONE_UA, acceptLanguage: "he-IL,he", platform: "iPhone" });
  } else {
    await s("Emulation.setUserAgentOverride", { userAgent: (await cdp.send("Browser.getVersion")).userAgent.replace("HeadlessChrome", "Chrome"), acceptLanguage: "he-IL,he" });
  }
  await s("Emulation.setLocaleOverride", { locale: "he-IL" }).catch(() => {});
  await s("Emulation.setTimezoneOverride", { timezoneId: "Asia/Jerusalem" }).catch(() => {});
  await s("Emulation.setEmulatedMedia", {
    features: [
      { name: "prefers-color-scheme", value: dark ? "dark" : "light" },
      { name: "prefers-reduced-motion", value: "reduce" },
    ],
  });
  // Hebrew and the theme before any app code runs (the keys the site reads).
  await s("Page.addScriptToEvaluateOnNewDocument", {
    source: `try { localStorage.setItem("ep-lang", "he"); localStorage.setItem("ep-theme", ${JSON.stringify(dark ? "dark" : "light")}); } catch (_) {}`,
  });
  // Hosting serves the landing site's root files (/icon-64.png…) next to
  // /app; the Vite dev server does not, so they are answered from landing/.
  await s("Fetch.enable", { patterns: ["*.png", "*.svg", "*.ico", "*.jpg", "*.webp"].map((urlPattern) => ({ urlPattern: `http://127.0.0.1:${VITE_PORT}/${urlPattern}` })) });
  const errors = [];
  // Requests still open, so a page that never settles can say what it waits on.
  const inflight = new Map();
  await s("Network.enable");
  cdp.on((msg) => {
    if (msg.sessionId !== sessionId) return;
    if (msg.method === "Network.requestWillBeSent") inflight.set(msg.params.requestId, msg.params.request.url);
    if (msg.method === "Network.loadingFinished" || msg.method === "Network.loadingFailed") inflight.delete(msg.params.requestId);
    if (msg.method === "Fetch.requestPaused") {
      const { pathname } = new URL(msg.params.request.url);
      const file = join(repo, "landing", decodeURIComponent(pathname));
      if (!pathname.startsWith("/app/") && !pathname.includes("..") && existsSync(file)) {
        const type = { png: "image/png", svg: "image/svg+xml", ico: "image/x-icon", jpg: "image/jpeg", webp: "image/webp" }[pathname.split(".").pop()];
        s("Fetch.fulfillRequest", { requestId: msg.params.requestId, responseCode: 200, responseHeaders: [{ name: "Content-Type", value: type }], body: readFileSync(file).toString("base64") }).catch(() => {});
      } else {
        s("Fetch.continueRequest", { requestId: msg.params.requestId }).catch(() => {});
      }
      return;
    }
    if (msg.method === "Runtime.exceptionThrown") errors.push(msg.params.exceptionDetails?.exception?.description?.split("\n")[0] || msg.params.exceptionDetails?.text);
    if (msg.method === "Runtime.consoleAPICalled" && msg.params.type === "error") {
      errors.push(msg.params.args.map((a) => a.value ?? a.description ?? "").join(" ").slice(0, 300));
    }
  });
  return { s, sessionId, targetId, browserContextId, errors, metrics, inflight };
}

async function closePage(cdp, page) {
  await cdp.send("Target.closeTarget", { targetId: page.targetId }).catch(() => {});
  await cdp.send("Target.disposeBrowserContext", { browserContextId: page.browserContextId }).catch(() => {});
}

async function evaluate(s, expression) {
  const r = await s("Runtime.evaluate", { expression, awaitPromise: true, returnByValue: true });
  if (r.exceptionDetails) throw new Error(r.exceptionDetails.exception?.description || r.exceptionDetails.text);
  return r.result.value;
}

// Settled = fonts loaded, no spinner, every eager <img> decoded, nothing new for
// 700 ms (12 s at most — a page that never settles is reported, not hung on).
const SETTLE = `(async () => {
  const FONTS = ["500", "600", "700", "800"].flatMap((w) => [w + ' 16px Heebo', w + ' 16px "Plus Jakarta Sans"']).concat(['24px "Material Icons Round"']);
  await Promise.race([Promise.all(FONTS.map((f) => document.fonts.load(f, f.includes("Material") ? "add" : "אבג abc").catch(() => null))), new Promise((r) => setTimeout(r, 8000))]);
  const t0 = performance.now();
  await Promise.race([document.fonts.ready, new Promise((r) => setTimeout(r, 8000))]);
  let quietSince = performance.now(), last = "", why = "";
  while (performance.now() - t0 < 12000) {
    const root = document.getElementById("root");
    const spinner = root && document.querySelector('.animate-spin,[aria-busy="true"]');
    // A lazy picture below the fold never loads until scrolled to: not a wait.
    const imgs = [...document.images].filter((i) => !i.complete && i.loading !== "lazy");
    const sig = (root ? root.innerHTML.length : 0) + ":" + document.images.length;
    why = !root || !root.children.length ? "empty root" : spinner ? "spinner " + (spinner.className || spinner.getAttribute("aria-busy")).toString().slice(0, 60) : imgs.length ? "image " + imgs[0].src.slice(0, 80) : sig !== last ? "DOM changing" : "";
    if (why) quietSince = performance.now();
    last = sig;
    if (performance.now() - quietSince > 700) { await Promise.race([document.fonts.ready, new Promise((r) => setTimeout(r, 2000))]); await new Promise((r) => setTimeout(r, 300)); return { settledMs: Math.round(performance.now() - t0), timedOut: false }; }
    await new Promise((r) => setTimeout(r, 100));
  }
  return { settledMs: Math.round(performance.now() - t0), timedOut: true, why };
})()`;

async function navigate(page, url) {
  const loaded = new Promise((resolve) => {
    const t = setTimeout(resolve, 30000);
    page.loadWaiter = () => {
      clearTimeout(t);
      resolve();
    };
  });
  await page.s("Page.navigate", { url });
  await loaded;
}

async function shoot(cdp, page, file, { full, width }) {
  const shot = async (params) => Buffer.from((await page.s("Page.captureScreenshot", { format: "png", ...params })).data, "base64");
  if (!full) return writeFileSync(file, await shot({}));
  // The whole page as one tall viewport, so fixed bars (the dock, the top
  // bar) sit at its edges as they would at the end of a scroll.
  const height = Math.min(16000, await evaluate(page.s, "Math.ceil(Math.max(document.documentElement.scrollHeight, document.body.scrollHeight))"));
  const m = page.metrics;
  if (height <= m.height) return writeFileSync(file, await shot({}));
  await page.s("Emulation.setDeviceMetricsOverride", { ...m, height, screenHeight: height });
  // Everything is in view now: the lazy pictures load too.
  await evaluate(page.s, `(async () => { const t0 = performance.now(); while (performance.now() - t0 < 5000 && [...document.images].some((i) => !i.complete)) await new Promise((r) => setTimeout(r, 100)); })()`);
  await sleep(300);
  try {
    writeFileSync(file, await shot({}));
  } finally {
    await page.s("Emulation.setDeviceMetricsOverride", m);
    await sleep(150);
  }
}

// ── Routes ───────────────────────────────────────────────────────────────
function featureRoutes() {
  const out = [];
  const dir = join(webapp, "src/features");
  for (const f of readdirSync(dir)) {
    const file = join(dir, f, "routes.tsx");
    if (!existsSync(file)) continue;
    const text = readFileSync(file, "utf8");
    for (const m of text.matchAll(/path:\s*"([^"]+)"([^}]*)/g)) out.push({ path: m[1], bare: /bare:\s*true/.test(m[2]), feature: f });
  }
  return out;
}

function routeList(sample) {
  const ids = {
    "/recipes/:id": sample.recipes[1].id,
    "/recipes/:id/edit": sample.recipes[1].id,
    "/cook/:id": sample.recipes[1].id,
    "/cook/community/:postId": sample.shared_recipes[0].id,
    "/community/recipe/:id": sample.shared_recipes[0].id,
    "/community/thread/:id": sample.forum_posts[0].id,
    "/groceries/:id": sample.grocery_lists[0].id,
    "/library/:id": sample.books[0].id,
    "/plans/:id": sample.meal_plans[0].id,
    "/prices/receipts/:id": sample.receipts[0].id,
    "/support/:id": sample.feedback[0].id,
    "/join/:code": "PREVIEW1",
    "/upgrade/:token": "preview-token",
  };
  const app = [
    { path: "/account" },
    { path: "/checkout/success" },
    { path: "/menu" },
    { path: "/phone" },
    { path: "/pricing" },
  ];
  const signedOut = ["/login", "/link", "/upgrade", "/pricing"].map((path) => ({ path, signedOut: true }));
  const extra = [
    // The same page in its other states.
    { path: "/sharing/share", query: `?kind=recipe&id=${sample.recipes[2].id}`, name: "sharing_share_recipe" },
    { path: "/nutrition", query: `?plan=${sample.meal_plans[0].id}`, name: "nutrition_plan" },
    { path: "/groceries/:id", url: `/groceries/${sample.grocery_lists[1].id}`, name: "groceries_id_recipe_list" },
    { path: "/assistant", query: `?scope=recipe&id=${sample.recipes[1].id}`, name: "assistant_scoped_recipe" },
    { path: "/not-a-page", name: "not_found" },
  ];
  const all = [...signedOut, ...featureRoutes(), ...app, ...extra];
  const seen = new Set();
  return all
    .map((r) => {
      const url = r.url ?? r.path.replace(/:[a-zA-Z]+/g, () => ids[r.path] ?? "x") + (r.query ?? "");
      const slug = r.name ?? ((r.signedOut ? "signed_out_" : "") + (r.path.replace(/^\//, "").replace(/[/:]+/g, "_").replace(/_+/g, "_") || "root"));
      return { ...r, url, slug };
    })
    .filter((r) => (seen.has(r.slug) ? false : seen.add(r.slug)));
}

// ── Main ─────────────────────────────────────────────────────────────────
async function main() {
  if (flag("compare-only")) {
    // After `npm run preview:native`: rebuild the side-by-side page only.
    const read = (d) => (existsSync(join(OUT, d, "report.json")) ? JSON.parse(readFileSync(join(OUT, d, "report.json"), "utf8")) : []);
    writeCompare({ web: read("web") });
    console.log(`compare: ${OUT}/compare.html`);
    return;
  }
  const only = opt("only");
  const dark = flag("dark");
  mkdirSync(OUT, { recursive: true });
  await ensureEmulators();
  if (!flag("no-seed")) await seed({ household: flag("household") });
  const sample = loadSample();
  const stub = await startFunctionsStub();
  await ensureVite();
  // --serve: keep the emulators, the functions stub and Vite up for other
  // runs (which then reuse them) until this process is stopped.
  if (flag("serve")) {
    console.log("serving: emulators + functions stub + vite are up; Ctrl-C to stop");
    await new Promise(() => {});
  }
  const routes = routeList(sample).filter((r) => !only || r.url.includes(only) || r.slug.includes(only));
  const { cdp, profile } = await launchChrome();
  const pages = [];
  cdp.on((msg) => {
    if (msg.method === "Page.loadEventFired") for (const p of pages) if (p.sessionId === msg.sessionId && p.loadWaiter) p.loadWaiter();
  });
  const token = await customToken(sample.user.uid);

  const variants = [
    { dir: "web", width: 390, height: 844, dpr: 2, mobile: true, dark: false, full: true },
    { dir: "web-desktop", width: 1440, height: 900, dpr: 1, mobile: false, dark: false, full: false },
    ...(dark ? [{ dir: "web-dark", width: 390, height: 844, dpr: 2, mobile: true, dark: true, full: true }] : []),
  ];
  const report = {};
  for (const v of variants) {
    const dir = join(OUT, v.dir);
    // A full run starts clean; an --only run replaces just its own routes.
    if (!only) rmSync(dir, { recursive: true, force: true });
    mkdirSync(dir, { recursive: true });
    const rows = [];
    // Vite optimises dependencies on the first visit and may reload the page
    // while it does: one throwaway visit, so the first real shot is not it.
    {
      const warm = await openPage(cdp, v);
      pages.push(warm);
      await navigate(warm, `${BASE}/login`);
      await evaluate(warm.s, SETTLE).catch(() => {});
      await closePage(cdp, warm);
    }
    for (const r of routes) {
      // Every route in a fresh context (see openPage), signed in first
      // unless it is a signed-out page.
      const page = await openPage(cdp, v);
      pages.push(page);
      try {
        if (!r.signedOut) {
          await navigate(page, `${BASE}/login`);
          await evaluate(page.s, `(async () => { for (let i = 0; i < 100 && !window.__easyplatePreview; i++) await new Promise((r) => setTimeout(r, 100)); return window.__easyplatePreview.signIn(${JSON.stringify(token)}); })()`);
        }
        page.errors.length = 0;
        page.inflight.clear();
        await navigate(page, `${BASE}${r.url}`);
        let settle;
        try {
          settle = await evaluate(page.s, SETTLE);
        } catch (e) {
          settle = { settledMs: -1, timedOut: true, why: String(e).slice(0, 120) };
        }
        await sleep(250);
        const state = await evaluate(
          page.s,
          `({ path: location.pathname.replace(/^\\/app/, "") + location.search, boundary: !!document.querySelector('[data-route-boundary], [data-error-boundary]') || /Something went wrong|משהו השתבש/.test((document.body?.innerText ?? "").slice(0, 2000)), text: (document.body?.innerText ?? "").slice(0, 160).replace(/\\s+/g, " ") })`,
        );
        const file = join(dir, `${r.slug}.png`);
        await shoot(cdp, page, file, { full: v.full, width: v.width });
        if (v.full) await shoot(cdp, page, join(dir, `${r.slug}.top.png`), { full: false, width: v.width });
        const pending = settle.timedOut ? [...page.inflight.values()].map((u) => u.replace(/\?.*/, "").slice(0, 120)) : [];
        const redirected = state.path.split("?")[0] !== r.url.split("?")[0];
        const row = { route: r.path, url: r.url, slug: r.slug, finalPath: state.path, redirected, errorBoundary: state.boundary, timedOut: settle.timedOut, waitingOn: settle.why || null, pendingRequests: pending, settledMs: settle.settledMs, errors: [...new Set(page.errors)].slice(0, 8), firstText: state.text };
        rows.push(row);
        const flagText = [redirected && `→ ${state.path}`, state.boundary && "ERROR BOUNDARY", settle.timedOut && `never settled (${settle.why})`, row.errors.length && `${row.errors.length} console error(s)`].filter(Boolean).join(", ");
        console.log(`${v.dir.padEnd(12)} ${r.slug.padEnd(30)} ${flagText || "ok"}`);
      } catch (e) {
        rows.push({ route: r.path, url: r.url, slug: r.slug, failed: String(e).slice(0, 300) });
        console.log(`${v.dir.padEnd(12)} ${r.slug.padEnd(30)} FAILED ${String(e).slice(0, 160)}`);
      } finally {
        await closePage(cdp, page);
      }
    }
    if (only && existsSync(join(dir, "report.json"))) {
      const kept = JSON.parse(readFileSync(join(dir, "report.json"), "utf8")).filter((old) => !rows.some((r) => r.slug === old.slug));
      rows.unshift(...kept);
    }
    report[v.dir] = rows;
    writeFileSync(join(dir, "report.json"), JSON.stringify(rows, null, 2));
  }
  writeCompare(report);
  if (stub) stub.close();
  await cdp.send("Browser.close").catch(() => {});
  cdp.ws.close();
  await cleanup();
  await sleep(500);
  try {
    rmSync(profile, { recursive: true, force: true, maxRetries: 5, retryDelay: 200 });
  } catch (_) {
    /* Chrome still closing: the OS temp folder is cleaned anyway */
  }
  const bad = (report.web || []).filter((r) => r.failed || r.errorBoundary || r.timedOut);
  console.log(`\n${(report.web || []).length} routes → ${OUT}/web, ${OUT}/web-desktop${dark ? `, ${OUT}/web-dark` : ""}; compare: ${OUT}/compare.html`);
  if (bad.length) console.log(`problem routes: ${bad.map((r) => r.slug).join(", ")}`);
}

// Native screen ↔ web route, side by side (out/compare.html): the first
// screenful of each, then the whole page of each.
const PAIRS = [
  ["recipes_list", "recipes"],
  ["recipe_details", "recipes_id"],
  ["add_recipe", "add"],
  ["library", "library"],
  ["book_viewer", "library_id"],
  ["meal_plan_board", "plans_id"],
  ["nutrition_dashboard", "nutrition_plan"],
  ["grocery_list", "groceries_id"],
  ["price_book", "prices"],
  ["receipt_details", "prices_receipts_id"],
  ["community_feed", "community"],
  ["forum", "community"],
  ["community_recipe", "community_recipe_id"],
  ["forum_thread", "community_thread_id"],
  ["inbox", "inbox"],
  ["settings", "settings"],
  ["account_menu", "menu"],
  ["profile", "settings"],
  ["paywall", "pricing"],
  ["shefi_chat", "assistant"],
  ["cook_mode", "cook_id"],
  ["sharing_management", "sharing"],
  ["household", "household"],
  ["support", "support"],
  ["support_chat", "support_id"],
];
function writeCompare(report) {
  const img = (dir, file) => (existsSync(join(OUT, dir, file)) ? `<img loading="lazy" src="${dir}/${file}">` : `<div class="missing">no ${dir}/${file}</div>`);
  const rows = PAIRS.map(
    ([n, w]) =>
      `<section><h2>${n} ↔ /${w}</h2><div class="pair">${img("native", `${n}.png`)}${img("web", `${w}.top.png`)}</div>` +
      `<details><summary>whole page</summary><div class="pair">${img("native", `${n}.full.png`)}${img("web", `${w}.png`)}</div></details></section>`,
  ).join("\n");
  const others = (report.web || []).filter((r) => !PAIRS.some(([, w]) => w === r.slug)).map((r) => `<figure>${img("web", `${r.slug}.top.png`)}<figcaption>${r.url}</figcaption></figure>`).join("");
  writeFileSync(
    join(OUT, "compare.html"),
    `<!doctype html><meta charset="utf-8"><title>Native vs web</title><style>body{font:14px system-ui;margin:16px;background:#f4f2fb}h2{font-size:15px;margin:24px 0 8px}.pair{display:grid;grid-template-columns:390px 390px;gap:24px;align-items:start}img{width:390px;border:1px solid #ccc;background:#fff}.missing{width:390px;height:120px;display:grid;place-items:center;border:1px dashed #999}figure{display:inline-block;margin:8px;vertical-align:top}summary{cursor:pointer;margin:8px 0}</style><h1>Native (left) vs web (right) — 390×844, Hebrew, light</h1>${rows}<h1>Web routes with no native pair</h1>${others}`,
  );
}

main().catch(async (e) => {
  console.error(e);
  await cleanup();
  process.exit(1);
});
