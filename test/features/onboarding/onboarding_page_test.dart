import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/features/grocery_list/domain/repositories/grocery_lists_repository.dart';
import 'package:easy_plate/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:easy_plate/features/recipe_books/domain/repositories/recipe_books_repository.dart';
import 'package:easy_plate/features/user_profile/domain/entities/user_preferences_entity.dart';
import 'package:easy_plate/features/user_profile/domain/repositories/user_preferences_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _Preferences implements UserPreferencesRepository {
  @override
  Future<UserPreferencesEntity> getPreferences() async =>
      const UserPreferencesEntity(
        shoppingDay: ShoppingDay.sunday,
        dietaryPreferences: [],
      );

  @override
  Future<void> savePreferences(UserPreferencesEntity preferences) async {}
}

// The settings bloc reads the shared counts on load; none here.
class _Books extends Fake implements RecipeBooksRepository {
  @override
  Future<List<Never>> getBooks() async => const [];
}

class _Lists extends Fake implements GroceryListsRepository {
  @override
  Future<List<Never>> getLists() async => const [];
}

void main() {
  // The icon carries matchTextDirection: the framework mirrors it under
  // RTL, so "forward" is arrow_forward in every language. arrow_back drew
  // Finish pointing backwards — right in Hebrew/Arabic, left in English.
  for (final locale in [AppLocale.he, AppLocale.en]) {
    testWidgets('Finish points forward (${locale.languageCode})', (
      tester,
    ) async {
      // Tall enough that the list builds the button at its bottom.
      tester.view.physicalSize = const Size(400, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.runAsync(() => LocaleSettings.setLocale(locale));
      addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.he));
      await tester.pumpWidget(
        TranslationProvider(
          child: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<UserPreferencesRepository>(
                create: (_) => _Preferences(),
              ),
              RepositoryProvider<RecipeBooksRepository>(
                create: (_) => _Books(),
              ),
              RepositoryProvider<GroceryListsRepository>(
                create: (_) => _Lists(),
              ),
            ],
            child: MaterialApp(
              builder: (context, child) => Directionality(
                textDirection: locale == AppLocale.he
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: child!,
              ),
              home: const OnboardingPage(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    });
  }
}
