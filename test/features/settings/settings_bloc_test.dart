import 'dart:async';

import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/grocery_list/domain/entities/grocery_list_entity.dart';
import 'package:easy_plate/features/grocery_list/domain/repositories/grocery_lists_repository.dart';
import 'package:easy_plate/features/recipe_books/domain/entities/recipe_book_entity.dart';
import 'package:easy_plate/features/recipe_books/domain/repositories/recipe_books_repository.dart';
import 'package:easy_plate/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:easy_plate/features/user_profile/domain/entities/user_preferences_entity.dart';
import 'package:easy_plate/features/user_profile/domain/repositories/user_preferences_repository.dart';
import 'package:easy_plate/features/user_profile/domain/usecases/get_user_preferences_usecase.dart';
import 'package:easy_plate/features/user_profile/domain/usecases/save_user_preferences_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePreferences implements UserPreferencesRepository {
  UserPreferencesEntity stored = const UserPreferencesEntity(
    shoppingDay: ShoppingDay.sunday,
    dietaryPreferences: [],
  );
  final saved = <UserPreferencesEntity>[];

  /// Set, the next save waits on it — Firestore taking its time.
  Completer<void>? saveGate;
  bool refuse = false;

  @override
  Future<UserPreferencesEntity> getPreferences() async => stored;

  @override
  Future<void> savePreferences(UserPreferencesEntity preferences) async {
    if (saveGate case final gate?) {
      saveGate = null;
      await gate.future;
    }
    if (refuse) throw Exception('offline');
    saved.add(preferences);
    stored = preferences;
  }
}

class _FakeBooks implements RecipeBooksRepository {
  @override
  Future<List<RecipeBookEntity>> getBooks() async => const [];
  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeLists implements GroceryListsRepository {
  @override
  Future<List<GroceryListEntity>> getLists() async => const [];
  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Two books and a list, one of each on a collab doc.
class _SomeShared implements RecipeBooksRepository, GroceryListsRepository {
  static final _at = DateTime(2026);
  @override
  Future<List<RecipeBookEntity>> getBooks() async => [
    RecipeBookEntity(
      id: 'b1',
      title: 'a',
      recipeRefs: const [],
      createdAt: _at,
      collabId: 'c1',
    ),
    RecipeBookEntity(
      id: 'b2',
      title: 'b',
      recipeRefs: const [],
      createdAt: _at,
    ),
  ];
  @override
  Future<List<GroceryListEntity>> getLists() async => [
    GroceryListEntity(
      id: 'l1',
      name: 'a',
      items: const [],
      createdAt: _at,
      collabId: 'c2',
    ),
  ];
  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _BrokenBooks implements RecipeBooksRepository {
  @override
  Future<List<RecipeBookEntity>> getBooks() async =>
      throw StateError('box closed');
  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  late _FakePreferences preferences;

  SettingsBloc buildBloc() => SettingsBloc(
    getUserPreferencesUseCase: GetUserPreferencesUseCase(preferences),
    saveUserPreferencesUseCase: SaveUserPreferencesUseCase(preferences),
    recipeBooksRepository: _FakeBooks(),
    groceryListsRepository: _FakeLists(),
  );

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 5));

  setUp(() => preferences = _FakePreferences());

  test(
    'two switches flipped while a save is still out both reach the record',
    () async {
      final bloc = buildBloc();
      await settle();
      final gate = preferences.saveGate = Completer<void>();

      bloc.add(const SettingsEvent.toggleSoundEffects(false));
      bloc.add(const SettingsEvent.toggleFastPageTurn(false));
      await settle();
      // The first save is held; the second has not even read the record.
      expect(preferences.saved, isEmpty);

      gate.complete();
      await settle();

      expect(preferences.saved, hasLength(2));
      expect(preferences.stored.soundEffectsEnabled, isFalse);
      expect(preferences.stored.fastPageTurnEnabled, isFalse);
      final state = bloc.state as SettingsLoaded;
      expect(state.preferences.soundEffectsEnabled, isFalse);
      expect(state.preferences.fastPageTurnEnabled, isFalse);
    },
  );

  test(
    'a dietary chip toggles on the record as stored, not on a stale copy',
    () async {
      final bloc = buildBloc();
      await settle();
      // Saved through another path (the assistant) after this bloc loaded.
      preferences.stored = preferences.stored.copyWith(
        dietaryPreferences: [DietaryPreference.values.first],
      );

      bloc.add(
        SettingsEvent.toggleDietaryPreference(DietaryPreference.values[1]),
      );
      await settle();

      expect(preferences.stored.dietaryPreferences, [
        DietaryPreference.values.first,
        DietaryPreference.values[1],
      ]);
    },
  );

  test('a failed shared-count read still loads the settings', () async {
    final bloc = SettingsBloc(
      getUserPreferencesUseCase: GetUserPreferencesUseCase(preferences),
      saveUserPreferencesUseCase: SaveUserPreferencesUseCase(preferences),
      recipeBooksRepository: _BrokenBooks(),
      groceryListsRepository: _FakeLists(),
    );
    await settle();
    expect(bloc.state, isA<SettingsLoaded>());
    expect((bloc.state as SettingsLoaded).sharedBooksCount, 0);
    await bloc.close();
  });

  test('shared counts follow the collab doc, not the legacy field', () async {
    final shared = _SomeShared();
    final bloc = SettingsBloc(
      getUserPreferencesUseCase: GetUserPreferencesUseCase(preferences),
      saveUserPreferencesUseCase: SaveUserPreferencesUseCase(preferences),
      recipeBooksRepository: shared,
      groceryListsRepository: shared,
    );
    await settle();
    final state = bloc.state as SettingsLoaded;
    expect(state.sharedBooksCount, 1);
    expect(state.sharedListsCount, 1);
    await bloc.close();
  });

  test('a refused save puts the switch back', () async {
    final bloc = buildBloc();
    await settle();
    preferences.refuse = true;

    bloc.add(const SettingsEvent.toggleSoundEffects(false));
    await settle();

    expect(preferences.saved, isEmpty);
    expect(
      (bloc.state as SettingsLoaded).preferences.soundEffectsEnabled,
      isTrue,
    );
    // …and says so: the screens listen for this.
    expect((bloc.state as SettingsLoaded).saveFailures, 1);
  });

  test('a language switch reports whether the record took it', () async {
    final bloc = buildBloc();
    await settle();

    preferences.refuse = true;
    final refused = Completer<bool>();
    bloc.add(SettingsEvent.changeLanguage(AppLanguage.english, saved: refused));
    expect(await refused.future, isFalse);

    preferences.refuse = false;
    final taken = Completer<bool>();
    bloc.add(SettingsEvent.changeLanguage(AppLanguage.english, saved: taken));
    expect(await taken.future, isTrue);
    await bloc.close();
  });
}
