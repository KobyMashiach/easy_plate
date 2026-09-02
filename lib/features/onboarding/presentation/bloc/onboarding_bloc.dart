import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../../core/services/shopping_reminder_service.dart';
import '../../../user_profile/domain/entities/user_preferences_entity.dart';
import '../../../user_profile/domain/usecases/save_user_preferences_usecase.dart';

part 'onboarding_bloc.freezed.dart';

@freezed
sealed class OnboardingEvent with _$OnboardingEvent {
  const factory OnboardingEvent.selectShoppingDay(ShoppingDay day) = _SelectShoppingDay;
  const factory OnboardingEvent.toggleDietaryPreference(DietaryPreference preference) =
      _ToggleDietaryPreference;
  const factory OnboardingEvent.finish() = _Finish;
}

@freezed
sealed class OnboardingState with _$OnboardingState {
  const factory OnboardingState.editing(
    ShoppingDay shoppingDay,
    List<DietaryPreference> selectedPreferences,
  ) = Editing;
  const factory OnboardingState.saving(
    ShoppingDay shoppingDay,
    List<DietaryPreference> selectedPreferences,
  ) = Saving;
  const factory OnboardingState.complete() = Complete;
}

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final SaveUserPreferencesUseCase saveUserPreferencesUseCase;

  OnboardingBloc({required this.saveUserPreferencesUseCase})
      : super(const OnboardingState.editing(ShoppingDay.sunday, [])) {
    on<_SelectShoppingDay>(_selectShoppingDay);
    on<_ToggleDietaryPreference>(_toggleDietaryPreference);
    on<_Finish>(_finish);
  }

  factory OnboardingBloc.fromContext(BuildContext context) {
    return OnboardingBloc(
      saveUserPreferencesUseCase: SaveUserPreferencesUseCase(context.read()),
    );
  }

  FutureOr<void> _selectShoppingDay(_SelectShoppingDay event, Emitter<OnboardingState> emit) {
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
    await saveUserPreferencesUseCase(
      UserPreferencesEntity(
        shoppingDay: current.shoppingDay,
        dietaryPreferences: current.selectedPreferences,
        onboardingComplete: true,
      ),
    );
    await ShoppingReminderService().scheduleForShoppingDay(current.shoppingDay);
    emit(const OnboardingState.complete());
  }
}
