# EasyPlate native mobile UI — implementation spec for the web app (< lg)

Source of truth: the Flutter code under `lib/` as of 2026-10-18. Read from
`lib/core/constants/*`, `lib/core/styles/app_theme.dart`, `lib/core/widgets/**`
and every page under `lib/features/*/presentation`. Reference captures in
`landing/screens/*.jpg` are Hebrew, 540 px wide (= 390 logical × 1.385) and
**date from 2026-10-06**. Two things changed after they were taken and the code
wins: the nav dock is now **Liquid Glass** (not the dark pill with a mint
active tab the screenshots show), and every main tab now has the floating
**Shefi pill** in the end corner.

Scope: everything below applies to the web app **under the `lg` breakpoint**
(phone and small tablet). Desktop stays as it is.

Units are logical px (= CSS px). Colours are named by the `AppPalette` token,
then the light hex, then the dark hex where it matters. Web tokens already exist
for every colour (`webapp/src/styles/tokens.css`, Tailwind names in
`tailwind.config.cjs`: `surface-lowest` = surfaceContainerLowest,
`surface-low` = surfaceContainerLow, `surface-high` = surfaceContainerHigh,
`surface-highest` = surfaceContainerHighest).

---

## 0. Foundations

### 0.1 Spacing (`AppSpacing`)

| token | px | Tailwind |
|---|---|---|
| xs | 4 | `1` |
| base | 8 | `2` |
| sm | 12 | `3` |
| gutter | 16 | `4` |
| marginMobile | 20 | `5` |
| md | 24 | `6` |
| lg | 32 | `8` |
| xl | 48 | `12` |

The page side margin on a phone is always **20** (`marginMobile`), not 12/16
as `AppShell`'s `<main className="px-3 sm:px-4">` does today.

### 0.2 Radii (`AppRadius`)

sm 8 · std 16 · md 24 · lg 32 · xl 48 · full 9999. Tailwind already maps
`rounded-sm/std/md/lg/xl/full`. Native cards and dialogs use **continuous
(superellipse) corners** (`RoundedSuperellipseBorder`). On the web use the
plain radius, optionally `corner-shape: squircle` behind `@supports`.

### 0.3 Type (`AppTextStyles`, font Plus Jakarta Sans, variable `wght` pinned)

| style | size / line | weight | tracking | Tailwind |
|---|---|---|---|---|
| displayLg | 40/48 | 800 | -0.02em | `text-display-lg` |
| headlineLg | 32/40 | 700 | -0.01em | `text-headline-lg` |
| **headlineLgMobile** | **28/36** | **700** | 0 | **missing on web** |
| headlineMd | 24/32 | 700 | 0 | `text-headline-md` |
| bodyLg | 18/28 | 500 | 0 | `text-body-lg` |
| bodyMd | 16/24 | 500 | 0 | `text-body-md` |
| labelMd | 14/20 | 600 | 0.01em | `text-label-md` |
| labelSm | 12/16 | 700 | 0.03em | `text-label-sm` |

Default text colour is `onSurface` #181445 (dark #E5E1E9).
Every page title on a phone is **headlineLgMobile 28/36**, not headline-lg 32.
Add `"headline-lg-mobile": ["28px", { lineHeight: "36px", fontWeight: "700" }]`.

Font fallback, native: `Plus Jakarta Sans` → `SF Hebrew`, `Arial Hebrew`,
`Geeza Pro`, `Noto Sans Arabic`, `Noto Sans Hebrew`, `Roboto`. Hebrew glyphs on
a phone are therefore **the system Hebrew face** (SF Hebrew on iOS, Noto Sans
Hebrew on Android), not Heebo. For pixel parity under lg:
`html[lang=he] body { font-family: "Plus Jakarta Sans", "SF Hebrew", "Arial Hebrew", "Noto Sans Hebrew", system-ui, sans-serif }`
(Latin digits and "Easy Plate" stay in Jakarta, as in the screenshots).

### 0.4 Shadows (`AppShadows`, all lavender-tinted)

| token | CSS | Tailwind |
|---|---|---|
| card | `0 12px 32px rgb(123 97 255 / .08)` | `shadow-card` |
| book | `8px 16px 32px rgb(123 97 255 / .12)` | `shadow-book` |
| button | `0 8px 24px rgb(91 60 221 / .25)` (primary) | `shadow-button` |
| active | `0 8px 24px rgb(116 89 247 / .30)` (primaryContainer) | `shadow-active` |
| dock | `0 12px 32px rgb(123 97 255 / .20)` | `shadow-dock` (only used by notices and the cook-timer banner now; the dock itself has its own glass shadow, 1.4) |
| control | `0 4px 12px rgb(123 97 255 / .10)` | `shadow-control` |
| dialog | `0 16px 40px rgb(123 97 255 / .18)` | `shadow-dialog` |

`bevelHighlight` = white @ 60 %, scaled by `bevelStrength` (1.0 light, 0.25 dark).
`buttonThickness` = 4 (the ClayButton extrusion).

### 0.5 Motion (`AppMotion`)

| token | value | use |
|---|---|---|
| press | 110 ms | finger-down sink/shrink |
| quick | 180 ms | chip fill, colour/ink change |
| standard | 240 ms | pill slide, row expand, bar fill |
| emphasized | 300 ms | dialog/notice entrance |
| exit | 180 ms | leaving |
| easeOut | `cubic-bezier(.23,1,.32,1)` | default |
| easeInOut | `cubic-bezier(.77,0,.175,1)` | theme reveal, reorder |
| drawer | `cubic-bezier(.32,.72,0,1)` | sheets, edge slides |
| settle | `cubic-bezier(.34,1.28,.64,1)` | only after a drag/flick release |

Reduced motion: movements (slide/scale/rotate) go to 0 ms; fades/colour stay
but are capped at 180 ms. Press feedback fires on pointer-**down**.

Missing on web: these as CSS custom properties. Add
`--dur-press:110ms; --dur-quick:180ms; --dur-standard:240ms; --dur-emph:300ms; --dur-exit:180ms; --ease-out:cubic-bezier(.23,1,.32,1); --ease-in-out:…; --ease-drawer:…; --ease-settle:…`.
The existing `animate-rise` (.45 s, `.2,.8,.2,1`) has no native counterpart; do not
use it on phone pages.

### 0.6 Icons

Native uses Flutter `Icons.*_rounded` = Google **Material Icons Round** (filled,
rounded). Sizes are given per component below (most: 22 in rows, 18–20 in
chips/buttons, 24 default). The web's hand-made stroke set
(`components/icons.tsx`) does not match. For parity load the Google Fonts
"Material Icons Round" (or Material Symbols Rounded with `FILL 1, wght 400,
GRAD 0, opsz 24`) and use the exact names listed in this spec.

### 0.7 Page background, scrolling

- Page background is flat `background` #FCF8FF (dark #141318). **No radial
  lavender/mint wash** — `index.css` body background-image must be dropped under lg.
- Scroll physics: iOS bounce on every platform, no glow/stretch indicator.
  On the web: `overscroll-behavior-y: auto` on the scroller (let iOS bounce), no
  custom glow.

### 0.8 RTL rules

- Every inset, alignment and position is **directional** (start/end), never
  left/right: use `ps/pe/ms/me/start-/end-` and logical properties.
  Hebrew/Arabic: start = right.
- A `Row` lays its children from the start edge: first child is rightmost in
  Hebrew. Mirror the DOM order the same way (flex follows `dir` automatically).
- Icons that mirror in RTL (Material `matchTextDirection`): `arrow_back`
  (points **right** in Hebrew — see 02/03 screenshots), `arrow_forward`,
  `chevron_right` (points **left** in Hebrew — grocery rows), `chevron_left`,
  `send`, `format_list_bulleted`, `playlist_add`, `logout`. Apply
  `rtl:-scale-x-100`. Everything else (bell, sparkle, cart, timer…) is not mirrored.
- Numbers: kcal uses thousands commas (`1,240`); money is symbol-first
  `₪59.90` (2 decimals); the red count badge is forced LTR.
- The book viewer page-flip direction follows RTL (`isRightSwipe: true`).
- The segmented-control label sits on the reading-start side of its icon
  (right of the icon in Hebrew).

---

## 1. App frame

### 1.1 Top bar — `ClayTopAppBar` (every screen)

- Surface `surfaceContainerLowest` #FFFFFF (dark #0E0D13), runs up under the
  status bar (`padding-top: env(safe-area-inset-top)`), bottom border 1 px
  `surfaceContainerHighest` #E3DFFF, shadow `control`.
- Height **68** (+ safe-area top). Horizontal padding 20. Not sticky-blurred: it
  is opaque and **fixed** (never scrolls, never hides). Content scrolls under
  nothing — the body starts below it.
