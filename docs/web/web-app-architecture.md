# EasyPlate web app — how a feature is built (read before writing code)

The web app (`webapp/`, served at `aieasyplate.app/app`) is the phone app on a big screen: same account, same data, same features. It is React 18 + TypeScript + Tailwind (Vite). Build: `cd webapp && npm run build` (runs the i18n check, `tsc`, `vite build` → `landing/app/`). Never deploy; the coordinator does.

## 1. Where your code goes

- **Your feature folder:** `webapp/src/features/<feature>/`. Put everything there: pages, components, hooks, data helpers.
- **Routes:** `routes.tsx` in that folder exports `routes: FeatureRoute[]` (see `src/app/routing.ts`). `App.tsx` picks it up by itself; never edit `App.tsx`.
  - Routes are signed-in pages inside the full-screen frame by default.
  - `bare: true` gives no frame (cook mode, full-screen readers).
  - `public: true` is for signed-out pages.
- **Translations:** `webapp/src/i18n/<feature>.json` holds `{ "he": {...}, "en": {...}, "ar": {...}, "fr": {...}, "ru": {...} }`.
  - Every key starts with `<feature>.`.
  - All five languages must have identical keys and placeholders, or the build fails (`scripts/check-i18n.mjs`).
  - Hebrew is the main language; copy the app's wording from `assets/i18n/he.i18n.json` where the app already says it.
  - Use `const { t } = useI18n()` and write `t("feature.key", { n: 3 })`.
- **Contract samples:** `webapp/contract-fixtures/<collection>/<name>.json`. Add one or more for every kind of record your code writes (see 3).
- **Shared files you may NOT edit:**
  - `src/App.tsx`, `src/app/*`, `src/lib/*`, `src/models/*`, `src/components/*`
  - other features' folders, `src/i18n/shell.json`
  - If you need a change there, say so in your report; the coordinator makes it.
  - You may add new files under `src/models/` only for a model your feature owns (`book.ts`, `mealPlan.ts`, `groceryList.ts`, `priceRecord.ts`, …), named after the collection.

## 2. The frame and look

- **The frame** (`src/app/AppShell.tsx`) is full screen:
  - desktop: side menu, top bar with inbox, language, appearance and profile menu;
  - phone (below `lg`): the native frame — white 68 px bar (avatar · "Easy Plate" · bell on the five dock tabs; back arrow · page title on every other route), the Liquid Glass dock and the Shefi pill on the tabs, the cook-timer banner, the iOS push slide between routes. Main content has 20 px sides, 24 top, 176 bottom under the dock.
- **Phone look (below `lg`), read `docs/web/mobile-native-spec.md`.** Keep the desktop as it is: phone-only markup behind `useIsPhone()` (`src/components/useIsPhone.ts`) or `max-lg:` / `lg:` classes. Shared phone pieces:
  - `components/PhoneBar.tsx` — `<PhoneBar title back trailing tab hideDock hideShefi />` tells the frame about the page (bar title, trailing round button, forcing tab chrome on e.g. `/plans/:id`).
  - `components/FloatingHeaderView.tsx` — the floating 28 px title with pinned 48 px round actions; pass today's header as `desktopHeader`.
  - `components/clay.tsx` — `ClayButton`, `ClayIconButton`, `ClayCard` (radius, spine, active, press), `ClayTag`, `Chip`, `Switch`, `RoundCheckbox`, `SegmentedControl`, `CountBadge`, `PageHeader`, `EmptyState`, `ProgressGroove`, `LoadingSpinner`.
  - `components/BottomSheet.tsx` (+ `SheetOption`), `components/AppDialog.tsx` — bottom sheet / native dialog on a phone, today's centred modal on desktop.
  - `components/FloatingActions.tsx` — `ShefiPill` (light variant for recipe details), `PageFab` (start corner).
  - `components/PullToRefresh.tsx` — `usePullToRefresh(fn)` / `<PullToRefresh>`.
  - `components/pageTransition.tsx` — `usePhoneNavigate()` for programmatic pushes/back with the slide.
  - Icons: `<Icon name>` draws Material Icons Round on a phone; spec names (`receipt_long`) work there directly.
  - Type: `text-headline-lg-mobile` (28/36) for phone page titles; AppMotion as CSS variables (`--dur-*`, `--ease-*`); `.press` / `.press-icon` / `.press-fab` for press-down.
- **Your page draws only its content.** It sits in a centered column up to 1400 px wide. Use the width: grids of cards on desktop, one column on a phone (`grid gap-4 sm:grid-cols-2 xl:grid-cols-3`).
- **Look:** the app's tokens and clay components only. Read `src/styles/index.css`, `src/components/ui.tsx` and `tailwind.config.cjs`.
  - Classes: `clay`, `clay-btn-primary|secondary|tonal|ghost|danger`, `clay-input`, `pill-*`.
  - Colours: `bg-primary`, `text-on-surface-variant`, `bg-primary-fixed`, `bg-secondary-fixed`, …
  - Type: `text-headline-lg`, `text-body-md`, …; radii `rounded-std|md|lg`; shadows `shadow-card|button|control`.
  - No raw hex colours except where the dock already does.
- **Light and dark** come from tokens, so never hard-code white or black.
- **RTL is the default** (Hebrew):
  - use logical classes: `ms-`, `me-`, `ps-`, `pe-`, `start-`, `end-`, `text-start`, `border-s`;
  - flip arrows with `rtl:rotate-180`;
  - wrap phone numbers and URLs in `dir="ltr"`.
