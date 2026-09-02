import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../../core/services/shopping_reminder_service.dart';
import '../../../grocery_list/domain/repositories/grocery_lists_repository.dart';
import '../../../recipe_books/domain/repositories/recipe_books_repository.dart';
import '../../../user_profile/domain/entities/user_preferences_entity.dart';
import '../../../user_profile/domain/usecases/get_user_preferences_usecase.dart';
import '../../../user_profile/domain/usecases/save_user_preferences_usecase.dart';

part 'settings_bloc.freezed.dart';

@freezed
sealed class SettingsEvent with _$SettingsEvent {
  const factory SettingsEvent.init() = _Init;
  const factory SettingsEvent.updateShoppingDay(ShoppingDay day) = _UpdateShoppingDay;
  const factory SettingsEvent.toggleDietaryPreference(DietaryPreference preference) =
      _ToggleDietaryPreference;
  const factory SettingsEvent.toggleSoundEffects(bool enabled) = _ToggleSoundEffects;
}

@freezed
sealed class SettingsState with _$SettingsState {
  const factory SettingsState.loading() = SettingsLoading;
  const factory SettingsState.loaded(
    UserPreferencesEntity preferences, {
    @Default(0) int sharedBooksCount,
    @Default(0) int sharedListsCount,
  }) = SettingsLoaded;
  const factory SettingsState.errorMessage(String error) = SettingsError;
}

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetUserPreferencesUseCase getUserPreferencesUseCase;
  final SaveUserPreferencesUseCase saveUserPreferencesUseCase;
  final RecipeBooksRepository recipeBooksRepository;
  final GroceryListsRepository groceryListsRepository;

  SettingsBloc({
    required this.getUserPreferencesUseCase,
    required this.saveUserPreferencesUseCase,
    required this.recipeBooksRepository,
    required this.groceryListsRepository,
  }) : super(const SettingsState.loading()) {
    on<_Init>(_init);
    on<_UpdateShoppingDay>(_updateShoppingDay);
    on<_ToggleDietaryPreference>(_toggleDietaryPreference);
    on<_ToggleSoundEffects>(_toggleSoundEffects);
    add(const SettingsEvent.init());
  }

  factory SettingsBloc.fromContext(BuildContext context) {
    return SettingsBloc(
      getUserPreferencesUseCase: GetUserPreferencesUseCase(context.read()),
      saveUserPreferencesUseCase: SaveUserPreferencesUseCase(context.read()),
      recipeBooksRepository: context.read(),
      groceryListsRepository: context.read(),
    );
  }

  Future<void> _init(_Init event, Emitter<SettingsState> emit) async {
    try {
      final preferences = await getUserPreferencesUseCase();
      final books = await recipeBooksRepository.getBooks();
      final lists = await groceryListsRepository.getLists();
      emit(.loaded(
        preferences,
        sharedBooksCount: books.where((b) => b.collaborators.isNotEmpty).length,
        sharedListsCount: lists.where((l) => l.collaborators.isNotEmpty).length,
      ));
    } catch (e) {
      debugPrint('Settings error: $e');
      emit(.errorMessage(e.toString()));
    }
  }

  Future<void> _updateShoppingDay(_UpdateShoppingDay event, Emitter<SettingsState> emit) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    final updated = current.preferences.copyWith(shoppingDay: event.day);
    await saveUserPreferencesUseCase(updated);
    await ShoppingReminderService().scheduleForShoppingDay(event.day);
    emit(.loaded(
      updated,
      sharedBooksCount: current.sharedBooksCount,
      sharedListsCount: current.sharedListsCount,
    ));
  }

  Future<void> _toggleDietaryPreference(
    _ToggleDietaryPreference event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    final preferences = [...current.preferences.dietaryPreferences];
    preferences.contains(event.preference)
        ? preferences.remove(event.preference)
        : preferences.add(event.preference);
    final updated = current.preferences.copyWith(dietaryPreferences: preferences);
    await saveUserPreferencesUseCase(updated);
    emit(.loaded(
      updated,
      sharedBooksCount: current.sharedBooksCount,
      sharedListsCount: current.sharedListsCount,
    ));
  }

  Future<void> _toggleSoundEffects(_ToggleSoundEffects event, Emitter<SettingsState> emit) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    final updated = current.preferences.copyWith(soundEffectsEnabled: event.enabled);
    await saveUserPreferencesUseCase(updated);
    emit(.loaded(
      updated,
      sharedBooksCount: current.sharedBooksCount,
      sharedListsCount: current.sharedListsCount,
    ));
  }
}
