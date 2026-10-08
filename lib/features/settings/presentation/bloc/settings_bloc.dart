import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/services/shopping_reminder_service.dart';
import '../../../../core/utils/i18n/app_language_mapper.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../grocery_list/domain/repositories/grocery_lists_repository.dart';
import '../../../recipe_books/domain/repositories/recipe_books_repository.dart';
import '../../../user_profile/domain/entities/user_preferences_entity.dart';
import '../../../user_profile/domain/usecases/get_user_preferences_usecase.dart';
import '../../../user_profile/domain/usecases/save_user_preferences_usecase.dart';

part 'settings_bloc.freezed.dart';

/// The switches on the notification settings screen, one per preference
/// flag. An enum rather than an event each so the screen is a list of rows
/// over one handler, and a new switch is one line here and one there.
enum NotificationSetting {
  push,
  repliesOnMyPosts,
  repliesOnThreads,
  shareInvites,
  sharedRecipeUpdates,
  adminReplies,
  announcements,
  foregroundPopups
  ;

  bool of(UserPreferencesEntity p) => switch (this) {
    push => p.pushEnabled,
    repliesOnMyPosts => p.notifyRepliesOnMyPosts,
    repliesOnThreads => p.notifyRepliesOnThreads,
    shareInvites => p.notifyShareInvites,
    sharedRecipeUpdates => p.notifySharedRecipeUpdates,
    adminReplies => p.notifyAdminReplies,
    announcements => p.notifyAnnouncements,
    foregroundPopups => p.foregroundPopupsEnabled,
  };

  UserPreferencesEntity apply(UserPreferencesEntity p, bool value) =>
      switch (this) {
        push => p.copyWith(pushEnabled: value),
        repliesOnMyPosts => p.copyWith(notifyRepliesOnMyPosts: value),
        repliesOnThreads => p.copyWith(notifyRepliesOnThreads: value),
        shareInvites => p.copyWith(notifyShareInvites: value),
        sharedRecipeUpdates => p.copyWith(notifySharedRecipeUpdates: value),
        adminReplies => p.copyWith(notifyAdminReplies: value),
        announcements => p.copyWith(notifyAnnouncements: value),
        foregroundPopups => p.copyWith(foregroundPopupsEnabled: value),
      };
}

@freezed
sealed class SettingsEvent with _$SettingsEvent {
  const factory SettingsEvent.init() = _Init;
  const factory SettingsEvent.updateShoppingDay(ShoppingDay day) =
      _UpdateShoppingDay;
  const factory SettingsEvent.toggleDietaryPreference(
    DietaryPreference preference,
  ) = _ToggleDietaryPreference;
  const factory SettingsEvent.toggleSoundEffects(bool enabled) =
      _ToggleSoundEffects;
  const factory SettingsEvent.changeLanguage(AppLanguage language) =
      _ChangeLanguage;
  const factory SettingsEvent.toggleFastPageTurn(bool enabled) =
      _ToggleFastPageTurn;
  const factory SettingsEvent.toggleCommunityPrices(bool enabled) =
      _ToggleCommunityPrices;
  const factory SettingsEvent.setShoppingReminders(
    List<ShoppingReminderSlot> slots,
  ) = _SetShoppingReminders;
  const factory SettingsEvent.setNotification(
    NotificationSetting setting,
    bool enabled,
  ) = _SetNotification;