- **Icons:** `<Icon name="…" />` from `src/components/icons.tsx`. Ask the coordinator for new names.
- **Accessibility:**
  - real `<button>` and `<a>` elements; labels for inputs;
  - visible focus (already global);
  - headings in order (`h1` once per page);
  - `aria-live` only on small status regions.

## 3. Data — the rule that must never be broken

Every account's data is the same Firestore records the phone mirrors (`lib/core/sync/user_cloud_collection.dart`):

- `users/{uid}/{collection}/{id}`, or `households/{hid}/{collection}/{id}` while the account is in a household (shared collections only);
- collections: `recipes`, `books`, `meal_plans`, `grocery_lists`, `price_records`, `receipts`, `product_pricing` (shared); `preferences`, `usage` (personal).

**A document's data is the Dart model's `toJson()` exactly.** The phone parses it with strict generated code, so a wrong shape breaks a phone. Therefore:

- Read the model's generated file (`lib/features/<x>/data/models/<y>_model.g.dart`, functions `_$XFromJson` / `_$XToJson`). Mirror it in a `src/models/<collection>.ts` with:
  - a `normalizeX(raw)`, which reads defensively and applies the app's defaults;
  - an `xToDart(x)`, which returns every key the Dart `toJson` writes, in its shape.
  - `src/models/recipe.ts` is the worked example.
- **Every key present:** nullable fields are written as `null`, never left out.
- **Dates:** ISO strings (`new Date().toISOString()`, as `DateTime.toIso8601String()`).
- **Enums:** their Dart names (`"tablespoon"`, `"glutenFree"`).
- **Doubles vs ints:** what Dart reads with `(x as num).toInt()` must be a whole number.
- **ids:** `newId()` (uuid v4, the app's format).
- **Writing:** `putRecord(collection, id, xToDart(x))` writes the whole record (set, not merge, exactly like the app). `deleteRecord`, `getRecord` and `listRecords` cover the rest.
- **Live reads:** `useCollection<T>(collection, uid)` and `useRecord<T>(collection, uid, id)` follow the household root by themselves.
- **contentLang / contentVersion:** follow the app's stamping rule on save. See `stampRecipe` in `src/models/recipe.ts`; books, plans and lists have the same rule in their repositories. For recipes always use `saveRecipe` / `deleteRecipe` from `src/lib/recipesStore.ts`.
- **Contract samples:** every record shape you write needs a sample under `webapp/contract-fixtures/<collection>/`. Make it exactly what your `xToDart` produces, ideally one minimal and one full. Then run `flutter test test/web_contract` from the repo root: it parses each sample with the app's own model and fails on any missing or extra key.
- **Other Firestore paths:** community, forum, collab, share_invites, notifications, households, entitlements and so on. Use `withFirestore((fs, db) => fs.onSnapshot(...))` for live data, or `await firestore()` for one-off reads and writes, from `src/lib/cloud.ts`.
  - Never import `firebase/firestore` directly.
  - Read `firestore.rules` for what a client may write. Copy the app's own datasource for the exact fields (`lib/features/<x>/data/datasources/*_remote_datasource.dart`).
- **Pictures:** `uploadRecipeImage(file)` returns the storage path to store in `imageStoragePath` (downscaled JPEG under `recipe_images/{uid}/`). `storageUrl(path)` turns a path into an `<img>` URL (cached).

## 4. Switches, Premium, quotas, AI

- **Feature switches** are Remote Config `ff_*`, the same ones the app reads (`lib/core/features/features_flags.dart`).
  - Wrap every entry point the app wraps: `<FeatureGate flag="ff_cook_mode">…</FeatureGate>`, or `page` for a whole page.
  - Branch with `useAccess("ff_x")`, which returns `"hidden" | "comingSoon" | "locked" | "enabled"`.
  - Other parameters: `useFlags().number("quota_…", fallback)` and `.string(...)`.
- **Premium:** `useAuth().premium`. Daily limits for free accounts follow the app's `MonetizationConfig` (Remote Config numbers) and `DailyUsageModel` in the `usage` collection: the doc id is the day, so read the app's `daily_usage_service.dart`. Count the same way the app counts.
- **Cloud Functions:** `callFunction(name, body)` from `src/lib/functions.ts`. Covers `aiProxy`, `socialRecipe`, `translateContent`, `imageSearch`, `speak`, `shareCodes`, `households`, `priceStats` and `deleteAccount`. CORS is open for the site, and the ID token is attached.
- **Gemini:** `interactions(body, { sourceUrl, sourceKind, feature })` goes through the proxy. Copy the request bodies field for field from the app's datasource (`lib/features/recipe_ingestion/data/datasources/recipe_ai_datasource.dart` and the assistant's), including prompts and JSON schemas.
- **Errors:** `ApiError` with `.code` and `.status`; `quotaOf(err)` reads a 429 quota object. Every error a user can see gets a translated message; never show raw error text.

## 5. Quality bar

- Feature parity with the app screen you are porting. Read its Dart page, bloc and datasource first, and behave the same: what is editable, what is locked, empty states, confirmations.
- Every list has an empty state, a loading state and an error state.
- Every button that writes is disabled while busy (no double submits).
- Every destructive action asks first.
- Live data uses listeners, and every effect cleans up.
- Lazy where lists can be long.
- `npm run build` green and `flutter test test/web_contract` green before you report.
