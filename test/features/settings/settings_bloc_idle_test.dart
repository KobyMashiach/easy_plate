import 'dart:async';

import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/grocery_list/domain/repositories/grocery_lists_repository.dart';
import 'package:easy_plate/features/recipe_books/domain/repositories/recipe_books_repository.dart';
import 'package:easy_plate/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:easy_plate/features/user_profile/domain/entities/user_preferences_entity.dart';
import 'package:easy_plate/features/user_profile/domain/repositories/user_preferences_repository.dart';
import 'package:easy_plate/features/user_profile/domain/usecases/get_user_preferences_usecase.dart';
import 'package:easy_plate/features/user_profile/domain/usecases/save_user_preferences_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _SlowPreferences implements UserPreferencesRepository {
  UserPreferencesEntity stored = const UserPreferencesEntity(
    shoppingDay: ShoppingDay.sunday,
    dietaryPreferences: [],
  );
  Completer<void>? gate;

  @override
  Future<UserPreferencesEntity> getPreferences() async => stored;

  @override
  Future<void> savePreferences(UserPreferencesEntity preferences) async {
    await gate?.future;
    stored = preferences;
  }
}

class _Books extends Fake implements RecipeBooksRepository {
  @override
  Future<List<Never>> getBooks() async => const [];
}

class _Lists extends Fake implements GroceryListsRepository {
  @override
  Future<List<Never>> getLists() async => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('idle resolves only after every change asked for was stored', () async {
    final preferences = _SlowPreferences();
    final bloc = SettingsBloc(
      getUserPreferencesUseCase: GetUserPreferencesUseCase(preferences),
      saveUserPreferencesUseCase: SaveUserPreferencesUseCase(preferences),
      recipeBooksRepository: _Books(),
      groceryListsRepository: _Lists(),
    );
    await bloc.idle;
    preferences.gate = Completer<void>();
    bloc.add(const SettingsEvent.toggleFastPageTurn(true));
    var idle = false;
    unawaited(bloc.idle.then((_) => idle = true));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(idle, isFalse);
    preferences.gate!.complete();
    await bloc.idle.timeout(const Duration(seconds: 5));
    expect(idle, isTrue);
    expect(preferences.stored.fastPageTurnEnabled, isTrue);
    await bloc.close();
  });
}
