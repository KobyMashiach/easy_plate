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
`AuthSessionService`, which moves the user through `signedOut → needsPhone →
needsEmailVerification → needsProfile → needsOnboarding → ready`. Three
providers are wired: Phone (SMS), Google, and Email/Password.

**A verified phone is the root identity of every account.** Only the phone flow
opens one: the login screen offers Google, Apple and email as ways back into an
account that already linked them, never as a way to sign up. `registerWithEmail`
still exists on the repository but nothing calls it.

Sign in with Apple is **iOS only** — `appleSignInAvailable` gates both the login
button and the profile's identity row. Apple's guideline 4.8 only binds iOS, and
on Android the button would be a browser round trip solving a problem that does
not exist there. It uses `firebase_auth`'s own `signInWithProvider(AppleAuthProvider())`
rather than a separate package, which drives ASAuthorization natively, so Hide My
Email works and there is no dependency to keep current.

Apple hands back the user's name **only on the very first authorization** for an
app; a reinstall gets nothing. That is why the profile screen asks for a name
rather than trusting whatever the provider supplied.

`ios/Runner/Runner.entitlements` is new and carries `com.apple.developer.applesignin`.
It is wired to all three build configurations. Two things live outside this repo:
enable Apple as a provider in the Firebase console, and enable Sign In with Apple
on the App ID in the Apple Developer portal. The console asks for the redirect
`https://easy-plate.firebaseapp.com/__/auth/handler` — that URL is only used by
the web/Android flow, so it does not affect the native iOS path, but the console
still wants it configured.

**The entitlements file does not yet carry `aps-environment`.** Push is still
broken on iOS for that reason; adding it also requires the capability on the App
ID, so it is deliberately a separate step.

The rule is enforced at the gate rather than at the button, which is what makes
it hold. `AppUserEntity.needsPhoneVerification` is simply the absence of the
`phone` provider, and Firebase only adds that provider once an SMS code has been
accepted — so there is no unverified state to reason about. An account that
arrives by Google, or one created before the rule existed, lands on
`PhoneGatePage` and cannot go anywhere else until it proves a number. That screen
*links* rather than signs in, so whatever brought the user there is preserved.

The check runs before the local Hive scope is switched and before the profile is
read, so an account that has not proved a number never opens a per-user box.

Linking Google or an email afterwards stays optional, from the profile screen.
`needsEmailVerification` applies only to accounts with a `password` provider:
Google arrives verified and a phone account has no address to prove — so linking
an email later does raise it.

**Every registration now costs an SMS**, and phone auth is a known target for
SMS-pumping fraud. Restrict the allowed regions in the Firebase console, and
treat App Check as a prerequisite rather than a nice-to-have.

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
  closing at sign-out races the screens still being torn down. `UserScope` keeps
  a reference to every box it opened, because Hive only hands a box back at the
  type it was opened with: closing one by asking for `Box<dynamic>` threw
  *"already open and of type Box<UserPreferencesModel>"*, which aborted the
  sign-in mid-transition and stranded the user on the OTP screen. Holding the
  reference sidesteps the type question and makes concurrent switches safe.
- **Local data written before this existed stays in the old unscoped boxes and
  will not appear.** There is no migration.

The recipe list is driven by `watchRecipes()` off the box itself, so a recipe
saved from ingestion, the editor, or the community shows up without the list
having to notice it was navigated back to.

### The cloud mirror

A box is a file in the app's container: it dies with an uninstall and never
existed on a second device. Scoping alone therefore gave the right answer on one
phone and an empty app on the next — a returning account found no recipes, no
library, and was sent back through onboarding to pick a shopping day it had
already chosen.

So every scoped box is mirrored into the account's own Firestore subtree
(`lib/core/sync/`):

| Box | Document path |
| --- | --- |
| `userPreferencesBox` | `users/{uid}/preferences/current` |
| `recipesBox` | `users/{uid}/recipes/{id}` |
| `recipeBooksBox` | `users/{uid}/books/{id}` |
| `mealPlansBox` | `users/{uid}/meal_plans/{id}` |
| `groceryListsBox` | `users/{uid}/grocery_lists/{id}` |

`UserCloudCollection<T>` is one generic mirror per box; `CloudSyncService` holds
the five instances and is the singleton both the repositories and the auth gate
talk to. The repository writes local first and then pushes, deliberately
*without* awaiting: offline, Firestore applies the write to its own queue at
once but does not complete the future until a server acknowledges it, so
awaiting would hang saving a recipe until the network came back.

