import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/auth_session_service.dart';
import '../../../../core/services/shopping_reminder_service.dart';
import '../../../user_profile/domain/entities/user_preferences_entity.dart';
import '../../../user_profile/domain/usecases/get_user_preferences_usecase.dart';
import '../../../user_profile/domain/usecases/save_user_preferences_usecase.dart';
import '../../../whats_new/presentation/whats_new_service.dart';

/// The choices on the first screen (look, language, shopping days, diet,
/// books) are saved one by one through the SettingsBloc, as on the
/// preferences screen; this bloc only closes the onboarding.
sealed class OnboardingEvent {
  const OnboardingEvent();
  const factory OnboardingEvent.finish() = OnboardingFinish;
}

final class OnboardingFinish extends OnboardingEvent {
  const OnboardingFinish();
}

sealed class OnboardingState {
  const OnboardingState();
}

/// [saveFailed]: back from a refused Finish, for the page to say so.
final class Editing extends OnboardingState {
  final bool saveFailed;
  const Editing({this.saveFailed = false});
}

final class Saving extends OnboardingState {
  const Saving();
}

final class Complete extends OnboardingState {
  const Complete();
}

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final GetUserPreferencesUseCase getUserPreferencesUseCase;
  final SaveUserPreferencesUseCase saveUserPreferencesUseCase;

  /// Resolves once every choice made on the screen is stored. Finish reads
  /// the record and writes it back with the onboarding marked done; a
  /// choice still being saved would otherwise write its older copy over
  /// that mark and send the account back here on the next launch.
  final Future<void> Function() settled;

  OnboardingBloc({
    required this.getUserPreferencesUseCase,
    required this.saveUserPreferencesUseCase,
    Future<void> Function()? settled,
  }) : settled = settled ?? (() async {}),
       super(const Editing()) {
    on<OnboardingFinish>(_finish);
  }

  factory OnboardingBloc.fromContext(
    BuildContext context, {
    Future<void> Function()? settled,
  }) {
    return OnboardingBloc(
      getUserPreferencesUseCase: GetUserPreferencesUseCase(context.read()),
      saveUserPreferencesUseCase: SaveUserPreferencesUseCase(context.read()),
      settled: settled,
    );
  }

  FutureOr<void> _finish(
    OnboardingFinish event,
    Emitter<OnboardingState> emit,
  ) async {
    if (state is! Editing) return;
    emit(const Saving());
    final UserPreferencesEntity saved;
    try {
      await settled();
      // The build a new account joins on is its "what's new" baseline: the
      // highlights start with the next update, never with this one.
      final build = await WhatsNewService().currentBuild();
      // Laid over the record as it stands — everything picked on this
      // screen and the language from the sign-in screen — not written as a
      // fresh record over it.
      saved = (await getUserPreferencesUseCase()).copyWith(
        onboardingComplete: true,
        whatsNewSeenBuild: build,
      );
      await saveUserPreferencesUseCase(saved);
      AuthSessionService().publishPreferences(saved);
    } catch (e) {
      // Back to the form rather than a spinner with no way out.
      debugPrint('Onboarding save failed: $e');
      emit(const Editing(saveFailed: true));
      return;
    }
    try {
      // With the slots the record holds, not the defaults (as SettingsBloc).
      await ShoppingReminderService().scheduleForShoppingDays(
        saved.shoppingDays,
        slots: saved.shoppingReminderSlots,
      );
    } catch (e) {
      // A plugin hiccup does not keep the account out of the app.
      debugPrint('Shopping reminder scheduling failed: $e');
    }
    emit(const Complete());
  }
}
