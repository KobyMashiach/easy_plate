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
`AuthSessionService`, which moves the user through `signedOut → needsProfile →
needsOnboarding → ready`. Three providers are wired: Email/Password, Phone
(SMS), and Google. Sign-out lives in Settings.

New accounts land on `ProfileSetupPage` (full name, photo, phone, email) before
onboarding. The profile is a Firestore document at `users/{uid}`; the photo goes
to Storage at `profile_photos/{uid}.jpg`. Local `UserPreferencesEntity` stays on
the device and is unrelated.

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

## Community

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
  recipe re-keys it, so the imported copy is the user's own.

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

## Editing a recipe

`RecipeEditorPage` edits a recipe in the same structured shape the parser
produces — title, prep/cook time, ingredient rows, steps. It is reached from the
ingestion review screen before saving, and from a saved recipe's details screen.

Two corrections run through the model. The spellcheck action fixes typos across
the title, ingredient names and steps; changing a time re-runs it on save so any
duration written into the steps agrees with the new time. The model only ever
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
