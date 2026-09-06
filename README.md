# EasyPlate

Recipe books, weekly meal planning, and an aggregated grocery list — offline-first,
Hebrew/RTL. Built on Clean Architecture + BLoC per `.claude/instructions.md`.

## Running

```bash
flutter pub get
dart run build_runner build          # freezed + hive adapters + json + slang
flutter run
```

Codegen must run after any change to a model, a bloc, or `assets/i18n/he.i18n.json`.

## Accounts and Firebase

Sign-in is mandatory — the router gates every screen behind
`AuthSessionService`, which moves the user through `signedOut →
needsEmailVerification → needsProfile → needsOnboarding → ready`. Three
providers are wired: Email/Password, Phone (SMS), and Google.

`needsEmailVerification` applies only to accounts with a `password` provider:
Google arrives verified and a phone account has no address to prove.

A profile is split across two documents. `users/{uid}` is private to its owner
and holds the email, phone and push token. `public_profiles/{uid}` holds only
the display name and photo and is readable by any signed-in user — the split
exists because Firestore rules grant or deny a *whole* document, so opening
`users` up far enough to show an author's name would have exposed their contact
details too.

Community posts and shared recipes store `authorUid` and resolve the name and
photo from `public_profiles` at read time, one batched lookup per page. That is
what makes renaming an account update everything it ever posted on the next
refresh. Each document still keeps the name it was published with, used only as
a fallback for an author whose public profile is missing (a pre-split account,
or a deleted one) so those rows render a name rather than a blank. Signing in
republishes the public half, which backfills accounts that predate it.

New accounts land on `ProfileSetupPage` (full name, photo) before onboarding.
Email and phone are shown there as *identities*, not editable text — the only
way to add one is its verification flow (`linkWithCredential`). That is what
makes signing in later by a linked phone resolve to the same account rather
than creating a second one; `credential-already-in-use` is surfaced when the
number belongs to somebody else. The profile is a Firestore document at
`users/{uid}`; the photo goes to Storage at `profile_photos/{uid}.jpg`. Local
`UserPreferencesEntity` stays on the device and is unrelated.

There is no settings tab. Every main screen carries the account avatar (photo,
or initials) in its app bar, which opens the account menu: Settings, My
profile, Support, and sign-out. Support hands off to WhatsApp or an email
client — both need the `<queries>` entries in `AndroidManifest.xml` to be
visible on Android 11+.

**Support contacts are placeholders.** `SupportPage.supportPhone` and
`supportEmail` need real values before release.

Remote Config carries `isProd`. Non-production builds show a **DEV** badge
above sign-out in the account menu; production behaves exactly as before. The
in-app default is `true`, so a failed or slow fetch never puts a DEV marker in
front of a real user — the console conditions (`IsAndroidProd` / `IsIosProd`,
keyed on app version) decide the rest.

A parameter that exists in the console with **no value** comes back as an empty
string with `source=valueRemote`, which shadows the in-app default; `asBool("")`
is false, so a blank parameter would mark a production build as DEV. Blank is
therefore treated as "not configured" and falls back to the default. Set both
the parameter's default value and its conditional values in the console —
`false` by default, `true` under `IsAndroidProd` / `IsIosProd` — or the flag
never actually does anything.

Remote Config **persists activated values on disk**, so a value fetched under
an old condition survives restarts. The app therefore re-fetches on every
entry — at launch and on each resume (`FirebaseService.refreshRemoteConfig`) —
and the flag is a `ValueNotifier` so screens re-render when a refresh lands
rather than holding whatever they read once. Each refresh logs the value, its
source (`remote` = console, `static` = in-app default) and the fetch status.

Analytics, Crashlytics, Messaging and Remote Config are booted in
`FirebaseService` (`lib/core/services/firebase_service.dart`). Push permission
is deliberately requested only once a user is signed in and onboarded, so the
prompt has context.

### Setup that lives outside this repo

```bash
firebase deploy --only firestore:rules,storage   # firestore.rules, storage.rules
```

