# Pwi Flutter — Coding Standard & Architecture System Prompt

> Give this document to another AI instance to have it generate code that precisely matches this codebase's conventions.

---

## 1. Project Overview

- **Flutter** + **Dart 3** (SDK `^3.10.0`)
- **Clean Architecture** strictly enforced per feature
- **BLoC** for state management (`flutter_bloc ^9`)
- **Freezed** for immutable models and sealed union types
- **Hive CE** for offline-first local storage
- **Dio** for networking
- **GoRouter** for navigation
- **Slang** for i18n (Hebrew primary locale, RTL)
- **No GetIt** — dependency injection is done via `flutter_bloc`'s `RepositoryProvider` / `BlocProvider` tree, plus a custom `Injector` singleton for services

---

## 2. Folder Structure

```
lib/
├── core/
│   ├── auth/              # Auth tokens, interceptors
│   ├── constants/         # Colors, text styles, enums, asset paths, API URLs
│   ├── di/                # Injector singleton (services only)
│   ├── errors/            # Custom exception classes
│   ├── hive/              # AdaptersController (register all TypeAdapters)
│   ├── logger/            # MemoryLogger, debug log screen
│   ├── main_imports/      # AppDependencies, buildBlocProviders(), buildRepositoryProviders()
│   ├── network/           # HttpCalls (Dio wrapper), AuthInterceptor, ConnectivityService
│   ├── services/          # App-wide services (AppStatusService, etc.)
│   ├── styles/            # Design tokens
│   ├── utils/             # Routing (Routing constants + goRouter), helpers, i18n
│   └── widgets/           # Shared design-system widgets
└── features/
    └── <feature_name>/
        ├── data/
        │   ├── datasources/          # Abstract interface + Impl (local & remote)
        │   ├── models/               # Freezed + Hive + JSON models
        │   └── repositories_impl/    # Concrete repository implementations
        ├── domain/
        │   ├── entities/             # Pure Dart entities (no external deps)
        │   ├── repositories/         # Abstract repository interfaces
        │   └── usecases/             # One class per use case
        └── presentation/
            ├── bloc/                 # XxxEvent, XxxState, XxxBloc — all in one file
            ├── pages/                # Full-screen widgets
            ├── widgets/              # Feature-scoped reusable widgets
            └── modal_bottom_sheet/   # Bottom-sheet widgets (when needed)
```

**Rules:**
- Feature names are `snake_case` (e.g. `fault_details`, `pnr_reports`, `dynamic_form`).
- Never import a feature's internal files from another feature — go through the domain layer.
- `core/` contains only cross-cutting concerns.

---

## 3. BLoC: Events & States

### File layout
All three — event, state, bloc — live in **one file** named `<feature>_bloc.dart`.

### Events

```dart
@freezed
sealed class HomeScreenEvent with _$HomeScreenEvent {
  const factory HomeScreenEvent.init({
    FaultSortOption? keepSort,
    FiltersModel? keepFilters,
  }) = _Init;
  const factory HomeScreenEvent.searchFaults(String value) = _SearchFaults;
  const factory HomeScreenEvent.filterFaults(FiltersModel filters) = _FilterFaults;
  const factory HomeScreenEvent.sortFaults(FaultSortOption sort) = _SortFaults;
}
```

**Rules:**
- Class name: `XxxEvent`
- Mixin: `with _$XxxEvent`
- `sealed class` + `@freezed`
- Each factory constructor name is a **verb phrase** in camelCase (e.g. `init`, `searchFaults`)
- The generated private class name (right of `=`) is `_PascalCase` matching the constructor

### States

```dart
@freezed
sealed class HomeScreenState with _$HomeScreenState {
  const factory HomeScreenState.initial(List<FaultModel> faults, {FiltersModel? filters}) = Initial;
  const factory HomeScreenState.loading(List<FaultModel> faults, {FiltersModel? filters}) = Loading;
  const factory HomeScreenState.loaded(List<FaultModel> faults, {FiltersModel? filters}) = Loaded;
  const factory HomeScreenState.errorMessage(List<FaultModel> faults, String error, {FiltersModel? filters}) = ErrorMessage;
}
```

**Rules:**
- Class name: `XxxState`
- Mixin: `with _$XxxState`
- `sealed class` + `@freezed`
- **Always carry persistent data** (e.g. the current list) through every state variant so the UI never loses it on transition
- Standard state names: `initial`, `loading`, `loaded`, `errorMessage` — add feature-specific variants as needed (e.g. `alertData`, `getResponders`)
- Named parameters that are optional across states use `{}` optional syntax

