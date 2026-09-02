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

Parsing goes through the Claude Messages API (`lib/features/recipe_ingestion/`).
Without a key, debug builds fall back to sample data (`lib/dev/fake_recipes.dart`)
so the ingestion flow is still walkable.

```bash
flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-...
```

**Do not ship a key this way.** A key compiled into a mobile binary is extractable.
For production, stand up a backend that holds the key and point the app at it:

```bash
flutter run --dart-define=AI_BASE_URL=https://your-proxy.example.com
```

The proxy must expose `POST /v1/messages` with the same request/response shape.

## Testing

```bash
flutter test
```

Coverage is currently the grocery aggregation engine only. The UI has been
verified by running the app on an iOS simulator, not by widget tests.

## Not yet implemented

These need infrastructure that does not exist in the project yet:

- **Sharing / real-time collaboration.** The Viewer/Editor model is in the data
  layer (`collaborators` on books and lists) and the settings screen reads it, but
  there is no auth or backend, so invites, deep links, and live sync are absent.
- **Social video Tier 2.** TikTok/Reels ingestion reads title, caption, and page
  text only. Audio transcription and on-screen OCR need a video-processing service.
- **Push notifications** are on-device local notifications scheduled around the
  configured shopping day — not server-driven push.