- Row: `[leading] 12 gap [title, flex 1, 1 line, ellipsis] [8 gap, action]… [8 gap, trailing]`.
- Title: headlineMd 24/32 w700 colour `primary` #5B3CDD.
  - Main tabs: "Easy Plate" (`t.appName`) — except **Community**, whose bar says
    "קהילה" (`t.community.title`).
  - Pushed pages: the page's own title (e.g. "הוספת מתכון", "דאשבורד תזונה"),
    recipe details uses "Easy Plate".
- Main tabs: leading = **account avatar**, actions = **notification bell**.
  Hebrew: avatar at the far right, title right-aligned next to it, bell at the
  far left. English: mirrored.
- Pushed pages: leading = `ClayIconButton(arrow_back_rounded)` (mirrored), and
  an optional trailing `ClayIconButton` (edit on recipe details, delete_sweep on
  notifications, delete_outline on receipt details, add_comment_outlined on Shefi,
  qr_code_scanner on sharing).

**Account avatar** (`AccountAvatarButton`): circle, padding 2, fill
`surfaceContainerLow` #F6F2FF, border 1 `surfaceContainerHighest`, shadow
`control`; inside a 34 px `ProfileAvatar` (photo cover, or `primaryFixed`
#E5DEFF disc with initials labelMd primary at 0.36×size, or `person_rounded`
0.55×size). Total 40×40. Tap → account menu. Admin only: red count badge at
top −4 / end −4.

**Notification bell**: `ClayIconButton` 40 (see 1.6) with
`notifications_rounded` 22 `primary`; badge = unread + running cook timers at
top −6 / end −8. Hidden when `ff_notifications` hidden.

**Count badge** (`CountBadge`): min 18×18, padding 1/5, radius 9, fill `error`
#BA1A1A, 2 px ring `surfaceContainerLowest` (or the colour underneath), text
10 px w700 line 1.2 `onError`, `99+` cap, LTR.

Web today: `AppShell` header is a sticky, 85 % blurred bar with the app icon +
"Easy Plate" body-lg, then bell (no count, only a 12 px dot), language select,
theme toggle and avatar on the end side. All of that differs; under lg replace
it with the layout above (avatar | title | bell).

### 1.2 Cook-timer banner (under the bar, every `ClayScaffold`)

When cook-mode timers run: a stack of pills directly under the bar, margin
8/20, each pill height `24 + 52×textScale` ≈ 76, radius 24, fill `navDock`
#1E1E24 (finished: `secondaryContainer` #62FAE3), shadow `dock`, padding
12/16; icon `timer_rounded` / `notifications_active_rounded` 18, labelMd white,
labelSm accent `secondaryFixedDim`, remaining time bodyLg; page dots 4→10 wide.
Missing on web.

### 1.3 Floating page header — `ClayFloatingHeaderView`

Used by: Recipes, Library, Meal plan board, Groceries. The title block is the
first sliver of the page's scroll view:

- Padding: top 24, start 20, end `20 + actionWidth + 12`, bottom `bottomGap`
  (default 24; Library 32, Groceries 32, Meal plan 0).
- Title headlineLgMobile 28/36 `onSurface`; optional subtitle 8 below it,
  bodyMd `onSurfaceVariant` #484555.
- Background `background` @ 78 % + `backdrop-filter: blur(20px)` (frosted).
- **Behaviour** (`SliverPersistentHeader(floating: true)`, no snap): scrolling
  down translates the header up 1:1 until it is gone; scrolling **up by any
  amount** brings it back 1:1 from wherever the list is (not only at the top).
  It never snaps. Implement as `translateY = clamp(prev - delta, -extent, 0)`.
- **The action stays pinned**: the page's round button(s) are absolutely
  positioned over the list at `top: 28` (24+4), `end: 20`, and do not move with
  the header. The list scrolls under them.
- Action button sizes: 48 each, 8 apart (`trailingWidth = 48·n + 8·(n−1)`).

Missing on web (pages use a static `<header>` with a title and inline buttons).

### 1.4 Nav dock — `ClayNavDock` (Liquid Glass)

- Five tabs, in this order (start → end, so in Hebrew right → left):

| # | label (he) | icon | flag |
|---|---|---|---|
| 0 | מתכונים | `receipt_long_rounded` | — (home, always on) |
| 1 | ספרייה | `library_books_rounded` | ff_books |
| 2 | תפריטים | `calendar_today_rounded` | ff_meal_plans |
| 3 | קניות | `shopping_cart_rounded` | ff_grocery_lists |
| 4 | קהילה | `groups_rounded` | ff_community |

  Hidden tab → removed, remaining tabs share the width. Coming-soon / Premium-only
  tab → keeps its slot, opens a gated notice page (`GatedNotice`: icon
  `schedule_rounded`/`workspace_premium_rounded` 56, headlineMd, bodyMd, Premium
  ClayButton). **No 6th "more" tab** — account/settings/etc. are reached from the
  avatar.
- Geometry: margin 0/20/24 (left, right 20; bottom 24 from the screen bottom on
  iOS; on Android 24 above the gesture-bar inset). Width = viewport − 40
  (350 at 390). Stadium shape. Inner padding 6. Each slot = (width−12)/5.
- Item: vertical padding 8, horizontal 4; icon 22; 2 px gap; label 10.5 px,
  line 14 px, tracking 0.36 px, **w600 active / w500 inactive**, 1 line ellipsis.
  Dock height ≈ 66.
- Glass, light theme:
  - fill: linear top→bottom white @ 66 % → white @ 46 %;
  - `backdrop-filter: blur(24px) saturate(1.6)`;
  - sheen: top 55 % of the height, white @ 35 % → 0;
  - rim: 1 px stroke, gradient top→bottom white @ 95 % / @ 25 % (at 55 %) / @ 95 %;
  - shadow `0 10px 30px rgb(0 0 0 / .12), 0 1px 4px rgb(0 0 0 / .05)`;
  - inactive ink `#1C1C1E` @ 72 %; active ink `primary` #5B3CDD.
- Glass, dark theme: fill #2C2C2E @ 58 % → #1C1C1E @ 46 %; rim white @ 32/6/32 %;
  sheen white @ 7 %; shadow `0 12px 30px rgb(0 0 0 / .45)`; inactive ink white
  @ 78 %; active ink `primary` (dark) #C9BFFF.
- Active lozenge: one slot wide, full inner height, stadium, fill white @ 72 %
  (dark: white @ 13 %), 0.6 px rim white (dark white @ 18 %), shadow
  `0 2px 8px rgb(0 0 0 / .06)`. Tap → it **glides** to the new slot, 240 ms
  easeOut, no overshoot. Active item scales to 1.04 (240 ms easeOut); ink colour
  cross-tweens in 180 ms.
- **Drag-to-select**: horizontal drag anywhere on the dock picks the lozenge up;
  it follows the finger 1:1 (RTL: finger right = toward start), the ink under it
  lights up as it passes, a selection haptic per tab crossed. On release it lands
  on the tab nearest to `position + velocity/1000 × 0.99/0.01` (the projected
  rest), animating with `settle` (the one overshoot in the app).
- **Does not hide on scroll.** It floats over the content; pages pad their
  scrollers with `bottomPadding` (1.5).
- Switching tabs is instant: the five pages are kept alive (`IndexedStack`), no
  transition, scroll positions are preserved.