### Bloc class

```dart
class HomeScreenBloc extends Bloc<HomeScreenEvent, HomeScreenState> {
  // Mutable working copies (not inside state)
  List<FaultModel> faults = [];
  FiltersModel? filters;

  final GetFaultsUseCase getFaultsUseCase;

  HomeScreenBloc({required this.getFaultsUseCase})
      : super(const HomeScreenState.initial([])) {
    on<_Init>(_init);
    on<_SearchFaults>(_searchFaults);
  }

  // Factory constructor resolves deps from BuildContext
  factory HomeScreenBloc.fromContext(BuildContext context) {
    return HomeScreenBloc(
      getFaultsUseCase: GetFaultsUseCase(context.read<FaultsRepository>()),
    );
  }

  FutureOr<void> _init(_Init event, Emitter<HomeScreenState> emit) async {
    emit(HomeScreenState.loading(filteredFaults, filters: filters));
    try {
      faults = await getFaultsUseCase();
      emit(HomeScreenState.loaded(faults, filters: filters));
    } catch (e) {
      debugPrint('Error: $e');
      emit(HomeScreenState.errorMessage(faults, e.toString()));
    }
  }
}
```

**Rules:**
- Handler registration: `on<_PrivateEventClass>(_handlerMethod)` — use the generated private class, not the public sealed class
- Handler signature: `FutureOr<void> _methodName(EventType event, Emitter<State> emit)`
- All use cases are injected via constructor
- Prefer `factory XxxBloc.fromContext(BuildContext context)` as the standard creation path in BlocProvider
- Mutable working data (lists, filters) lives as instance fields on the bloc, not duplicated in every state variant — state variants carry a **snapshot** reference

---

## 4. Data Models

### Pattern: Freezed + Hive + JSON in one class

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';

part 'fault_model.freezed.dart';
part 'fault_model.g.dart';

@freezed
@HiveType(typeId: 104)           // unique integer across entire project
sealed class FaultModel with _$FaultModel {
  static const hiveKey = 'faultModelHive';   // box name constant lives here

  const factory FaultModel({
    @HiveField(0) @JsonKey(name: 'FAILURE_NUM') required String failureNum,
    @HiveField(1) @JsonKey(name: 'FAILURE_STATUS', defaultValue: 1) required int failureStatus,
    @HiveField(2) @JsonKey(name: 'CUSTOMER_NAME') String? customerName,
  }) = _FaultModel;

  factory FaultModel.fromJson(Map<String, dynamic> json) => _$FaultModelFromJson(json);
}
```

**Rules:**
- `@freezed` + `@HiveType(typeId: N)` on the same class — keep typeId values globally unique
- `@HiveField(N)` index order must match declaration order and must never be reordered
- `@JsonKey(name: 'SCREAMING_SNAKE_CASE')` for all fields that map to an API JSON key
- `sealed class` keyword always accompanies `@freezed` classes in Dart 3
- `static const hiveKey` on every model for the box name
- Generated parts: `part 'model.freezed.dart'` and `part 'model.g.dart'`
- `fromJson` factory always provided

### Models that are NOT persisted in Hive
Omit `@HiveType` / `@HiveField` — use only `@freezed` + `json_serializable`.

---

## 5. Hive Initialization & Adapter Registration

### AdaptersController (`lib/core/hive/adapters_controller.dart`)

```dart
class AdaptersController {
  static Future<void> registerAdapters() async {
    await registerModel(FaultModelAdapter(), boxName: FaultModel.hiveKey);
    await registerModel(UserModelAdapter(), boxName: UserModel.hiveKey);
    // one line per model
  }

  static Future<void> registerModel<T>(
    TypeAdapter<T> adapter, {
    String? boxName,
  }) async {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
    if (boxName != null && !Hive.isBoxOpen(boxName)) {
      await Hive.openBox<T>(boxName);
    }
  }
}
```

**Rules:**
- `hive_ce` and `hive_ce_flutter` (not the original `hive` package)
- Adapters generated by `hive_ce_generator`
- Always check `isAdapterRegistered` before registering
- Always check `isBoxOpen` before opening
- `Hive.initFlutter()` is called in `main()` before `AdaptersController.registerAdapters()`

### Local Data Sources using Hive

```dart
abstract class FaultsLocalDataSource {
  Future<List<FaultModel>> getFaults();
  Future<void> saveFaults(List<FaultModel> faults);
  Future<void> saveFault(FaultModel fault);
  Future<void> clearFaults();
}