Without those rules the default deny-all blocks every profile read and write,
and the whole Community tab as well.

Config comes from `android/app/google-services.json` and
`ios/Runner/GoogleService-Info.plist` — there is no generated
`firebase_options.dart` to keep in sync.

## Per-account local data

Every Hive box is namespaced by the signed-in uid (`UserScope`, in
`lib/core/hive/`): `recipesBox_<uid>`, and the same for books, meal plans,
grocery lists and preferences. A single fixed box name is one shared file for
whoever happens to be signed in, which is how one account's recipes were
visible to the next. Firestore holds the community and is deliberately *not*
scoped — it is shared by design.

Consequences worth knowing:

- Preferences (including language and `onboardingComplete`) are per account, so
  they cannot be read until auth resolves. The splash and login run on
  `DeviceLocaleStore` — a device-wide box holding only the language, which is
  deliberately *not* scoped because it is needed before any account exists. It
  falls back to the device locale the first time, and the account's own
  language takes over on sign-in.
- The login screen has a language picker, and a new account inherits whatever
  was picked there; changing language in settings mirrors back to the device
  store so the next login screen opens in the language last actually used.
- `UserScope.open` throws rather than falling back to an unscoped box. A silent
  fallback is exactly the bug it exists to prevent.
- Boxes are closed when a *different* account signs in, not at sign-out —
  closing at sign-out races the screens still being torn down.
- **Local data written before this existed stays in the old unscoped boxes and
  will not appear.** There is no migration.

The recipe list is driven by `watchRecipes()` off the box itself, so a recipe
saved from ingestion, the editor, or the community shows up without the list
having to notice it was navigated back to.

## Sharing a recipe with another account

Long-press a recipe in My Recipes (owner only) to share it by the other
person's **email or phone**, as viewer or editor. Finding them never exposes a
contact: `user_directory/{sha256(contact)}` maps a hash to a uid, written for
each verified contact whenever the public profile is published. A share turns
the recipe into a Firestore document, `collab_recipes/{id}`, which becomes the
source of truth — every account's local copy is a cache of it, refreshed when
the recipe is opened (`SyncCollabRecipeUseCase`) and written through on save
(`SaveCollabRecipeUseCase`: document first, cache second). Viewers are
read-only at three layers: the UI, the use case, and the rules.

An invite is `share_invites/{collabId}_{targetUid}` — a deterministic id, so
when the target adds themselves to the recipe's members the rules can look the
invite up and verify the role they claim is the one they were offered. The
recipient answers from the inbox or from *ניהול שיתופים*; accepting writes a
local cache under a fresh id. If the owner deletes the shared document, a
member's cache degrades to an ordinary private recipe rather than vanishing.

### Notifications and push

Every share also drops an item into `notifications/{targetUid}/items`, which
the bell in every main screen's bar watches live (`NotificationsService`, one
subscription per session, unread count as a badge). A client cannot send FCM
to another device, so the push is a Cloud Function (`functions/index.js`)
that mirrors each new inbox item to the recipient's `pushToken`. Tapping the
push opens the inbox, whether the app was running or was launched by the tap.

```bash
cd functions && npm install && cd ..
firebase deploy --only firestore:rules,functions
```

Without the rules deploy every sharing write is denied; without the function
the in-app inbox still works but no push is sent.

A directory entry is written when an account signs in, so a person who has
not opened this build yet cannot be found — that is "לא נמצא חשבון". If not
even the *sender's* own contacts resolve, the directory was never populated
for this account (the rules were not deployed when it signed in) and the app
says so instead: sign out and back in after deploying. Every publish and
lookup logs the hash it used, so a miss can be checked against the
`user_directory` collection in the console. The push text is Hebrew —
the function does not know the recipient's locale.

## Community

