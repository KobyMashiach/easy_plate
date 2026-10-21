# Web ↔ native parity harness

Screenshots of every web-app route and of the native app's main screens,
from the same Hebrew sample data, so the phone layout of `aieasyplate.app/app`
can be matched to the Flutter app screen by screen — and the desktop layout
can be proven unchanged.

Nothing here touches production: the web app's emulator mode talks only to
local emulators of the `demo-easyplate` project, the Cloud Functions are a
local stub, and the native renders run in `flutter test` with fakes.

## One-time needs

- Node 22+ (built-in `WebSocket`), Google Chrome at
  `/Applications/Google Chrome.app` (or `CHROME_BIN=…`).
- `firebase` CLI and a **JDK 21+** for the emulators. `shoot.mjs` uses
  `PREVIEW_JAVA_HOME` if set, else the JDK 21 it was built with (a scratch
  folder that may be gone), else `JAVA_HOME`. With Homebrew:
  `brew install openjdk@21` then
  `export PREVIEW_JAVA_HOME=$(brew --prefix openjdk@21)/libexec/openjdk.jdk/Contents/Home`.
- `functions/node_modules` installed (the seed uses its `firebase-admin`).

## Commands (from `webapp/`)

| Command | What it does |
| --- | --- |
| `npm run preview:shoot` | Everything for the web: starts the emulators if they are not up, seeds them, starts the functions stub and Vite in emulator mode, and writes all screenshots. `-- --dark` adds dark-theme phone shots, `-- --only plans` limits the routes, `-- --no-seed` keeps the current data, `-- --household` seeds a Pro Family household. |
| `npm run preview:native` | The native reference renders (`flutter test test/store_assets/web_parity_screens_test.dart --dart-define=WEB_PARITY_SCREENS=true`), then rebuilds `out/compare.html`. |
| `npm run preview:emulators` | Only the emulators (auth 9299, firestore 8288, storage 9399), in the foreground. |
| `npm run preview:seed` | Only the seed (emulators must be running). `node scripts/preview/seed.mjs --household` for the household variant. |
| `npm run preview:dev` | Vite in emulator mode on `http://127.0.0.1:5188/app` for clicking around by hand. Sign in from the console: `__easyplatePreview.signIn(token)` — a token comes from `node -e "import('./scripts/preview/seed.mjs').then(m=>m.customToken('preview-user-0001')).then(console.log)"`. |
| `npm run preview:check-build` | Production build **with** `VITE_EMULATORS=1` set, into a temp folder, then fails if any emulator host, port, the demo project, the preview hook or the local flags file is in the bundle. |

Typical loop: `npm run preview:shoot && npm run preview:native`, then open
`scripts/preview/out/compare.html`.

## Output (`scripts/preview/out/`, git-ignored)

- `web/<route>.png` — 390×844 @2x, mobile emulation (iPhone UA, touch),
  Hebrew, light, reduced motion — **whole page**.
- `web/<route>.top.png` — the same, first viewport only.
- `web/report.json` — per route: final path (a redirect shows), error
  boundary, never-settled (and what it waited on), console errors.
- `web-desktop/<route>.png` — 1440×900 first viewport (proves the desktop
  layout did not move).
- `web-dark/…` — with `--dark`.
- `native/<screen>.png` — 390×844 @2x first screenful;
  `native/<screen>.full.png` — the page made as tall as its longest
  vertical scroll; `native/<screen>.errors.txt` — framework errors noted
  during that render, if any.
- `compare.html` — native vs web, side by side, per screen.

Route names are the path with `/` → `_` (`/recipes/:id` → `recipes_id`);
signed-out pages are prefixed `signed_out_`. The routes are read from
`src/features/*/routes.tsx` plus the app-level ones in `App.tsx`, so a new
feature route is picked up by itself.

## How it works

- **Emulator mode** (`VITE_EMULATORS=1`, dev server only):
  `src/lib/firebase.ts` uses a `demo-easyplate` config, connects Auth to the
  emulator and exposes `window.__easyplatePreview.signIn`;
  `src/lib/firestoreSdk.ts` wraps `getFirestore`/`getStorage` so every
  instance connects to the emulators; `FUNCTIONS_ORIGIN` points at the local
  stub; `src/lib/flags.tsx` reads `remote-config.json` here (every `ff_*` = 2)
  instead of Remote Config. Each guard is
  `import.meta.env.DEV && import.meta.env.VITE_EMULATORS === "1"`, a
  compile-time `false` in a production build, so the branches and their
  strings are dropped (`preview:check-build` proves it).
- **Data**: `sample-data.json` is the single source. Collection records are
  exactly the Dart `toJson` shapes (the same contract as
  `webapp/contract-fixtures/`); other documents (feed, forum, inbox, invites,
  support) follow the shapes the web app's data files read. Photos in
  `images/` were cropped from the store raws in `store_assets/raw/he/`.
  The account: `preview-user-0001`, phone `+972500000000` (verified — the
  gate), email `preview@easyplate.test` / `preview-pass-123`, Premium
  (`entitlements` doc, product `easy_plate_ai_pro_family_yearly`).
- **Screenshots**: `shoot.mjs` drives Chrome over the DevTools protocol;
  each route opens in a fresh browser context (own storage and connection
  pool — leftover Firestore streams otherwise exhausted Chrome's six
  connections per host), signs in with a custom token, waits until fonts,
  spinners and pictures settle, and captures. Root files Hosting serves next
  to `/app` (`/icon-64.png`) are answered from `landing/`.
- **Native**: `test/store_assets/web_parity_screens_test.dart` fills real
  Hive boxes from the sample, marks the session ready
  (`AuthSessionService.signInForTest`) and the plan Premium Family
  (`EntitlementService.documentForTest`), fakes the server repositories, and
  renders through the app's own router and pages with SF Hebrew (an
  iPhone's Hebrew font, and Safari's). The paywall is `PaywallView` with
  sample offers, since real offers come from the store SDK.