  /// The look was switched; remember it on the account (the device itself
  /// is already switched by ThemeController).
  const factory SettingsEvent.setThemeMode(String mode) = _SetThemeMode;
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

/// Shared by the settings, preferences and notification screens: they are
/// three views over the one preferences record.
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
    on<_ChangeLanguage>(_changeLanguage);
    on<_ToggleFastPageTurn>(_toggleFastPageTurn);
    on<_ToggleCommunityPrices>(_toggleCommunityPrices);
    on<_SetShoppingReminders>(_setShoppingReminders);
    on<_SetNotification>(_setNotification);
    on<_SetThemeMode>(_setThemeMode);
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
      emit(
        .loaded(
          preferences,
          sharedBooksCount: books
              .where((b) => b.collaborators.isNotEmpty)
              .length,
          sharedListsCount: lists
              .where((l) => l.collaborators.isNotEmpty)
              .length,
        ),
      );
    } catch (e) {
      debugPrint('Settings error: $e');
      emit(.errorMessage(e.toString()));
    }
  }

  /// Every change shows at once and is persisted after: a switch that waits
  /// for the cloud write before moving reads as a tap that never landed.
  ///
  /// The session is told afterwards so everything that reads the current
  /// preferences elsewhere — the grocery tab's price fallback, the popup
  /// gate for pushes — sees the new value without a restart.
  Future<void> _commit(
    SettingsLoaded current,
    UserPreferencesEntity updated,
    Emitter<SettingsState> emit,
  ) async {
    emit(
      .loaded(
        updated,
        sharedBooksCount: current.sharedBooksCount,
        sharedListsCount: current.sharedListsCount,
      ),
    );
    await saveUserPreferencesUseCase(updated);
    AuthSessionService().publishPreferences(updated);
  }

  Future<void> _updateShoppingDay(
    _UpdateShoppingDay event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    final updated = current.preferences.copyWith(shoppingDay: event.day);
    await _commit(current, updated, emit);
    // With the slots the account chose, not the defaults: a reminder set
    // to "day before only" must stay that way when the day moves.
    await ShoppingReminderService().scheduleForShoppingDay(
      updated.shoppingDay,
      slots: updated.shoppingReminderSlots,
    );
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
    await _commit(
      current,
      current.preferences.copyWith(dietaryPreferences: preferences),
      emit,
    );
  }

  /// Persists the choice and switches the live locale, so every screen using
  /// `t` re-renders in the new language without a restart.
  Future<void> _changeLanguage(
    _ChangeLanguage event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    final updated = current.preferences.copyWith(language: event.language);
    emit(
      .loaded(
        updated,
        sharedBooksCount: current.sharedBooksCount,
        sharedListsCount: current.sharedListsCount,
      ),
    );
    await LocaleSettings.setLocale(event.language.locale);
    await saveUserPreferencesUseCase(updated);
    AuthSessionService().publishPreferences(updated);
  }

  Future<void> _toggleFastPageTurn(
    _ToggleFastPageTurn event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    await _commit(
      current,
      current.preferences.copyWith(fastPageTurnEnabled: event.enabled),
      emit,
    );
  }

  Future<void> _setShoppingReminders(
    _SetShoppingReminders event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    final updated = current.preferences.copyWith(
      shoppingReminderSlots: event.slots,
    );
    await _commit(current, updated, emit);
    // Rescheduled at once. Before, the old reminders kept firing until the
    // next launch re-read the preferences.
    await ShoppingReminderService().scheduleForShoppingDay(
      updated.shoppingDay,
      slots: updated.shoppingReminderSlots,
    );
  }

  Future<void> _setThemeMode(
    _SetThemeMode event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    if (current.preferences.themeMode == event.mode) return;
    await _commit(
      current,
      current.preferences.copyWith(themeMode: event.mode),
      emit,
    );
  }

  Future<void> _toggleCommunityPrices(
    _ToggleCommunityPrices event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    await _commit(
      current,
      current.preferences.copyWith(communityPricesEnabled: event.enabled),
      emit,
    );
  }

  Future<void> _toggleSoundEffects(
    _ToggleSoundEffects event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    await _commit(
      current,
      current.preferences.copyWith(soundEffectsEnabled: event.enabled),
      emit,
    );
  }

  Future<void> _setNotification(
    _SetNotification event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    await _commit(
      current,
      event.setting.apply(current.preferences, event.enabled),
      emit,
    );
  }
}