Both tabs (shared recipes first, then the forum) and a forum thread pull to
refresh. The refresh event carries a `Completer` rather than deriving its future
from the bloc's state stream: bloc skips emitting a state equal to the current
one, so an unchanged reload would never resolve and the spinner would turn
forever. Empty lists are wrapped in `RefreshableEmptyState` so the gesture is
still reachable when there is nothing to overscroll — which is exactly when a
refresh is wanted.

Two Firestore-backed surfaces behind one **Community** nav tab
(`lib/features/community/`), so the dock keeps a workable number of tabs:

- **Forum** (`lib/features/forum/`) — threads at `forum_posts/{id}` with replies
  in a subcollection. A reply and the thread's `replyCount` are written in one
  batch so the counter cannot drift; deleting a thread sweeps its replies,
  because Firestore does not cascade.
- **Shared recipes** (`lib/features/shared_recipes/`) — a public feed at
  `shared_recipes/{id}`. Each entry stores a *copy* of the recipe, so the author
  editing or deleting their own copy does not change what the feed shows.
  Liking is one document per user (`likes/{uid}`) plus a denormalised counter,
  moved together in a transaction so a double tap stays one like. Saving a feed
  recipe re-keys it and stamps `savedFromSharedId`, so the imported copy is the
  user's own — that field is what splits My Recipes into "mine" and "saved",
  and what the feed's saved filter reads. The feed's whole narrowing and
  ordering decision lives in `SharedFeedQuery` — a pure value class over the
  already-loaded page, so no Firestore composite index is needed per
  combination and the rules are unit-testable. It covers search (title or
  author), scope (all/mine/saved), sort (newest/oldest/most liked), dietary
  topics, a minimum like count (a slider in tens, topping out at an open-ended
  100+), and time — `TimeBucket` rather than a plain maximum, so the top stop
  means "over two hours" instead of "no cap". A checkbox splits time into
  separate prep and cook sliders; whichever side is hidden is ignored, so the
  badge never points at a filter the user cannot see. Every bucket but `any`
  excludes recipes that state no time, since filtering by time is a question
  about recipes that answer it.
  Only the author can edit or unshare their own post.

  A forum reply can carry a pointer to a feed recipe (`sharedRecipeId` plus the
  title captured at the time), rendered as a chip that resolves the live recipe
  on tap — a reply outlives the recipe it links to, so that lookup can come
  back empty.

Both require the rules below; the collections are deny-all without them.

## Grocery list scope

The list aggregates the menus named in `selectedPlanIds` on the stored
`GroceryListEntity`. An **empty list means every menu** — which is also what a
list written before the field existed decodes to, and what a fully-ticked
picker collapses back to, so a menu added later is picked up rather than
silently excluded by a frozen set of ids.

## AI recipe ingestion

Parsing goes through the Gemini Interactions API (`lib/features/recipe_ingestion/`)
in structured-output mode, with the `url_context` and `google_search` server tools
handling link scraping and web search. Without a key, debug builds fall back to
sample data (`lib/dev/fake_recipes.dart`) so the ingestion flow is still walkable.