Web today: dark `bg-nav-dock` pill, `inset-x-3`, icon-only 48 px circles,
mint (#62FAE3) active, a 6th "menu" item. Every part of that differs.

### 1.5 Floating buttons above the dock

- **Shefi pill** (`AssistantFab`) — on every main tab when the assistant is
  enabled: `position: fixed; inset-inline-end: 20px; bottom: 96px` (= dock
  reserve; + Android gesture inset). Height 56, stadium, padding start 16 / end
  24. Fill: linear gradient top-start → bottom-end `lavenderGlow` #7B61FF →
  `primary` #5B3CDD → `onPrimaryFixedVariant` #441CC8. Content: 32 px disc white
  @ 22 % with `auto_awesome_rounded` 18 white, 12 gap, "שפי" bodyLg 18 **w700**
  white. Glow: `0 8px (24→32)px 1px rgb(123 97 255 / (.45→.70))` breathing over
  3 s, reversing (static under reduced motion). Press: scale .95.
  Hebrew: bottom-**left**.
- **Light variant** (recipe details only): fill `surfaceContainerLowest`, 1.5 px
  `primary` border, disc `primaryFixed`, sparkle and text `primary`. Placed as a
  Material end-float FAB: end 16, bottom 16 (+ safe area).
- **Page FAB** (Community feed `ios_share_rounded`, Forum `edit_rounded`):
  Material FAB, 56×56 circle, `primary` fill, white 24 icon, elevation 0,
  `inset-inline-start: 20px; bottom: 96px` — the **opposite** corner from Shefi,
  same baseline (Hebrew: bottom-right).
- Screens whose main action sits in the floating header (Recipes, Library,
  Plans, Groceries) have **no** bottom FAB; their "+"/sparkle are the pinned
  header buttons (1.3).

### 1.6 Round icon buttons — `ClayIconButton`

- Default 40×40 circle; icon 0.55×size (22 at 40, 26 at 48).
- Ghost (default): fill `surfaceContainerLow` #F6F2FF, 1 px border
  `surfaceContainerHighest` #E3DFFF, shadow `control`, icon `primary`
  (disabled: `outlineVariant` #C9C4D8).
- Filled (the one lead action): fill `primary`, no border, shadow `button`,
  icon `onPrimary`.
- Press: scale .92, 110 ms easeOut.
- In headers they are 48. Example, Recipes: one filled 48 `auto_awesome`;
  Library: filled 48 `add`; Groceries: ghost `receipt_long`, ghost `autorenew`,
  filled `add`; Meal plan: ghost `person_add_alt_1`, ghost `more_horiz`, filled
  `playlist_add`. Order is start→end in the DOM, so in Hebrew the filled one is
  the **leftmost** (outermost).

### 1.7 Bottom padding

Pages under the dock pad their scroller bottom by
`bottomPadding = 96 (+ Android inset) + (Shefi on or page FAB ? 80 : 0)` →
**176** in the normal case. Web today: `pb-28` (112).

### 1.8 Page transitions

- Push/pop: **iOS slide** — new page slides in from the end edge (from the left
  in Hebrew), the previous page moves ⅓ of the width toward the start and
  darkens slightly under a shadow; pop reverses. iOS duration 500 ms
  (Android 400 ms), curve ≈ `cubic-bezier(.32,.72,0,1)`. iOS: edge back-swipe.
- Main tabs: no transition (1.4).
- Dialogs: 2.1. Sheets: 1.10.
- Web: use the View Transitions API (`::view-transition-old/new` with
  translateX and the drawer curve) for route changes under lg; respect reduced
  motion. Missing today.

### 1.9 Pull to refresh

Material `RefreshIndicator`, colour `primary`, on: community feed, forum list,
forum thread, notifications, sharing management. Not on recipes/library/plans/
groceries. An empty list still pulls (`RefreshableEmptyState`). Web: a small
circular spinner disc (white, primary arc, 40 px, shadow) that follows the pull,
threshold ~80 px. Missing on web.

### 1.10 Bottom sheets (`showModalBottomSheet`, the theme's sheet)

- Fill `surfaceContainerLowest`, top corners **32** (continuous). A few sheets
  override to **24** (forum composer, meal-plan picker, ingestion "open" sheet,
  cook-mode ingredients).
- Drag handle shown: 32×4, radius 2, `outlineVariant` #C9C4D8, centred in a
  48 px tall strip (cook mode draws its own 40×4 at top 12).
- Scrim `rgb(0 0 0 / .54)`; max width 640; slides up with the drawer curve.
- Content padding: 20 sides (`marginMobile`), 0 or 24 top under the handle,
  bottom 20 + keyboard inset. Title headlineMd (or `ClaySectionHeader` with
  underline), 16 gap, fields, 24/32 gap, full-width ClayButton, 12 bottom gap.
- Option rows inside sheets are ClayCards r24 p16: icon 24 `primary`, 12 gap,
  bodyMd (destructive: icon and text `error`), 8 between rows.
- Web: there is no sheet component; `features/recipes/components/Modal.tsx` is a
  centred `<dialog>` with a header bar and a close button. Under lg every sheet
  must be a bottom sheet.

### 1.11 Toasts

None. There are no SnackBars; transient messages are `AppDialog.notify` (2.2).

---

## 2. Components

### 2.1 Dialog — `AppDialog.show` (modal, resolves an answer)

- Scrim `onSurface` @ 32 % + page `backdrop-filter: blur(14px × t)` growing with
  the entrance.
- Card: max-width 380, margin 24 (bottom +keyboard), padding 24, radius **32**,
  fill `surfaceContainerLowest`, 0.5 px `surfaceContainerHighest`, shadow
  `dialog`. Content scrolls if tall.
- Column, centred: **medallion 64** circle (icon 32) → 16 → title headlineMd
  centred → 8 → message bodyMd centred (`onSurfaceVariant`; `onSurface` when
  there is no title) → [16 → custom content, e.g. a text field] → 24 →
  full-width ClayButton (destructive variant for deletes) → 8 → cancel as text
  button, labelMd `onSurfaceVariant`.
- Kinds (medallion fill / ink / icon):
  general `primaryFixed`/`primary`/`auto_awesome_rounded`;
  info `infoContainer` #D0E4FF/`onInfoContainer`/`info_rounded`;
  success `secondaryContainer` #62FAE3/`onSecondaryContainer` #007165/`check_rounded`;
  warning `errorContainer` #FFDAD6/`onErrorContainer` #93000A/`warning_amber_rounded`;
  error `error`/`onError`/`error_outline_rounded`. Callers may override the icon.
- Busy variant: the button is replaced by a 28 px spinner, stroke 3; can't be
  dismissed.
- Motion: in 300 ms (fade + scale .94→1 + translateY 4 % → 0, easeOut); out
  180 ms (reverse, flipped curve). Reduced motion: fade only.
- Web: `Modal.tsx`'s `ConfirmDialog` is a left-aligned header/footer dialog
  with two side-by-side buttons — does not match.

### 2.2 Notice — `AppDialog.notify` (transient, the toast replacement)

- Drops from the **top**, under the status bar: margin 8 top, 16 sides,
  max-width 440. Card radius 24, `surfaceContainerLowest`, 0.5 px border,
  shadow `dock`, padding start 12 / top 12 / end 16 / bottom 12.
- Row: medallion 40 (icon 20) → 12 → text: title bodyLg, message bodyMd (or
  labelMd `onSurfaceVariant` under a title).
- In: slide from −60 % of its height + fade, 300 ms easeOut; out 180 ms.
  Auto-dismiss **3200 ms**; tap or swipe up dismisses; one at a time (a new one
  replaces the old).
- Web: `Toaster.tsx` shows a coloured block at **bottom-24** for 3500 ms.

### 2.3 Buttons

**ClayButton** (the only filled button):
- Stadium. Face padding 16 vertical / 24 horizontal → face height 52; a 4 px
  **slab** (same stadium) sits under it, offset 4 down, so the box is 56.
- Face `primary` #5B3CDD; slab `onPrimaryFixedVariant` #441CC8 (solid); glow
  `0 8px 24px rgb(primary / .25)`.
- Label labelMd 14/20 **w600** `onPrimary`; optional leading icon 20, gap 8.
- `expanded` = full width; otherwise hugs content.
- Press: face moves down 4 px onto the slab and the glow disappears, 110 ms easeOut.
- Disabled: face `outlineVariant` #C9C4D8, sunk (no slab visible, no glow).
- Destructive: face `error`, slab `onErrorContainer` #93000A.

Secondary actions are **not** tonal ClayButtons — natively they are:
- text button: labelMd `primary`, stadium, optional 16–18 icon (e.g. "פריט מהיר",
  "בחירת מתכון" in meal cards, "הגדרות"/"סמן הכל כנקרא" in notifications);
- pill ClayCard (`_BulkAction`): full radius, padding 12, icon 18 + 8 + labelMd,
  ink `primary` (destructive `error`, disabled `outlineVariant`), white card;
- ClayIconButton (1.6).

Web: `.clay-btn-primary` uses slab `on-primary-fixed` @ 55 %, font-weight 700,
3 px press, opacity .6 when disabled; `.clay-btn-tonal/secondary/ghost` have no
native counterpart on phone screens.

### 2.4 Cards — `ClayCard`

- Fill `surfaceContainerLowest` (#FFF; dark #0E0D13). Border 0.5 px
  `surfaceContainerHighest`. Shadow `card`.
- Bevel: overlay gradient from the top-left corner to the centre, white @
  (50 % × bevelStrength) → white @ 0 (active: 20 %).
- Default radius **16**, default padding 16. Almost every screen passes
  **radius 24 (md)**; padding is 16 (gutter) or 24 (md) — given per screen below.
- Active (`isActive`): fill `primaryContainer` #7459F7, no border, shadow `active`.
- Tappable: press scale .98, 110 ms easeOut (`PressScale`).
- `showSpine`: an 8 px strip on the start edge, gradient start→end
  `spineColor`(default `primaryFixed`) @ 70 % → 0; content gets +16 start padding.
- Web `.clay`: radius 24 always, padding 20 via `Card`, no 0.5 px border, bevel
  as a 1 px inset line. Add a `clay-16` (radius 16) and border.

### 2.5 Tags and chips

- **ClayTag** (static): stadium, padding 4/8, fill `primaryFixed` / ink
  `primary` by default; optional icon 14 + 4 gap; labelSm 12/16 w700.
- **Dietary tag colours** (`dietaryTagColors`, fill / ink):
  meat `errorContainer`/`onErrorContainer`; dairy `infoContainer`/`onInfoContainer`;
  vegetarian `secondaryContainer`/`onSecondaryContainer`;
  vegan `secondaryFixedDim` #3CDDC7/`onSecondaryFixed`;
  kosher `tertiaryFixed` #E0E0FF/`onTertiaryFixedVariant` #2F3AA3;
  glutenFree `primaryFixed`/`onPrimaryFixedVariant`;
  allergy `surfaceContainerHighest`/`onSurfaceVariant`.
  Icons: meat `set_meal`, dairy `egg_alt`, vegetarian `eco`, vegan `spa`,
  kosher `verified`, glutenFree `block`, allergy `warning_amber` (all `_rounded`).
- **Filter chip** (`DietaryChipSelector`, the topics chips): stadium, padding
  8/12, 1 px border. Off: fill `surfaceContainerLow`, border `outlineVariant`,
  icon 16 + 4 + labelMd in `tertiary` #4651B9. On: fill = the tag's colour,
  border same, ink = the tag's ink. 180 ms easeOut. Wrap, 8 gap both ways.
- **Choice chip** (single-select, e.g. units, ingestion channels, theme,
  language, reminder slots): same geometry; on = `primary` fill, `onPrimary`
  ink; off = `surfaceContainerLow` + `outlineVariant` border + `tertiary` ink.
  Ingestion channels are larger: padding 10/14, icon 18, 6 gap, ink `primary`
  when off.
- **Plan / sort chip**: on = `primaryFixed` fill + `primary` border + `primary`
  (or `onPrimaryFixedVariant`) ink; off as above.
- Web `.pill-*` covers ClayTag colours partly; the outlined filter/choice chip
  states are hand-rolled per page.

### 2.6 Segmented control — `ClaySegmentedControl`

- Track: stadium, fill `surfaceContainer` #EFEBFF, 1 px `surfaceContainerHighest`,
  padding 4.
- Segment: padding 14 vertical / 12 horizontal → 48 tall; track 58 total.
- Only the **selected** segment shows its label: icon 18 + labelMd (with 4 px
  end padding) in `primary`; others show the icon alone in `onSurfaceVariant`.
  Selected width = icon + 4 + label + 24 + 2 (capped so others keep 42 each); the
  rest share what is left equally.
- Pill under the selected segment: white `surfaceContainerLowest`, stadium,
  shadow `control`. Pill position, widths and the label unfold all animate
  **500 ms easeOut** together (label: width + fade from the icon side).
- Optional count badge on a segment's icon (top −7, end −9).
- Used by: Recipes (mine `edit_note` / saved `bookmark`), Community (shared
  `public` / forum `forum`), Price book (receipts `receipt_long` / prices `sell`),
  Paywall tier (person / people / family_restroom).
- Web: Recipes uses a `bg-surface-low` group with a **primary-filled** active
  button showing all labels; Plans uses another variant. Missing component.

### 2.7 Text fields

- Theme input: filled `surfaceContainerLow`, 1 px `outlineVariant` border,
  radius 16, content padding 12/16, text bodyMd, hint bodyMd `outline` #797587,
  floating label labelMd `onSurfaceVariant`. Focus: 2 px `primary`.
- **Search field** (`ClayInset`, recipes + community): stadium, recessed
  gradient top→bottom `surfaceContainerHighest` → `surfaceContainerLow` (stop 45 %),
  1 px `surfaceContainerHighest`; padding 0/16; `search_rounded` 24 `outline`,
  12 gap, borderless input bodyMd with 16 vertical padding → 56 tall; a
  `close_rounded` clear icon at the end.
- Web `.clay-input`: radius 16, 2 px transparent border + inset shadow, 52 min
  height — close for the plain field; no `ClayInset` search pill.

### 2.8 Switch

Material 3 switch 52×32: on track `secondaryContainer` #62FAE3 / thumb
`onSecondaryContainer` #007165 (24 px); off track `surfaceContainerHighest`
#E3DFFF / thumb `surfaceContainerLowest` (16 px) with the M3 2 px `outline`
border. Web uses checkboxes (`accent-color`).

### 2.9 Checkbox (grocery) — `BouncyCheckbox`

24 circle, 2 px border. Off: fill `surfaceContainerLowest`, border
`outlineVariant`. On: fill + border `secondaryContainer` #62FAE3,
`check_rounded` 16 `onSecondaryContainer`; scales to 1.1 with `settle` (240 ms),
colour 180 ms; light haptic on check.

### 2.10 Progress bar — `ClayProgressBar`

Stadium groove, default 24 tall: gradient top→bottom `surfaceContainerHighest`
→ `surfaceContainer` (stop 50 %); fill stadium, gradient start→end
`primaryContainer` #7459F7 → `primary`; width animates 240 ms easeOut. Cook mode
uses 12 and 8 high versions.

### 2.11 Section header, page header, empty/error/loading

- `ClayPageHeader` (non-floating pages): title headlineLgMobile, subtitle 8 →
  bodyMd `onSurfaceVariant`; optional trailing at top +4 with 12 gap.
- `ClaySectionHeader`: headlineMd + optional trailing (bottom-aligned); with
  underline: 8 px bottom padding + 1 px `surfaceVariant` #E3DFFF rule.
- `ClayEmptyState`: centred, padding 32: 96 circle `primaryFixed` with icon 44
  `primary` → 24 → bodyMd centred `onSurfaceVariant` → 24 → optional ClayButton.
- `ErrorRetryView`: centred card r24 p24 (margin 24): 64 circle
  `errorContainer` with `error_outline_rounded` 32 `onErrorContainer` → 16 →
  "שגיאה" headlineMd → 8 → labelMd `onSurfaceVariant` centred → 16 → ClayButton
  `refresh_rounded` "נסה שוב".
- Loading: a centred Material circular spinner (36 px, 4 px stroke, `primary`).
  **No shimmer/skeletons anywhere.**

### 2.12 Lists / rows

- **Nav row** (`SettingsNavRow`, `_MenuRow`): ClayCard r24 p24; icon 22
  `primary` (destructive `error`) → 12 → label bodyLg (+ hint labelMd `outline`,
  4 above) → `chevron_right_rounded` 24 `tertiary` (mirrored). Rows are
  separated by **12** in the account menu and **24** in settings lists.
- **Group label** (`SettingsGroupLabel`): labelMd `onSurfaceVariant`, padding
  start 4, top 8.
- **Toggle row** (`SettingsToggle`): ClayCard r24, padding 12/24, title bodyMd,
  subtitle labelMd `outline`, switch at the end.
- Web `ui.tsx Row`: 44 px tinted icon tile, bold body-md label, "›" glyph,
  padding 16 — different.

### 2.13 Image placeholder — `ClayImage`

Missing image: fill `primaryFixed` (or a tint), centred `restaurant_menu_rounded`
`primary` at the given size; radius from the caller.

---

## 3. Screens

All main tabs: top bar (1.1) + body + dock (1.4) + Shefi pill (1.5). Grid
numbers are for a 390 px viewport → **350 px content width** (20 + 20 margins).

### 3.1 Recipes (tab 0, home) — `MyRecipesPage`

1. **Floating header**: "המתכונים שלי" + subtitle; pinned action: filled
   ClayIconButton 48 `auto_awesome_rounded` → ingestion.
2. Segmented control: mine / saved (2.6), margin 0/20.
3. 32 gap.
4. **Topics card**: ClayCard r24 p16 →
   ClayInset search (2.7) → 16 → "נושאים" labelSm `onSurfaceVariant` → 8 →
   DietaryChipSelector wrap (7 chips, 8 gap).
5. 32 gap.
6. **Grid**: 2 columns, 12 gap both ways, every card **248 tall** (fixed).
   At 390: 169 × 248.
   - `RecipeCard`: ClayCard r24 p8, press .98.
     - Image 136 tall, full card inner width, radius 16 (`ClayImage`, fallback
       icon 40).
     - **kcal pill**: top 8 / end 8 on the image; stadium padding 4/8, fill
       `warmAccent` #F2A93B, `bolt_rounded` 13 + 3 gap + "780 קק״ל" labelSm
       **w800** `onWarmAccent` #3B2600.
     - **time pill**: bottom 8 / start 8; same shape, fill white @ 90 %,
       `timer_rounded` 13, ink `onSurface` (e.g. "2 שע׳ ו50 דק׳").
     - Saved recipes: a remove button top 4 / start 4 (compact IconButton,
       white @ 90 %, `bookmark_remove_rounded` 18 `error`).
     - 12 gap → title bodyMd **w700**, line 1.25, max 2 lines, flexible height.
     - 8 gap → 26 px meta row (clipped, no wrap): up to 2 tags, 4 apart —
       pending analysis (`hourglass_top`, mint) or collab role (`group`, mint),
       then dietary tags (2.5 colours). Fallback: "N רכיבים" (`list_alt`,
       `surfaceContainerLow` / `tertiary`).
   - Long-press = share sheet (own recipes).
7. Bottom padding 176.
- Empty: ClayEmptyState (`restaurant_menu` / `bookmark_border`) + ClayButton
  "הוספת מתכון" `add`.
- Web gaps: header with two text buttons, sort select and a "filters" disclosure,
  aspect-ratio 4/3 images instead of fixed 136, variable card height.

### 3.2 Recipe details — `RecipeDetailsPage` (pushed)

- Bar: back, "Easy Plate", trailing `edit_rounded` (when editable).
- Light Shefi pill (1.5) bottom-end.
- ListView padding 24 top / 20 sides / 48+80 bottom:
  1. **Hero** 260 tall, radius 32, image cover; bottom gradient (centre →
     bottom, transparent → black @ 45 %). Bottom-start: up to 2 glass chips
     (stadium, padding 6/12, white @ 88 %, icon 14 `primary`, 4 gap, labelSm
     `onSurface`). Bottom-end (editable): 36 px white circle (padding 8) with
     `edit_rounded`/`add_a_photo_rounded` 20 `primary`. Tap image → full-screen
     viewer.
  2. 16 → title (ClayPageHeader, headlineLgMobile).
  3. 16 → **4 stat tiles** in a row, 8 apart (81.5 wide at 390): white, radius
     16, 1 px `surfaceContainerHighest`, padding 12/8; 36 circle accent @ 14 %
     with icon 18 accent → 8 → value bodyLg w800 (+ unit labelSm
     `onSurfaceVariant`), scaled down to fit → caption labelSm `onSurfaceVariant`.
     Tiles: prep `timer` primary; cook `local_fire_department` secondary
     #006B5F; servings `group` tertiary; kcal `bolt` warmAccent.
  4. Extra dietary tags (3rd+) as ClayTags, wrap 8.
  5. Allergen notice (`AllergenNotice`: ClayTags + "מכיל: …" line with
     `warning_amber` `error`).
  6. 32 → **Nutrition card** (r24 p24): section header "ערכים תזונתיים" with
     underline; if servings > 1 a two-pill switch (per serving / whole recipe,
     each Expanded, stadium, padding 8 vertical, selected `primary`/`onPrimary`,
     other `surfaceContainerLow` + `outlineVariant` + `tertiary`, 8 gap); 16 →
     `MacroRingWithBars` (ring 120 / stroke 12, ≤ 34 % of width; 16 gap; three
     macro bars 12 apart). Empty: 44 circle sparkle + text + "הערכה" ClayButton.
  7. 24 → pending-analysis card (mint) when relevant.
  8. "מצב בישול" ClayButton `local_fire_department` full width (if steps).
  9. 24 → **Ingredients card** r24 p24: underlined section header → 12 → rows
     (4 vertical padding): 6 px `primary` dot at top 6 → 12 → bodyMd line;
     → 24 → "רשימת קניות מהמתכון" ClayButton `shopping_cart`.
  10. 24 → **Steps card** r24 p24: underlined header → rows (8 vertical
      padding): 28 circle `primaryFixed` with the number labelSm `primary` → 12
      → bodyMd.
- **Macro visuals**: protein `secondary` #006B5F, carbs `tertiary` #4651B9,
  fat `warmAccent` #F2A93B. Bar: 10 dot + label labelMd (flex 3) + grams labelMd
  w800 end-aligned (flex 2) + 8 + 34 px percent labelSm; then 4 → 10 px track
  `surfaceContainerHigh` with a fill in the macro colour (500 ms easeOutCubic).
  Ring: track `surfaceContainerHigh`, round caps, 0.06 rad gaps between arcs,
  starts at 12 o'clock, draws in over 700 ms easeOutCubic; centre: kcal
  headlineMd w800 + "קק״ל" labelSm.

### 3.3 Ingestion / add — `IngestionPage` (pushed)

- Bar: back, "הוספת מתכון". Body ListView padding 20.
1. ClayPageHeader "הוספת מתכון".
2. 24 → "מאיפה מגיע המתכון?" labelMd `onSurfaceVariant` → 12 → channel chips
   (wrap 8): rawText `content_paste`, webSearch `travel_explore`, urlScrape
   `link`, socialVideo `play_circle`, aiRequest `auto_awesome`, manual
   `edit_note`, file `mic` (2.5 ingestion chip; selected = primary fill).
3. 24 → AI quota pill (when AI is gated): stadium, padding 8/12, fill
   `primaryFixed` (blocked: `surfaceContainerHighest`), icon sparkle/lock/play
   + 8 + labelSm; 24 below.
4. Channel card r24 p24: intro row (44 circle `primaryFixed` + channel icon 22
   `primary`, 12, title headlineMd) → 12 → description bodyMd
   `onSurfaceVariant` line-height 1.5 → 16 → text field (8 lines raw text, 4 AI
   request, 2 otherwise).
5. 32 → full-width ClayButton "נתח מתכון" (sparkle; play/lock variants for
   rewarded/blocked).
- Parsing: centred spinner + 16 + bodyMd.
- Review: ListView p20 with medallion, headlineLgMobile title, tags, ingredient
  and step cards (as 3.2), bottom bar padding 20: ClayButton "edit" + 12 +
  expanded ClayButton "save" (`bookmark_added`).

### 3.4 Library (tab 1) — `LibraryPage`

- Floating header "הספרייה שלי" + subtitle, bottomGap 32; pinned filled 48
  `add_rounded` → create book (prompt dialog, then spine-colour dialog).
- Grid: 2 columns, cross gap 16, main gap **32**, aspect **0.72** → 167 × 232 at 390.
- **Book cover** (`ClayBookCover`): radius start 8 / end 24 (spine side is the
  start edge, i.e. the right in Hebrew), fill white, shadow `book`; a 12 px
  solid **spine** on the start edge; image fills the top (cover, tinted
  fallback spine @ 12 % with `menu_book` 56); text block padding 12: eyebrow
  "אוסף" labelSm in the spine colour → 4 → title bodyLg w700 (2 lines) → 4 →
  `menu_book_rounded` 16 `outline` + 4 + "6 מתכונים" labelMd `outline`. Press
  scale .98.
- Spine colours: violet `primary`, indigo `tertiary`, teal `secondary`, mint
  `mintFresh` #2DD4BF, amber `warmAccent`, coral #E8734A, rose #D6457A, plum
  #8E44AD, forest #2E8B57, slate #5C6F82. Unset: hash of the id over
  primary/secondary/tertiary.
- Long-press: bottom sheet (title headlineMd, optional role tag, option cards:
  share `person_add_alt_1`, cover `image`, spine colour (24 swatch), rename
  `drive_file_rename_outline`, delete/leave in `error`).
- Empty: ClayEmptyState `auto_stories` + "ספר חדש" ClayButton.

### 3.5 Book viewer — `OpenBookShell` (pushed, full screen, no bar, no dock)

- Background: gradient top-left → bottom-right `surfaceContainer` →
  `surfaceDim` #DAD6FF.
- **Capsule** (QuickJumpCapsule) floating at top 12, centred: stadium,
  padding 8/16, fill `surface` @ 80 % + blur 12, 1 px `outlineVariant` @ 30 %,
  shadow `card`. Buttons: icon 20 + 4 + labelSm, all `onSurfaceVariant`,
  separated by 1×24 dividers (`outlineVariant` @ 50 %, 12 margin): back
  `arrow_back`, contents `auto_stories`, add `add`, quick nav `grid_view`.
  Reserved height 72.
- Book: inset 16 sides/bottom, top 72+8; clipped to radius 16; page stock
  `surfaceBright`; inner-edge shadow on each page (24 px gradient
  `onSurface` @ 6 % → 0); page padding 24 / 48 top / 24 / 24.
- Portrait: one page, curl/page-flip 300 ms; jumps riffle through pages
  (fast-turn preference), optional click sound. Landscape (tablets only): a
  two-page spread, 600 ms per spread.
- Recipe page: image 160 tall r24 → 16 → title headlineLgMobile → tags → time
  tags (timer primary, cook mint) → 24 → section heading (headlineMd `primary`,
  8 bottom padding, 2 px `primaryFixed` underline) → ingredients (6 px dots) →
  steps (26 circles) → page number labelSm `outline` at the bottom.
- Contents page: cover 140 tall r24, title headlineLg, heading, rows with a
  dotted leader (2 px `outlineVariant`) and page number labelMd `primary`.

### 3.6 Meal plan board (tab 2) — `MealPlannerPage`

- Floating header: title = plan name, subtitle "תפריטים", bottomGap 0.
  Pinned (start→end): ghost 48 `person_add_alt_1` (share, own plans), ghost 48
  `more_horiz` (options sheet), 8 gaps, **filled** 48 `playlist_add` (new plan).
  Hebrew: filled is leftmost.
- Body (padding 20 sides except the day strip):
  1. shared role tag (if shared), 8 above.
  2. If > 1 plan: plan chips (wrap 8; padding 8/16; selected `primaryFixed` +
     `primary` border + `primary` labelMd; other `surfaceContainerLow` +
     `outlineVariant` + `tertiary`); long-press = options. Then 32.
  3. **Day strip** (`ClayDaySelector`): horizontal scroll, 90 tall, padding
     0/20, tiles **72×90**, gap 12; each a ClayCard r24 padding 12 vertical,
     centred: weekday labelSm (`primary`; active `primaryFixed`) → 4 →
     `restaurant_rounded` 16 + 4 + count headlineMd (`primary`; active
     `onPrimaryContainer`). Active tile = `primaryContainer` #7459F7 + shadow
     `active`. The strip scrolls horizontally from the start edge (Sunday at the
     right in Hebrew).
  4. 16 → **Daily totals card** r24 p16: row "סה״כ ליום" ClaySectionHeader +
     filled ClayIconButton 40 `insights_rounded` → dashboard; 12 → ring 104 /
     stroke 11 + 16 + MacroLegend (10 dot, 8, label labelMd, 8, grams labelMd w800
     `onSurfaceVariant`; rows 4 apart). No data: ring 88/10 with a
     `restaurant` icon in the middle + labelMd text. Missing-data line:
     `info_outline` 14 + labelSm `outline`.
  5. 16 → **meal cards**, 24 apart: ClayCard p16 **with spine** (radius 16):
     header row = ClayTag (meal name, `restaurant_rounded`, full width) + delete
     IconButton `delete_outline` 20 `outline`; 12 → items (4 vertical padding):
     `menu_book_rounded` (recipe) / `edit_note_rounded` (quick) 18 `primary` →
     8 → bodyMd (+ ingredients labelSm `outline`, 1 line) → `close_rounded` 16
     `outline`; → divider (24 tall) → two Expanded text buttons: "בחירת מתכון"
     `restaurant_menu` 18, "פריט מהיר" `edit_note` 18.
  6. **Add meal**: `ClayDashedCard` — dashed 2 px border (`primary` @ 30 %,
     dash 8 / gap 6) radius 16, fill `surfaceContainer` @ 30 %, padding 24,
     centred: 56 `primary` circle with `add` 28 white → 12 → bodyLg `primary`
     → 4 → labelMd `outline` hint.
- Create plan: bottom sheet (title, name field, template cards r24 p16 —
  active = `primaryContainer` with check — and save ClayButton).
- Web gaps: breadcrumb back link, plan list as a separate page, day buttons as
  bordered 72-wide pills with text counts, meal cards in a 1–2 column grid.

### 3.7 Nutrition dashboard — `NutritionDashboardPage` (pushed)

- Bar: back, "דאשבורד תזונה". ListView 24 top / 20 / 48 bottom.
1. ClayPageHeader plan name + "שבועי".
2. 16 → two hero tiles, 12 apart, each padding 16 r24: daily average (filled
   `primary`, ink `onPrimary`) and week total (white, 1.5 px `warmAccent` @ 50 %
   border). Caption labelSm @ 80 % → 8 → value headlineLgMobile w800 → unit
   labelMd @ 80 %.
3. 16 → "לפי יום" card r24 p16: header → 16 → bars area 168 tall, 7 bars 8
   apart: value labelSm 10 px on top, stacked bar (fat top, carbs, protein
   bottom), radius 8, min 6 % height, empty = `surfaceContainerHigh`; weekday
   labelSm below (selected `primary` w800). Tap toggles a selected day (others
   40 % opacity) and a summary strip (`primaryFixed` r16 p12).
4. 16 → "חלוקת קלוריות": MacroRingWithBars 128/14 + "ממוצע ליום" labelSm.
5. 16 → "לפי ארוחה": rows (4 vertical): weekday labelSm 44 wide, meal labelMd,
   kcal labelMd w800.

### 3.8 Groceries (tab 3) — `GroceryListPage`

- Floating header "רשימת קניות", bottomGap 32; pinned: ghost 48
  `receipt_long` (price book), ghost 48 `autorenew` (rebuild), **filled** 48
  `add` (add item). Viewer-only lists: only the price-book button.
- Body (20 sides, bottom 176):
  1. **List switcher card** (`GroceryListSwitcherCard`) r24 p24: 36 square r8
     `primaryFixed` with source icon 20 `primary` (plans `calendar_month`, recipe
     `restaurant_menu`, manual `edit_note`) → 12 → name bodyLg + source labelMd
     `onSurfaceVariant` → 12 → stadium pill padding 4/12 `surfaceContainerLow`
     + `outlineVariant` border: "N רשימות" labelSm `primary` + 4 +
     `unfold_more` 16. Tap → lists sheet (3.9).
  2. 16 → role tag (shared) → 16.
  3. Source card: plans → `MealPlanFilterCard` r24 p24 (`filter_list` icon,
     summary bodyLg, chips of chosen plans, "בחר תפריטים" ClayButton
     `checklist`); recipe → `RecipeListCard` r24 p24 with a scale stepper. 16.
  4. **Progress card** r**48** p24: "התקדמות איסוף" labelMd + percent headlineMd
     `primary` on the end → 12 → ClayProgressBar 24 → 12 → "7 מתוך 11 פריטים
     נאספו" labelSm `outline` (end-aligned).
  5. 16 → two `_BulkAction` pills, Expanded, 12 apart: select-all
     `done_all` (or clear `remove_done`) `primary`; delete checked
     `delete_sweep` `error`.
  6. 32 → **Section "פריטים לא מסומנים"** header: tap to collapse;
     `chevron_right` `primary` rotated 90° when open (240 ms), 8 →
     headlineMd → count pill (stadium padding 4/12 `primaryFixed`, labelSm
     `primary`); 8 bottom padding + 1 px `surfaceVariant` rule. 16 gap, then rows
     12 apart. Collapse animates size + fade 240 ms easeOut.
  7. 32 → section "פריטים מסומנים", collapsed by default.
  8. 32 → **Cost card** r24 p16: 44 circle `warmAccent` @ 18 % with
     `payments_rounded` → 12 → "סה״כ משוער" labelMd → total headlineMd w800 →
     "משוער · N ללא מחיר" labelSm `outline`; filled ClayIconButton 44
     `document_scanner` (scan receipt).
- **Item row** (`GroceryItemCard`): ClayCard **with spine**, padding 0, radius
  16; inner row padding 16: expand chevron (`chevron_right` `outline`, rotates
  90°) or a 24 spacer → 8 → name bodyLg (checked: `outline` + line-through) +
  amount labelMd `outlineVariant` ("1.0 ק״ג") → price chip (padding 4,
  `receipt_long`/`groups` 13 `outline` + 3 + "₪59.90" labelMd w800 `onSurface`,
  end padding 8; tap = add price) → BouncyCheckbox 24. Expanded: source
  breakdown strip (`surfaceContainerLow`, padding 12 / 32 start) + "התאם כמויות"
  text button. Swipe end→start to delete (background `errorContainer` r16,
  `delete_rounded` at the end, 20 inset).
- Web gaps: no floating header (static header + inline buttons), progress and
  cost in a side column, 10 px plain progress bar, ghost text buttons for bulk
  actions, no spine, different checkbox.

### 3.9 Grocery lists overview

Not a page natively: a **bottom sheet** (max 75 % height) from the switcher
card: padding 24/20, "הרשימות שלי" underlined section header → 16 → list rows
12 apart → 24 → "רשימה חדשה" ClayButton. Row = ClayCard r24, padding
start 24 / top 12 / end 4 / bottom 12, open list filled `primaryFixed`:
`check_circle`/`radio_button_unchecked` 22 `primary` → 12 → name bodyLg +
source labelMd → shared `group` 16 `tertiary` → `more_vert` menu (rename,
share, delete). New list → sheet with source option cards (r24 p24, icon 24,
title bodyLg, description labelMd, chevron). Web has a separate `/groceries`
page instead.

### 3.10 Price book + receipts — `PriceBookPage` (pushed from groceries)

- Bar: back, "המחירים שלי". Header (not floating) padding 24/20: title +
  trailing row of 48 buttons: delete-all `delete_sweep` (prices tab, ghost),
  add price `sell` (ghost), scan `document_scanner` (filled).
- 16 → segmented control receipts / prices.
- 12 → receipts tab: sort chips (padding 6/12, labelSm; on `primaryFixed` +
  `primary` border, ink `onPrimaryFixedVariant`) + filter IconButton
  (`filter_alt`, active filled `primaryFixed`). Prices tab: dense search field
  (`search` 20) → 8 → sort row + filter.
- 12 → list (padding 20, bottom 176):
  - Receipt row: ClayCard r24 p16, 12 apart: 44 circle `primaryFixed` +
    `receipt_long` `onPrimaryFixedVariant` → 12 → store bodyLg + "date · N
    פריטים" labelMd → total bodyLg w800 → optional `image` IconButton.
  - Price row: ClayCard r24 padding 12/16, 8 apart: name bodyMd + "store · date"
    labelSm; end column: price bodyLg w800 + unit labelSm.
- Receipt details: bar back + delete; ClayPageHeader store (+ rename edit
  button) / date subtitle; "view image" ClayButton; "captured" card r24 with
  lines.

### 3.11 Community (tab 4) — `CommunityPage`

- Bar title "קהילה" (not "Easy Plate"), avatar + bell.
- **Fixed** segmented control (does not scroll): padding 24 top / 20 sides,
  shared recipes `public_rounded` / forum `forum_rounded`; 24 below. Each tab
  builds lazily, then stays alive.
- **Shared feed**: fixed top block (padding 0/20/12): quota banner → row of
  ClayInset search (2.7, placeholder "שם מתכון או שם מפרסם") + 12 + filter
  button (52 circle: padding 16, `surfaceContainerLow` + `outlineVariant`
  border, `tune_rounded` 20 `tertiary`, a 12 px `error` dot with 2 px
  `background` ring when filters are on) → 12 → three Expanded scope chips, 4
  apart (padding 8 vertical, stadium; on `primaryFixed` + `primary` border, ink
  `primary`; off `surfaceContainerLow` + `outlineVariant`, ink `tertiary`;
  labelSm). Then the pull-to-refresh list (padding 0/20, bottom 176), cards 12
  apart, a native ad card every N items for free accounts.
- **Feed card** r24 p24: `AuthorRow` (32 avatar circle — photo or
  `primaryFixed` + `person` 18 — → 12 → name labelMd, 1 line → age labelSm
  `onSurfaceVariant` "3d") [+ edit/delete IconButtons 20 for own posts] → 12 →
  row: title bodyLg (2 lines) [+ gate badge 18 `tertiary`] → 4 → first four
  ingredients joined " · " labelMd `onSurfaceVariant` (2 lines); optional 64 px
  thumbnail r16 at the end (12 start padding) → 12 → row: like button
  (`favorite_rounded` 20 `error` / `favorite_border_rounded` `tertiary` + count
  labelMd `tertiary`) … spacer … "שמירה למתכונים שלי" ClayButton
  `bookmark_add_rounded` (or a mint "נשמר" ClayTag).
- Page FAB `ios_share_rounded` bottom-start (1.5).
- **Forum list**: pull-to-refresh list of post cards r24 p24: AuthorRow →
  12 → title bodyLg → 4 → body bodyMd `onSurfaceVariant` (3 lines) → 12 →
  like + 24 + `mode_comment_outlined` 16 + 4 + count labelSm `tertiary`.
  Incoming-posts pill: centred at top 12, `primary` stadium, elevation 4,
  padding 8/16, `arrow_upward` 16 + 4 + labelMd white; slides/fades in from
  −50 % (180 ms). FAB `edit_rounded` bottom-start → composer sheet (radius 24,
  padding 24, underlined "פוסט חדש", title + 5-line body fields, "פרסם"
  ClayButton `send`).
- **Forum thread** (pushed): bar back + "פורום"; pull-to-refresh; post card r24
  p24 (title headlineMd, body bodyMd, like), "N תגובות" labelMd, reply cards
  r24 p24 (highlighted reply `primaryFixed`), reply composer docked at the
  bottom (padding 12/20, attach `attach_file` `primary`, 1–3 line field, send
  `send_rounded` `primary`).

### 3.12 Notifications / inbox — `NotificationsPage` (pushed from the bell)

- Bar: back, "התראות", trailing `delete_sweep_rounded` (delete all).
- Pull-to-refresh list padding 20, items 12 apart:
  1. running cook sessions first (card r24 p24: 40 circle `primaryFixed` +
     `local_fire_department`, "בבישול" bodyLg, progress, two ClayButtons
     resume `play_arrow` / stop `stop`).
  2. a row of two text buttons: "הגדרות" `tune` 18 … "סמן הכל כנקרא" `done_all` 18.
  3. notification cards r24 p24; **unread = `primaryFixed` fill**; title bodyMd,
     meta labelSm `onSurfaceVariant`, actions (accept ClayButton `check` + decline
     labelMd `error`; forum reply `forum` 18 + open text button; admin message
     `campaign`/`support_agent`). Swipe end→start to delete (`errorContainer`
     r24, `delete_rounded`).
- Empty: ClayEmptyState `notifications_none_rounded`.

### 3.13 Account menu (the "more"/profile page) — `AccountMenuPage`

- Bar: back, "עוד". ListView padding 20.
- Profile card r24 p24: avatar 56 → 12 → name bodyLg + email/phone labelMd
  `onSurfaceVariant` (tap → profile edit).
- 32 → menu rows (2.12 nav row, r24 p24, 12 apart): Premium
  `workspace_premium`, web `language`, shared access `group`, household
  `family_restroom`, settings `settings`, preferences `tune`, Shefi
  `auto_awesome`, help `help_outline`, admin `admin_panel_settings` (admins).
- 48 → sign-out ClayButton `logout` full width → 24 → version labelSm.
- Web: `/menu` (a list of all nav entries) and a dropdown profile menu — neither
  matches.

### 3.14 Settings + preferences — `SettingsPage`, `PreferencesPage`

- Bar: back + "הגדרות"/"העדפות". `SettingsBody`: ClayPageHeader at 24/20 → 32 →
  list (20 sides, bottom 176) with **24** between rows.
- Settings rows: group "חשבון" → profile `person`, shared access `group`; group
  notifications → `notifications`; language card (`SettingsCard` r24 p24:
  section header + 16 + centred wrap of choice chips with a `check` 16 on the
  selected); home widgets `widgets`; wake word `record_voice_over`; appearance
  card (chips `brightness_auto`/`light_mode`/`dark_mode`); danger zone →
  delete account `delete_forever` (error).
- Preferences: shopping group → shopping-day card (weekday selector) +
  community-prices toggle; dietary card (DietaryChipSelector); books group →
  fast page turn + sound toggles.
- Notification settings: toggle rows + reminder slot chips (`notifications_active`
  / `notifications_none` 16).

### 3.15 Paywall — `PaywallPage` (pushed)

- Bar: back, "איזי-פלייט פרימיום". ListView padding 20.
- 8 → 88 circle `primaryFixed` + `workspace_premium_rounded` 48 `primary` → 16
  → headline headlineMd centred → 8 → bodyMd `onSurfaceVariant` centred → 24.
- Benefits card r24 p16: rows 12 apart, each 36 circle `secondaryFixed`
  #62FAE3 + icon 20 `onSecondaryFixedVariant` (`block`, `menu_book`,
  `auto_awesome`, `family_restroom`) → 12 → bodyMd.
- 24 → (households) tier headlineMd + labelMd + segmented control.
- Offer cards (r24, padding 12/16, selected `primaryFixed` fill):
  `radio_button_checked/off` (`primary`/`outline`) → 12 → period bodyLg + intro
  labelSm `secondary` → price bodyLg w700 (+ struck original labelSm).
- 8 → "מתחילים ב-…" ClayButton `lock_open_rounded` → 12 → price terms labelMd
  `onSurface` → 24 → legal labelSm `onSurfaceVariant` → 16 → links (wrap 16/4,
  labelMd `primary` underlined): restore, coupon, terms, privacy.
- Active subscriber: mint card (`secondaryFixed`) with `verified` 40, headline,
  manage ClayButton `cancel_outlined`.

### 3.16 Shefi chat — `AssistantPage` (pushed)

- Bar: back, title "שפי" (or the scoped item's title), trailing
  `add_comment_outlined` (new chat).
- Messages list padding 16/20. Bubbles: max-width 320, padding 12/16, margin 12
  bottom, radius 24 with the tail corner 8 (user: `primary` fill, `onPrimary`
  text, tail at bottom-end; Shefi: white + 1 px `surfaceContainerHighest`, tail
  at bottom-start; error: `errorContainer`). Text bodyMd. Typing: three 7 px
  dots pulsing over 900 ms.
- Tool cards r24 p16 (recipe card: 44 square r8 `primaryFixed` +
  `restaurant_menu`, eyebrow labelSm `secondary`, title bodyLg, chevron;
  grocery card with 22 px check rows; plan card `calendar_month`).
- Suggestion chips (Material ActionChip, sparkle 16 `primary`) after the last
  message, wrap 8.
- "working on …" labelMd `outline` line above the input.
- **Input bar**: padding 20 sides, 12 + keyboard bottom; a ClayCard r**32** p12
  holding a ClayInset field (r24, padding 0/16, 12 vertical, bodyMd; listening
  hint in `primary`) and 44 px round buttons: mic (`mic`/`stop`) and send
  (`arrow_upward`, filled) or stop while busy. Field grows to multi-line and
  moves the buttons below it when the text is long.
- Locked view: 72 circle sparkle 36, headlineMd, bodyMd, Premium ClayButton.

### 3.17 Cook mode — `CookModePage` (pushed, full screen, screen kept on)

- Bar: leading `close_rounded`, title "מצב בישול", action ghost 40
  `format_list_bulleted` (ingredients sheet).
- Top block padding 16/20: "שלב 2 מתוך 6" labelMd `onSurfaceVariant` … 
  `brightness_7` 14 + "המסך דלוק" labelSm `outline` → 8 → ClayProgressBar 12.
- Running-timers strip (card r24 padding 12/16, rows with progress 8) when
  other steps' timers run.
- PageView of steps (swipe; 300 ms easeOut when driven by buttons). Step page
  padding 16/20: [timer card first, if the step names a duration: r24 p16,
  `timer` 20, label labelMd, remaining **displayLg 40** , progress 8, start/pause
  ClayButton + 56 reset round button; finished → mint] → step card r**32** p24:
  44 circle `primaryFixed` with the number headlineMd `primary` → 16 → step text
  **headlineMd 24 w600, line-height 1.4** → 12 → "ingredients in this step" card
  r24 p16 with amount chips (stadium, padding 8/12, amount bodyLg `primary` + 8 +
  name bodyMd).
- Bottom bar padding 12/20/16: 56 round `arrow_back` (previous) → 12 → expanded
  ClayButton next `arrow_forward` / done `check`.
- Ingredients sheet: radius 32 top, own handle 40×4, padding 12/20/48.

### 3.18 Sharing management — `SharingManagementPage`

- Bar: back, "ניהול שיתופים", trailing `qr_code_scanner` (join by code).
- Pull-to-refresh ListView padding 20: three sections, each an underlined
  ClaySectionHeader (12 bottom) + cards (r24 p24, 12 apart) or a muted line
  (labelMd `outline`, 12 vertical): pending invites (accept ClayButton +
  decline text), shared by me (kind tag + member rows with `person_remove` 20
  `error`), shared with me (`logout` 20 `error`); then the books-and-lists card.
  Kind tags: recipe `restaurant_menu`, book `menu_book`, plan
  `calendar_month`, list `shopping_cart`, household `family_restroom`; role tags
  mint (`edit` / `visibility`). Optional 64 px thumbnail r16.

### 3.19 Household — `HouseholdPage`

- Bar: back, "חשבון משותף". ListView padding 20.
- Hero: 88 rounded square r24 `primaryFixed` + `family_restroom` 44 `primary`
  → 12 → title headlineMd centred → labelSm.
- No household: bodyMd explainer → name field → "צור" ClayButton
  `add_home` (or "ראה תוכניות" `workspace_premium`).
- Household: seats line labelSm; 32 → "חברים" underlined header → member cards
  r24 p24 (`star` owner `primary` / `person` `tertiary`), 12 apart → 24 →
  invite section (ClayButton `qr_code_2`) → 32 → dissolve / leave ClayButton
  (destructive).

### 3.20 Support chat — `SupportChatPage`

- Bar: back, thread subject (or "צור קשר").
- Thread padding 16/20. Bubbles: max 80 % width, padding 8/12, radius 16 with
  the tail corner 0 (mine: `primaryFixed`, tail bottom-end; admin:
  `surfaceContainer`, tail bottom-start); sender labelSm (`primary` /
  `tertiary`) → 2 → selectable bodyMd → 2 → time labelSm `outline`.
- Closed: `lock` 16 + labelMd notice. Composer padding 8/16/16(+keyboard):
  field + 8 + filled 48 `send_rounded`.
- Support page (entry): cards for the tutorial (`school`), Shefi
  (`auto_awesome`), contact (`support_agent`) with chevrons; WhatsApp `chat` and
  email `mail` buttons.

### 3.21 What's new — `WhatsNewBookPage`

Same `OpenBookShell` as 3.5 with one capsule action (`close_rounded`
"סגור"). One leaf per feature: illustration (image 140 tall r16, or 88 circle
`primaryFixed` + icon 44 in a 104 box) → 12 → "N/M" labelSm + date labelSm
`outline` → 12 → title headlineLgMobile (+ Premium tag) → 8 → body bodyMd
`onSurfaceVariant` → 24 → optional "פתח" text button `open_in_new` 18 → page
dots (6 px, active 14 wide) + next/"הבנתי" ClayButton (`arrow_forward` /
`check`).

---

## 4. Biggest gaps: native vs the current web under lg

Ordered by how much they change the look:

1. **Dock**: web = dark `nav-dock` pill, icon-only 48 px circles, mint active,
   a 6th "menu" item, `inset-x-3`. Native = Liquid-Glass capsule (white
   blurred glass, specular rim), **icon + 10.5 px label**, sliding white
   lozenge with `primary` ink, drag-to-select, 20 px margins, 24 bottom, 5 tabs only.
2. **Top bar**: web = sticky blurred header with logo, bell-with-dot,
   language select, theme toggle, avatar dropdown. Native = opaque white 68 px
   bar: avatar (start) · "Easy Plate" 24 px `primary` · bell with numeric
   badge (end); the menu is a pushed page from the avatar.
3. **No floating header / pinned round actions** on the web; pages use static
   `PageTitle` (32 px, `animate-rise`) and inline text buttons. Native: 28 px
   title that floats away with a frosted background, the round 48 px "+"/sparkle
   pinned at top-end.
4. **No floating buttons**: Shefi pill (end corner) and the page FAB (start
   corner) above the dock are missing; bottom padding is 112 instead of 176.
5. **Dialogs and notices**: web uses a header/footer `<dialog>` and a bottom
   toast; native uses the centred medallion card (32 radius, stacked
   full-width button + text cancel, blurred backdrop) and a top-dropping notice.
   No bottom sheets on the web at all.
6. **Segmented control**: missing. Web uses primary-filled tabs with all labels;
   native uses the recessed track, white sliding pill, label only on the
   selected segment, 500 ms unfold.
7. **ClayButton**: web slab colour (`on-primary-fixed`/55 %), weight 700,
   3 px press, opacity disabled; native solid `#441CC8` slab, weight 600, 4 px
   sink, grey `outlineVariant` disabled face. Web tonal/ghost buttons have no
   phone counterpart.
8. **Icons**: web stroke SVGs vs native filled Material Icons Round.
9. **Fonts**: web Heebo for Hebrew vs native system Hebrew (SF Hebrew / Noto
   Sans Hebrew); web lacks the 28 px `headlineLgMobile`.
10. **Page background**: web has a radial lavender + mint wash; native is flat
    `background`.
11. **Cards**: web `.clay` lacks the 0.5 px `surfaceContainerHighest` border and
    the 16 px default radius; padding 20 vs native 16/24; no spine variant
    (meal and grocery cards).
12. **Screen layouts**: recipes card is aspect-ratio based instead of fixed
    248/136 with the topics card above; groceries puts progress/cost in a side
    column with a thin bar; plans has a breadcrumb + separate plan list and
    bordered day pills instead of the 72×90 clay day tiles and the daily ring
    card; grocery list overview is a page instead of a sheet; community lacks
    the fixed segment + search pill + scope chips layout.
13. **Motion**: no iOS push transition between routes, no press-down scale on
    cards (.98) and icon buttons (.92), no AppMotion tokens; `animate-rise` on
    titles has no native counterpart.
14. **Pull to refresh, switches, cook-timer banner, circle grocery checkbox**:
    missing or replaced by browser defaults.

### Suggested web primitives to add (under lg)

`TopBar`, `NavDockGlass`, `FloatingHeaderView` (+ pinned action slot),
`ShefiFab`, `PageFab`, `ClayIconButton`, `ClayButton` (fix slab/weight/press),
`ClayCard` (radius 16|24, border, spine, press), `ClayTag`, `FilterChip`,
`ChoiceChip`, `SegmentedControl`, `SearchPill` (ClayInset), `BottomSheet`,
`AppDialog` (show + notify), `EmptyState`, `ErrorRetry`, `ProgressGroove`,
`BouncyCheckbox`, `Switch`, `StatTile`, `MacroRing`/`MacroBar`, `DaySelector`,
`DashedAddCard`, `CountBadge`, plus the motion CSS variables in 0.5 and the
`headline-lg-mobile` text size.