class FaultsLocalDataSourceImpl implements FaultsLocalDataSource {
  static const boxName = 'faultsBox';

  @override
  Future<List<FaultModel>> getFaults() async {
    final box = await Hive.openBox<FaultModel>(boxName);
    return box.values.toList();
  }

  @override
  Future<void> saveFaults(List<FaultModel> faults) async {
    final box = await Hive.openBox<FaultModel>(boxName);
    await box.clear();
    await box.putAll({for (final f in faults) f.failureNum: f});
  }
}
```

**Rules:**
- Always `abstract class + Impl` pair for every data source
- Open box lazily in each method with `Hive.openBox<T>(name)` — the call is safe if already open
- Use the model's own unique field as the box key (e.g. `f.failureNum`)

---

## 6. Domain Layer

### Repository interface

```dart
abstract class FaultsRepository {
  Future<List<FaultModel>> getFaults([int? areaCode, bool justLocal]);
  Future<void> updateFaultStatus({required FaultModel fault, required int statusNum});
  Future<List<HistoryFaultModel>> getHistoryFaults(FaultModel fault);
}
```

**Rules:**
- Interface only — no implementation detail
- Lives in `domain/repositories/`
- Filename: `<name>_repository.dart`

### Use cases

```dart
class GetFaultsUseCase {
  final FaultsRepository repository;
  GetFaultsUseCase(this.repository);

  Future<List<FaultModel>> call({int? areaCode, bool justLocal = false}) {
    return repository.getFaults(areaCode, justLocal);
  }
}
```

**Rules:**
- One class per use case
- Always implement `call()` so the use case can be invoked as a function: `await getFaultsUseCase()`
- No failure/Either type — throw exceptions directly; the bloc catches them
- Filename: `<verb>_<noun>_usecase.dart`

### Entities

```dart
class FaultEntity {
  final String failureNum;
  final int failureStatus;
  final String? customerName;

  const FaultEntity({
    required this.failureNum,
    required this.failureStatus,
    this.customerName,
  });
}
```

**Rules:**
- Pure Dart — no package imports (no Freezed, no Hive)
- `const` constructor
- All fields `final`

---

## 7. Repository Implementation

```dart
class FaultsRepositoryImpl implements FaultsRepository {
  final FaultsLocalDataSource localDataSource;
  final OutboxRepository outboxRepo;

  FaultsRepositoryImpl({
    required this.localDataSource,
    required this.outboxRepo,
  });

  bool get _isOnline => AppStatusService().isConnected.value;

  @override
  Future<List<FaultModel>> getFaults([int? areaCode, bool justLocal = false]) async {
    if (!ConnectivityService().hasConnection || justLocal) {
      return localDataSource.getFaults();
    }

    final response = await HttpCalls().post(getAllFaultsUrl, withSessionIdParams: true);
    if (response?.data == null) throw Exception('No data received');

    final faults = (response!.data['FAULTS'] as List)
        .map((j) => FaultModel.fromJson(j as Map<String, dynamic>))
        .toList();

    await localDataSource.saveFaults(faults);
    return faults;
  }
}
```

**Rules:**
- Implements the domain interface
- Receives data sources via constructor injection
- Offline-first: check connectivity before hitting network
- `kDebugMode` guard returns fake data in debug builds
- Throws raw exceptions — no Result/Either wrapper

---

## 8. Dependency Injection

Injection is split into two mechanisms:

### A. flutter_bloc RepositoryProvider tree (feature dependencies)

`lib/core/main_imports/repository_providers.dart`:

```dart
List<SingleChildWidget> buildRepositoryProviders(AppDependencies deps) {
  return [
    RepositoryProvider<FaultsLocalDataSource>(
      create: (_) => FaultsLocalDataSourceImpl(),
    ),
    RepositoryProvider<FaultsRepository>(
      create: (context) => FaultsRepositoryImpl(
        localDataSource: context.read<FaultsLocalDataSource>(),
        outboxRepo: deps.outboxRepo,
      ),
    ),
    RepositoryProvider<GetFaultsUseCase>(
      create: (context) => GetFaultsUseCase(context.read<FaultsRepository>()),
    ),
  ];
}
```

`lib/core/main_imports/bloc_providers.dart`:

```dart
List<SingleChildWidget> buildBlocProviders(AppDependencies deps) {
  return [
    BlocProvider(
      create: (context) => HomeScreenBloc.fromContext(context),
    ),
    BlocProvider(
      create: (_) => LoginBloc(
        signInUseCase: SignInUseCase(deps.loginRepository),
      )..add(const LoginEvent.initial()),
    ),
  ];
}
```

**Rules:**
- Lower-level providers are declared before the ones that depend on them (order matters)
- Use `context.read<T>()` inside `create:` to resolve already-registered providers
- Prefer `XxxBloc.fromContext(context)` factory when the bloc resolves all its use cases from the context
- Use `deps.xxx` for dependencies wired in `AppDependencies` (Hive-backed services, etc.)

### B. Injector singleton (services & long-lived objects)

`lib/core/di/injector.dart`:

```dart
class Injector {
  static final Injector _instance = Injector._internal();
  factory Injector() => _instance;
  Injector._internal();

