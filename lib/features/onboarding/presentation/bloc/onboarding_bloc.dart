import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/services/shopping_reminder_service.dart';
import '../../../user_profile/domain/entities/user_preferences_entity.dart';
import '../../../user_profile/domain/usecases/get_user_preferences_usecase.dart';
import '../../../user_profile/domain/usecases/save_user_preferences_usecase.dart';
import '../../../whats_new/presentation/whats_new_service.dart';

part 'onboarding_bloc.freezed.dart';

@freezed
sealed class OnboardingEvent with _$OnboardingEvent {
  const factory OnboardingEvent.selectShoppingDay(ShoppingDay day) =
      _SelectShoppingDay;
  const factory OnboardingEvent.toggleDietaryPreference(
    DietaryPreference preference,
  ) = _ToggleDietaryPreference;
  const factory OnboardingEvent.finish() = _Finish;
}

@freezed
sealed class OnboardingState with _$OnboardingState {
  /// [saveFailed]: back from a refused Finish, for the page to say so.
  const factory OnboardingState.editing(
    ShoppingDay shoppingDay,
    List<DietaryPreference> selectedPreferences, {
    @Default(false) bool saveFailed,
  }) = Editing;
  const factory OnboardingState.saving(
    ShoppingDay shoppingDay,
    List<DietaryPreference> selectedPreferences,
  ) = Saving;
  const factory OnboardingState.complete() = Complete;
}

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final GetUserPreferencesUseCase getUserPreferencesUseCase;
  final SaveUserPreferencesUseCase saveUserPreferencesUseCase;

  OnboardingBloc({
    required this.getUserPreferencesUseCase,
    required this.saveUserPreferencesUseCase,
  }) : super(const OnboardingState.editing(ShoppingDay.sunday, [])) {
    on<_SelectShoppingDay>(_selectShoppingDay);
    on<_ToggleDietaryPreference>(_toggleDietaryPreference);
    on<_Finish>(_finish);
  }

  factory OnboardingBloc.fromContext(BuildContext context) {
    return OnboardingBloc(
      getUserPreferencesUseCase: GetUserPreferencesUseCase(context.read()),
      saveUserPreferencesUseCase: SaveUserPreferencesUseCase(context.read()),
    );
  }

  FutureOr<void> _selectShoppingDay(
    _SelectShoppingDay event,
    Emitter<OnboardingState> emit,
  ) {
    final current = state;
    if (current is Editing) {
      emit(.editing(event.day, current.selectedPreferences));
    }
  }

  FutureOr<void> _toggleDietaryPreference(
    _ToggleDietaryPreference event,
    Emitter<OnboardingState> emit,
  ) {
    final current = state;
    if (current is Editing) {
      final preferences = [...current.selectedPreferences];
      preferences.contains(event.preference)
          ? preferences.remove(event.preference)
          : preferences.add(event.preference);
      emit(.editing(current.shoppingDay, preferences));
    }
  }

  FutureOr<void> _finish(_Finish event, Emitter<OnboardingState> emit) async {
    final current = state;
    if (current is! Editing) return;
    emit(.saving(current.shoppingDay, current.selectedPreferences));
    final UserPreferencesEntity saved;
    try {
      // The build a new account joins on is its "what's new" baseline: the
      // highlights start with the next update, never with this one.
      final build = await WhatsNewService().currentBuild();
      // Laid over the record as it stands — the language picked on the
      // sign-in screen, the theme, the notification switches — not written
      // as a fresh record over it, which reset all of those to defaults.
      saved = (await getUserPreferencesUseCase()).copyWith(
        shoppingDay: current.shoppingDay,
        dietaryPreferences: current.selectedPreferences,
        onboardingComplete: true,
        whatsNewSeenBuild: build,
      );
      await saveUserPreferencesUseCase(saved);
      AuthSessionService().publishPreferences(saved);
    } catch (e) {
      // Back to the form rather than a spinner with no way out.
      debugPrint('Onboarding save failed: $e');
      emit(
        .editing(
          current.shoppingDay,
          current.selectedPreferences,
          saveFailed: true,
        ),
      );
      return;
    }
    try {
      // With the slots the record holds, not the defaults (as SettingsBloc).
      await ShoppingReminderService().scheduleForShoppingDay(
        current.shoppingDay,
        slots: saved.shoppingReminderSlots,
      );
    } catch (e) {
      // A plugin hiccup does not keep the account out of the app.
      debugPrint('Shopping reminder scheduling failed: $e');
    }
    emit(const OnboardingState.complete());
  }
}