`AuthSessionService` hydrates on sign-in, after `UserScope.switchTo` and before
preferences are read — the stage the gate picks depends on `onboardingComplete`,
which is one of the things being restored. It is skipped for an account already
hydrated this session, and capped at 12 seconds so a hanging network costs a
pause rather than the app.

The merge is cloud-wins, then push-back: remote documents overwrite the box, and
anything the box holds that the cloud has never seen goes up. The push-back half
is what carries an account whose data predates the mirror, and anything saved
while the network was down. Two consequences to know:

- **There are no tombstones.** A record deleted on another device while this one
  was offline is restored rather than removed. Deletes propagate immediately
  when online, which is the case that matters.
- Photos travel separately — see [Photos](#photos) below. The mirror carries
  only fields; a picture is a file.

Rules-wise the subtree is owner-only, and it needs a rule of its own: Firestore
rules do not cascade into subcollections, so `match /users/{uid}` alone would not
have reached any of it.

### Photos

An entity carries a photo's *file name*, and that name means something only
inside this device's image directory. So the picture went nowhere: not to a
second device, not to the account a recipe was shared with, not to the community
feed. Three bug reports, one missing piece.

`RecipeImageStore` (`lib/core/sync/`) is that piece. On save the file is
uploaded to `recipe_images/{uid}/{fileName}` and the recipe records the
**Storage path** — not a download URL. A download URL carries an access token
that makes the object readable by anyone holding the link whatever the rules
say; a path is resolved through the SDK, so `storage.rules` actually decides.

`ClayImage` takes that path as `remotePath`. When the file is not on this
device it is fetched **once**, into the same local directory under the same file
name, and read off the disk on every build after that — so a shared or restored
recipe costs one download, not one per rebuild, and works offline afterwards.
Concurrent asks for the same photo share one download.

The paths that publish a recipe to someone else — sharing, accepting an invite,
editing a shared recipe, posting to the community, updating a post — go through
`RecipesRepository.readyForSharing`, which **awaits** the upload. A plain save
deliberately does not: uploading in the background keeps the editor from waiting
on a picture, and a failed upload leaves `imageStoragePath` null so the next save
retries. Sharing cannot afford that, because a recipe published seconds after
its photo was picked would be sent with no path at all, and the copy the other
side keeps would stay blank for good.

Two rules that are easy to get wrong, both pinned in
`test/core/sync/recipe_photo_travel_test.dart`:

- **A new photo clears `imageStoragePath`.** `copyWith` does this whenever the
  file name changes. Keeping the old path would leave every other copy of the
  recipe showing the picture that was just replaced.
- **A saved community recipe keeps the *author's* path**, rather than
  re-uploading the same bytes once per saver. So deleting that copy must not
  delete the object — `RecipeImageStore.ownsPath` is the guard, and it is why
  deletion is namespaced by uid at all.

Nested models are written as plain maps because `build.yaml` sets
`explicit_to_json: true` for `json_serializable`. Without it the generated
`toJson` hands nested freezed objects over untouched — fine for `jsonEncode`,
rejected by Firestore, which takes only primitives, lists and maps.
`test/core/sync/cloud_round_trip_test.dart` pins both halves: that every model
survives `fromJson(toJson(x))`, and that the encoded map contains nothing
Firestore cannot store.

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

**Do not ship a key this way.** A key compiled into a mobile binary is extractable
with `strings`, however it got there. `dart_defines/dev.json` is a development
answer only.

### The production path: the AI proxy

`functions/aiProxy.js` is a Cloud Function that holds the key and stands between
the app and Google. It exposes the same `POST /v1beta/interactions` with the same
request and response shape, so the ingestion pipeline is unchanged — only the base
URL and the credential differ.

`ApiConfig.aiBaseUrl` is the only switch. Left at Google's own endpoint the app
authenticates with `x-goog-api-key` from the dart-define; pointed anywhere else it
sends the signed-in user's Firebase ID token as a bearer token instead, and needs
no key at all. `ApiConfig.isConfigured` is true in both states, which is why a
proxied build has a working AI feature with nothing secret inside it.

The function does three things the app cannot do for itself: it keeps the key out
of the binary, it refuses any path but the one the app calls, and it enforces a
per-user daily quota. That last one is not decoration — an authenticated user can
still burn the budget in a loop, and only the server can say no. The limit lives in
`FREE_DAILY_CALLS`, and `dailyLimitForUser` is the single place that becomes an
entitlement lookup once subscriptions exist.

Usage counts live at `ai_usage/{uid}`, written only by the Admin SDK. The rules'
closing deny-all already makes that collection unreachable from any client.

Deploying it, once per machine:

```bash
npm install -g firebase-tools
firebase login
firebase use --add                                   # writes .firebaserc
cd functions && npm install && cd ..
firebase functions:secrets:set GEMINI_API_KEY        # prompts for the value
firebase deploy --only functions
```

The deploy prints the function URL. Put it in `dart_defines/dev.json` and drop the
key:

```json
{ "AI_BASE_URL": "https://europe-west1-easy-plate.cloudfunctions.net/aiProxy" }
```

Rotating the key later is `firebase functions:secrets:set GEMINI_API_KEY` followed
by a redeploy. No app release is involved, because no build ever contained it.

`cd functions && npm test` covers the quota decision: the day rollover, the call
that reaches the limit, and the one past it.

**Still missing:** App Check. Until it is enabled, the proxy trusts any valid
Firebase ID token, which means any account — including one created by a script.
The quota bounds the damage per account; App Check is what stops the accounts
being created by something other than the app.

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

An analysis is capped at 45 seconds (`IngestionBloc.analysisTimeout`). Past
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

What the budget is spent on, and what was done about each:

- **The model thinking.** Gemini 3 reasons before answering by default, and on an
  extraction that was most of the wait for nothing — the job is transcription
  against a fixed schema, not a problem to solve. `ApiConfig.thinkingLevel` sends
  `generation_config.thinking_level`, `low` for extraction and refine and
  `minimal` for search. `low` is the floor for `gemini-3.8-flash`; `minimal` is
  only accepted by the lite tier, and sending it to a model that does not take it
  is a 400. Override with `GEMINI_THINKING_LEVEL` / `GEMINI_SEARCH_THINKING_LEVEL`,
  or set either to empty to send no level at all.
- **Cold starts.** The proxy sat idle between calls, so a Node boot and a secret
  mount were charged to the one request the user was watching. `minInstances: 1`
  keeps an instance warm; it is billed as idle time, and setting it back to `0`
  is the way to stop that charge.
- **Distance.** The proxy runs in `europe-west1` rather than `us-central1`, so a
  call from an Israeli phone no longer crosses the Atlantic twice. Only the HTTP
  proxy moved — `pushOnNotification` is a Firestore trigger and stays in the
  database's region.
- **Retries.** A capacity error is retried twice, now at 0.6s and 1.2s rather
  than 2s and 4s: the retry runs inside the same 45-second budget, and one that
  lands after the deadline is the same as no retry at all. A *spent daily quota*
  is no longer retried at all — it arrives as a 429 like a capacity error, but
  `HttpCalls.errorTypeFor` reads the proxy's `quota` object and types it
  `AppErrorType.quotaExceeded`, because waiting cannot change the answer until
  the quota resets.

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

## Releasing to Google Play

Play rejects anything signed with the debug key, so `android/app/build.gradle.kts`
reads `android/key.properties` and signs `release` with it. Both that file and
`*.jks` are excluded by `android/.gitignore` — nothing about the key is in this
repo, and a machine without it can still build debug. A **release** build with no
credentials fails with a message rather than quietly producing an unusable
artefact.

```bash
flutter build appbundle --release --dart-define-from-file=dart_defines/dev.json
```

The store wants the App Bundle, not an APK. `debugSymbolLevel = "SYMBOL_TABLE"`
ships native symbols so Crashlytics can symbolicate; `FULL` also works but tripled
the bundle, because it carries complete DWARF debug info for the whole engine.

To check what actually signed a bundle:

```bash
unzip -p build/app/outputs/bundle/release/app-release.aab META-INF/UPLOAD.RSA | keytool -printcert
```

`CN=Android Debug` there is the rejection above; the upload key is anything else.

### The SHA-1 trap

`google-services.json` carries **one** certificate hash, and until the release key
was added it was the debug one. Google Sign-In matches on that hash, so a store
build fails with `ApiException: 10` for every user while everything else keeps
working — a failure that never appears in development.

Three fingerprints have to be registered in Firebase → Project settings → your
Android app, after which `google-services.json` must be re-downloaded:

1. the debug key, so development keeps working,
2. the **upload** key (`keytool -printcert` above),
3. the **app signing** key, which Play generates and shows under Release →
   Setup → App signing only *after* the first upload.

Missing the third is the usual reason sign-in works in internal testing and
breaks in production.

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
