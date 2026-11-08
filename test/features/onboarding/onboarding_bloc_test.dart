import 'dart:async';

import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:easy_plate/features/user_profile/domain/entities/user_preferences_entity.dart';
import 'package:easy_plate/features/user_profile/domain/repositories/user_preferences_repository.dart';
import 'package:easy_plate/features/user_profile/domain/usecases/get_user_preferences_usecase.dart';
import 'package:easy_plate/features/user_profile/domain/usecases/save_user_preferences_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _Preferences implements UserPreferencesRepository {
  UserPreferencesEntity stored = const UserPreferencesEntity(
    shoppingDay: ShoppingDay.sunday,
    dietaryPreferences: [],
  );
  bool refuse = false;
  int reads = 0;

  @override
  Future<UserPreferencesEntity> getPreferences() async {
    reads++;
    return stored;
  }

  @override
  Future<void> savePreferences(UserPreferencesEntity preferences) async {
    if (refuse) throw Exception('offline');
    stored = preferences;
  }
}

OnboardingBloc _bloc(_Preferences p, {Future<void> Function()? settled}) =>
    OnboardingBloc(
      getUserPreferencesUseCase: GetUserPreferencesUseCase(p),
      saveUserPreferencesUseCase: SaveUserPreferencesUseCase(p),
      settled: settled,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a refused Finish goes back to the form and flags it', () async {
    final preferences = _Preferences()..refuse = true;
    final bloc = _bloc(preferences);
    bloc.add(const OnboardingEvent.finish());
    final back = await bloc.stream
        .firstWhere((s) => s is Editing && s.saveFailed)
        .timeout(const Duration(seconds: 5));
    expect((back as Editing).saveFailed, isTrue);
    await bloc.close();
  });

  test(
    'Finish reads the record only once the screen\'s saves landed',
    () async {
      // Finish reads the record and writes it back marked done; read before
      // a pending choice was stored, that choice's own write (from its older
      // copy) would undo the mark.
      final preferences = _Preferences();
      final pending = Completer<void>();
      final bloc = _bloc(preferences, settled: () => pending.future);
      bloc.add(const OnboardingEvent.finish());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state, isA<Saving>());
      expect(preferences.reads, 0);
      pending.complete();
      // Past the wait it goes on to the save (which, without Firebase in a
      // test, ends back on the form).
      await bloc.stream
          .firstWhere((s) => s is Editing)
          .timeout(const Duration(seconds: 5));
      await bloc.close();
    },
  );
}