  bool _initialized = false;
  late OutboxRepository outboxRepo;
  late SyncBloc syncBloc;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    final box = await Hive.openBox<OfflineRequestModel>('outbox_box');
    outboxRepo = OutboxRepositoryImpl(OutboxLocalDataSourceHive(box));
    syncBloc = SyncBloc(processOutbox: processOutbox);
  }
}
```

**Rules:**
- Singleton via `factory` constructor returning `_instance`
- Guards re-initialization with `_initialized` flag
- Used only for services that must outlive the widget tree (connectivity, sync, media tracker)

---

## 9. Networking

### HttpCalls (Dio wrapper)

```dart
class HttpCalls {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: iecPrefix,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 60),
    headers: {'Content-Type': 'application/json'},
  ));

  HttpCalls({bool media = false, bool saveLocally = false});

  Future<Response?> get(String path, {Map<String, dynamic>? queryParameters, bool withSessionIdParams = false}) =>
      _request('GET', path, null, queryParameters, withSessionIdParams: withSessionIdParams);

  Future<Response?> post(String path, {dynamic data, bool withSessionIdParams = false}) =>
      _request('POST', path, data, null, withSessionIdParams: withSessionIdParams);
}
```

**Rules:**
- Always use `HttpCalls` — never instantiate `Dio` directly in a repository
- Named constructors for special token contexts: `HttpCalls.withTokens(...)`
- Auth handled by `AuthInterceptor` added in the constructor
- Returns `Response?` (nullable) — callers must null-check

---

## 10. Error Handling

### Exception pattern

```dart
class AppException implements Exception {
  final AppErrorType type;
  final String message;

  const AppException(this.type, {this.message = ''});

  @override
  String toString() => 'AppException($type): $message';
}

enum AppErrorType { cancelled, networkError, unauthorized, unknown }
```

**Rules:**
- Custom exceptions implement `Exception`, not `Error`
- Enum-based error types — no string codes
- No `Either` / `Result` / `Failure` wrapper — exceptions propagate up and are caught in the bloc
- Blocs catch all exceptions with `catch (e)`, emit `errorMessage` state, and `debugPrint` the error

---

## 11. Routing

```dart
class Routing {
  static const splash = '/';
  static const home = '/home';
  static const faultsDetails = 'faults_details'; // relative child route
}

List<RouteBase> appRoutes(UserModel? user, String initialRoute) => [
  GoRoute(
    path: Routing.home,
    name: Routing.home,
    builder: (context, state) => const MainNavBar(),
    routes: [
      GoRoute(
        path: Routing.faultsDetails,
        name: Routing.faultsDetails,
        builder: (context, state) => FaultsDetailsPage(
          fault: state.extra as FaultModel,
        ),
      ),
    ],
  ),
];
```

**Rules:**
- All route path strings are `static const` on `Routing`
- Root routes start with `/`, child routes are relative (no leading `/`)
- Extras passed via `state.extra` cast to the expected type
- Navigation always uses `context.pushNamed(Routing.xxx, extra: payload)`

---

## 12. Dart 3 Features & Style

### Sealed classes with pattern matching

```dart
// In a BlocBuilder:
return switch (state) {
  Initial(faults: final faults) => FaultListWidget(faults: faults),
  Loading() => const CircularProgressIndicator(),
  Loaded(faults: final faults) => FaultListWidget(faults: faults),
  ErrorMessage(error: final msg) => ErrorWidget(msg),
  _ => const SizedBox.shrink(),
};
```

### Records

```dart
// GoRouter path + extra as a record
if (config case (String path, {Map<String, dynamic>? extra})) {
  context.pushNamed(path, extra: extra);
}
```

### Switch statement on enums

```dart
switch (sort) {
  case FaultSortOption.newest:
    list.sort((a, b) => b.orderBy!.compareTo(a.orderBy!));
  case FaultSortOption.oldest:
    list.sort((a, b) => a.orderBy!.compareTo(b.orderBy!));
}
```

### Dot shorthands (Dart 3.7+)

Use dot shorthands for named constructors / enum values when the type is unambiguous from context:

```dart
// State emission — type is inferred from Emitter<HomeScreenState>
emit(.loading(faults));
emit(.loaded(faults));
emit(.errorMessage(faults, e.toString()));