Get a key from [Google AI Studio](https://aistudio.google.com/apikey) and put it
in `dart_defines/dev.json`, which is gitignored:

```bash
cp dart_defines/dev.example.json dart_defines/dev.json   # dev.json is gitignored
```

```json
{
  "GEMINI_API_KEY": "paste-the-key-here",
  "GEMINI_MODEL": "gemini-3.8-flash"
}
```

Nothing else has to be typed per run. `.vscode/launch.json` and
`.vscode/settings.json` both point at that file, so F5 and the Run button pick
it up; from a terminal it is:

```bash
flutter run --dart-define-from-file=dart_defines/dev.json
```

Leaving `GEMINI_API_KEY` empty is a valid state — debug builds then fall back to
the sample data. `flutter test` is deliberately left without the key so tests
exercise that fallback rather than the network.

**Do not ship a key this way.** A key compiled into a mobile binary is extractable.
For production, stand up a backend that holds the key and point the app at it:

Once that proxy exists, drop `GEMINI_API_KEY` from `dart_defines/dev.json` and
put the proxy there instead — nothing in the app changes:

```json
{ "AI_BASE_URL": "https://your-proxy.example.com" }
```

The proxy must expose `POST /v1beta/interactions` with the same request/response shape.

### Web search: two ways to open a result

Web search runs on the lightest model (`GEMINI_SEARCH_MODEL`, default
`gemini-3.5-flash-lite`): it only returns titles and links, so there is no
reasoning to pay for. Tapping a result no longer commits to the model — a sheet
offers two paths:

- **View the original** fetches the page directly (`WebPageDataSource`) and
  shows its text through `readableTextFromHtml`, a small tag-stripper that keeps
  the main content region and block boundaries. No model, so it loads in the
  time of one HTTP round trip.
- **Create a structured recipe** is the previous behaviour: `url_context`
  extraction into ingredients and steps. It stays one tap away from the original
  view, so reading first does not mean searching again.

### JSON-LD first

Most recipe sites embed a schema.org `Recipe` in `application/ld+json` for
search engines. `parseJsonLdRecipe` (`lib/core/utils/`) lifts it out — title,
ISO-8601 prep/cook durations, ingredient lines, instructions in every shape the
schema allows (a string, a list, `HowToStep`s, `HowToSection`s), and
`suitableForDiet` mapped onto the app's chips. It is used on *both* paths:
"view the original" surfaces it as a one-tap structured import, and "create a
structured recipe" tries it before the model, so a site that publishes its data
imports instantly, with no API key, and with nothing invented. The model is the
fallback, not the default. Ingredient lines are split by
`parseIngredientLine` — a visible heuristic for "2 כוסות קמח" → 2, cup, קמח —
and a line it cannot split keeps its whole text as the name with an unstated
amount, the same "the source did not say" the model reports.

### When the analysis is slow

An analysis is capped at 30 seconds (`IngestionBloc.analysisTimeout`). Past
that, or on any failure, the text it was working from is offered back instead
of an error — the pasted text, or for a link the page text fetched without the
model — with three ways on: try again, edit by hand in the structured editor,
or **save and analyse later**. The last one stores a *template*: a recipe
flagged `pendingAnalysis` whose steps hold the complete original text, one line
each. The details screen shows the flag and an "analyse now" action that runs
the model on that text and replaces the recipe in place, keeping its id, photo
and origin. Structuring it by hand in the editor clears the flag too.

A fifth ingestion channel, **write by hand**, opens the same editor on a blank
recipe — no model, no waiting.

## Editing a recipe

`RecipeEditorPage` edits a recipe in the same structured shape the parser
produces — title, prep/cook time, ingredient rows, steps. It is reached from the
ingestion review screen before saving, and from a saved recipe's details screen.

Saving never waits on the model by itself. The save button opens a sheet:
plain **save** pops immediately, **save with AI review** runs the refine first —
spelling across title, ingredient names and steps, plus re-syncing any duration
written into the steps when a time changed. The spellcheck action in the app
bar runs the same pass in place without leaving the editor. The model only ever
returns free text — amounts, units and the times the user set are merged back in
locally, and a reply with a different number of items is discarded in favour of
what the user typed.

## Testing

```bash
flutter test
```

Coverage is the grocery aggregation engine and its menu filtering, the
page-flip cadence, the recipe editor, the auth gate's redirect rules and stage
machine, and the shared-recipes feed logic. The rest of the UI has been verified by running the app on an iOS
simulator, not by widget tests.

## Not yet implemented

These need infrastructure that does not exist in the project yet:

- **Sharing / real-time collaboration.** The Viewer/Editor model is in the data
  layer (`collaborators` on books and lists) and the settings screen reads it, but
  there is no auth or backend, so invites, deep links, and live sync are absent.
- **Social video Tier 2.** TikTok/Reels ingestion reads title, caption, and page
  text only. Audio transcription and on-screen OCR need a video-processing service.
- **Push notifications** are on-device local notifications scheduled around the
  configured shopping day — not server-driven push.
