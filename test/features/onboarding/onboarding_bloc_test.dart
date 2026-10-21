import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:easy_plate/features/user_profile/domain/entities/user_preferences_entity.dart';
import 'package:easy_plate/features/user_profile/domain/repositories/user_preferences_repository.dart';
import 'package:easy_plate/features/user_profile/domain/usecases/get_user_preferences_usecase.dart';
import 'package:easy_plate/features/user_profile/domain/usecases/save_user_preferences_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _RefusingPreferences implements UserPreferencesRepository {
  @override
  Future<UserPreferencesEntity> getPreferences() async =>
      const UserPreferencesEntity(
        shoppingDay: ShoppingDay.sunday,
        dietaryPreferences: [],
      );

  @override
  Future<void> savePreferences(UserPreferencesEntity preferences) async =>
      throw Exception('offline');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a refused Finish goes back to the form and flags it', () async {
    final preferences = _RefusingPreferences();
    final bloc = OnboardingBloc(
      getUserPreferencesUseCase: GetUserPreferencesUseCase(preferences),
      saveUserPreferencesUseCase: SaveUserPreferencesUseCase(preferences),
    );
    bloc.add(const OnboardingEvent.selectShoppingDay(ShoppingDay.friday));
    bloc.add(const OnboardingEvent.finish());
    final back = await bloc.stream
        .firstWhere((s) => s is Editing && s.saveFailed)
        .timeout(const Duration(seconds: 5));

    // The choices are kept, and the page is told to say so.
    expect((back as Editing).shoppingDay, ShoppingDay.friday);
    await bloc.close();
  });
}