// Event dispatch — type inferred from Bloc<HomeScreenEvent, ...>
add(.init());

// Enum — type inferred from parameter
bloc.add(.sortFaults(.newest));
```

**Rules:**
- Use dot shorthands wherever the static type is already known from context
- Never use dot shorthands when the type must be inferred at a call site that receives `dynamic` or `Object`

### General style

- `const` constructors wherever possible
- `required` named parameters for all non-nullable constructor args
- `final` fields everywhere; avoid `var` in class bodies
- `debugPrint()` not `print()`
- Trailing commas on all multi-line argument lists (formatter: `trailing_commas: preserve`)
- No unnecessary comments — only for non-obvious invariants

---

## 13. Analysis Options

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables

formatter:
  trailing_commas: preserve

analyzer:
  errors:
    invalid_annotation_target: ignore
    depend_on_referenced_packages: ignore
```

---

## 14. Code Generation

Run after any model/bloc/i18n change:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Generated file suffixes:
- `.freezed.dart` — Freezed union/copyWith
- `.g.dart` — json_serializable + hive_ce_generator
- `strings.g.dart` / `strings_he.g.dart` — Slang i18n

---

## 15. Localization (Slang)

```dart
// Import — replace <app_package> with the name from pubspec.yaml
import 'package:<app_package>/core/utils/i18n/strings.g.dart';

// Usage — top-level `t` accessor
Text(t.home.title)
Text(t.error.no_connection)
```

**Rules:**
- The package name (`<app_package>`) is the `name:` field in `pubspec.yaml` — always derive it from there, never hardcode a specific value
- Translation strings live in `lib/core/utils/i18n/`
- Always use `t.xxx` — never hardcode Hebrew strings in widget code
- App locale is always `he_IL`; `Locale('he', 'IL')` passed to `MaterialApp`

---

## 16. Debug / Fake Data Pattern

```dart
if (kDebugMode) {
  faults = fakeFaultsList;
} else {
  final response = await HttpCalls().post(url);
  faults = (response!.data['FAULTS'] as List).map(...).toList();
}
```

- Fake data lives in `lib/dev/` or alongside the feature as `fake_<model>s.dart`
- Always guarded with `kDebugMode` — never reaches production

---

## 17. App Initialization Order (`main.dart`)

```
1. WidgetsFlutterBinding.ensureInitialized()
2. MemoryLogger.init()
3. Firebase.initializeApp()
4. ConnectivityService().initialize()
5. loadUrls()                          // remote config / URL resolution
6. SystemChrome.setPreferredOrientations()
7. initHive()                          // Hive.initFlutter() + AdaptersController.registerAdapters()
8. AppDependencies.create()            // create Hive-backed repos, use cases
9. Injector().init()                   // wire long-lived services
10. runApp(TranslationProvider → MultiRepositoryProvider → MultiBlocProvider → MyApp))
```

---

## Quick Reference: Naming Conventions

| Artifact | Convention | Example |
|---|---|---|
| Feature folder | `snake_case` | `fault_details/` |
| BLoC file | `<feature>_bloc.dart` | `home_screen_bloc.dart` |
| Event class | `XxxEvent` sealed | `HomeScreenEvent` |
| Event factory | camelCase verb | `.init()`, `.searchFaults()` |
| State class | `XxxState` sealed | `HomeScreenState` |
| State variant | PascalCase noun | `Initial`, `Loading`, `Loaded`, `ErrorMessage` |
| Repository interface | `XxxRepository` abstract | `FaultsRepository` |
| Repository impl | `XxxRepositoryImpl` | `FaultsRepositoryImpl` |
| Data source interface | `XxxLocalDataSource` | `FaultsLocalDataSource` |
| Data source impl | `XxxLocalDataSourceImpl` | `FaultsLocalDataSourceImpl` |
| Use case | `VerbNounUseCase` | `GetFaultsUseCase` |
| Model | `XxxModel` | `FaultModel` |
| Entity | `XxxEntity` | `FaultEntity` |
| Hive box name | stored as `static const hiveKey` on the model | `FaultModel.hiveKey` |


## Stitch Design System
- Default Stitch Project ID: 7084543715612353080
- When implementing UI, always fetch the corresponding design and tokens from this Stitch project.