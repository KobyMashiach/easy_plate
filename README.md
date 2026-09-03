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

Coverage is the grocery aggregation engine, the page-flip cadence, and the
recipe editor. The rest of the UI has been verified by running the app on an iOS
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
