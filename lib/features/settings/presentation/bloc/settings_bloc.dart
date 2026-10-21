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

  /// [saved] is completed with whether the record now holds [language]:
  /// content translation waits for that, not for the on-screen preview.
  const factory SettingsEvent.changeLanguage(
    AppLanguage language, {
    Completer<bool>? saved,
  }) = _ChangeLanguage;
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

    /// Bumped by every refused save, so the screens can say so (the
    /// switch going back on its own read as a tap that did not land).
    @Default(0) int saveFailures,
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
    // One queue for every event, not one per type: each save re-reads the
    // stored record, applies its change and writes it back, so two switches
    // flipped in quick succession would both read the record before either
    // wrote and the second write would undo the first. One at a time, in
    // the order they were tapped — the init first, so a tap that lands
    // before the first read is answered rather than dropped.
    on<SettingsEvent>(_handle, transformer: _sequential());
    add(const SettingsEvent.init());
  }

  /// Handles each event only after the previous one finished.
  static EventTransformer<E> _sequential<E>() =>
      (events, mapper) => events.asyncExpand(mapper);

  Future<void> _handle(SettingsEvent event, Emitter<SettingsState> emit) =>
      switch (event) {
        _Init() => _init(event, emit),
        _UpdateShoppingDay() => _updateShoppingDay(event, emit),
        _ToggleDietaryPreference() => _toggleDietaryPreference(event, emit),
        _ToggleSoundEffects() => _toggleSoundEffects(event, emit),
        _ChangeLanguage() => _changeLanguage(event, emit),
        _ToggleFastPageTurn() => _toggleFastPageTurn(event, emit),
        _ToggleCommunityPrices() => _toggleCommunityPrices(event, emit),
        _SetShoppingReminders() => _setShoppingReminders(event, emit),
        _SetNotification() => _setNotification(event, emit),
        _SetThemeMode() => _setThemeMode(event, emit),
      };

  factory SettingsBloc.fromContext(BuildContext context) {
    return SettingsBloc(
      getUserPreferencesUseCase: GetUserPreferencesUseCase(context.read()),
      saveUserPreferencesUseCase: SaveUserPreferencesUseCase(context.read()),
      recipeBooksRepository: context.read(),
      groceryListsRepository: context.read(),
    );
  }

  int _saveFailures = 0;

  /// For a screen's listener: a save was refused since [previous].
  static bool saveFailedBetween(
    SettingsState previous,
    SettingsState current,
  ) =>
      current is SettingsLoaded &&
      current.saveFailures >
          (previous is SettingsLoaded ? previous.saveFailures : 0);

  Future<void> _init(_Init event, Emitter<SettingsState> emit) async {
    try {
      final preferences = await getUserPreferencesUseCase();
      // The counts only label a row: a failed read of either box shows 0
      // rather than failing all three settings screens.
      final books = await _orEmpty(recipeBooksRepository.getBooks, 'books');
      final lists = await _orEmpty(groceryListsRepository.getLists, 'lists');
      emit(
        .loaded(
          preferences,
          sharedBooksCount: books.where((b) => b.isShared).length,
          sharedListsCount: lists.where((l) => l.isShared).length,
          saveFailures: _saveFailures,
        ),
      );
    } catch (e) {
      debugPrint('Settings error: $e');
      emit(.errorMessage(t.common.loadFailed));
    }
  }

  static Future<List<T>> _orEmpty<T>(
    Future<List<T>> Function() read,
    String what,
  ) async {
    try {
      return await read();
    } catch (e) {
      debugPrint('Settings: shared $what count unavailable: $e');
      return const [];
    }
  }

  /// Every change shows at once and is persisted after: a switch that waits
  /// for the cloud write before moving reads as a tap that never landed.
  ///
  /// [change] is applied to the record as stored, not to this bloc's copy of
  /// it: the notification screen, the assistant and the what's-new book each
  /// save through their own path, and a copy loaded before they did wrote
  /// their changes back out (a switch turned off there came back on here).
  /// A refused save puts the screen back where it was.
  ///
  /// The session is told afterwards so everything that reads the current
  /// preferences elsewhere — the grocery tab's price fallback, the popup
  /// gate for pushes — sees the new value without a restart.
  Future<UserPreferencesEntity> _commit(
    SettingsLoaded current,
    UserPreferencesEntity Function(UserPreferencesEntity) change,
    Emitter<SettingsState> emit,
  ) async {
    void show(UserPreferencesEntity preferences) => emit(
      .loaded(
        preferences,
        sharedBooksCount: current.sharedBooksCount,
        sharedListsCount: current.sharedListsCount,
        saveFailures: _saveFailures,
      ),
    );
    show(change(current.preferences));
    final UserPreferencesEntity updated;
    try {
      updated = change(await getUserPreferencesUseCase());
      await saveUserPreferencesUseCase(updated);
    } catch (e) {
      debugPrint('Settings save failed: $e');
      _saveFailures++;
      show(current.preferences);
      return current.preferences;
    }
    show(updated);
    AuthSessionService().publishPreferences(updated);
    return updated;
  }

  Future<void> _updateShoppingDay(
    _UpdateShoppingDay event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    final updated = await _commit(
      current,
      (p) => p.copyWith(shoppingDay: event.day),
      emit,
    );
    // With the slots the account chose, not the defaults: a reminder set
    // to "day before only" must stay that way when the day moves.
    await _reschedule(updated);
  }

  /// The plugin can throw (permission revoked, exact alarms off); the
  /// preference is saved either way, so the failure is only logged.
  Future<void> _reschedule(UserPreferencesEntity updated) async {
    try {
      await ShoppingReminderService().scheduleForShoppingDay(
        updated.shoppingDay,
        slots: updated.shoppingReminderSlots,
      );
    } catch (e) {
      debugPrint('Shopping reminders not rescheduled: $e');
    }
  }

  Future<void> _toggleDietaryPreference(
    _ToggleDietaryPreference event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    // Toggled on the record as re-read, not on this bloc's copy: the
    // assistant saves this list through its own path, and a list built
    // here would write its stale version back over that.
    await _commit(
      current,
      (p) => p.copyWith(
        dietaryPreferences: p.dietaryPreferences.contains(event.preference)
            ? (p.dietaryPreferences.toList()..remove(event.preference))
            : [...p.dietaryPreferences, event.preference],
      ),
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
    if (current is! SettingsLoaded) {
      event.saved?.complete(false);
      return;
    }
    await LocaleSettings.setLocale(event.language.locale);
    final saved = await _commit(
      current,
      (p) => p.copyWith(language: event.language),
      emit,
    );
    // Refused: the record kept its language, so the live locale goes back
    // too, rather than the screens in one language and the selector on
    // another.
    if (saved.language != event.language) {
      await LocaleSettings.setLocale(saved.language.locale);
    } else {
      // Scheduled reminders carry their text from when they were set:
      // without this they kept arriving in the old language.
      await _reschedule(saved);
    }
    event.saved?.complete(saved.language == event.language);
  }

  Future<void> _toggleFastPageTurn(
    _ToggleFastPageTurn event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    await _commit(
      current,
      (p) => p.copyWith(fastPageTurnEnabled: event.enabled),
      emit,
    );
  }

  Future<void> _setShoppingReminders(
    _SetShoppingReminders event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    final updated = await _commit(
      current,
      (p) => p.copyWith(shoppingReminderSlots: event.slots),
      emit,
    );
    // Rescheduled at once. Before, the old reminders kept firing until the
    // next launch re-read the preferences.
    await _reschedule(updated);
  }

  Future<void> _setThemeMode(
    _SetThemeMode event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    if (current.preferences.themeMode == event.mode) return;
    await _commit(current, (p) => p.copyWith(themeMode: event.mode), emit);
  }

  Future<void> _toggleCommunityPrices(
    _ToggleCommunityPrices event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state;
    if (current is! SettingsLoaded) return;
    await _commit(
      current,
      (p) => p.copyWith(communityPricesEnabled: event.enabled),
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
      (p) => p.copyWith(soundEffectsEnabled: event.enabled),
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
      (p) => event.setting.apply(p, event.enabled),
      emit,
    );
  }
}
