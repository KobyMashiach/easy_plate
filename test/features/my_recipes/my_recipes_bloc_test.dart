import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/repositories/recipes_repository.dart';
import 'package:easy_plate/features/my_recipes/domain/usecases/delete_recipe_usecase.dart';
import 'package:easy_plate/features/my_recipes/domain/usecases/get_recipes_usecase.dart';
import 'package:easy_plate/features/my_recipes/domain/usecases/watch_recipes_usecase.dart';
import 'package:easy_plate/features/my_recipes/presentation/bloc/my_recipes_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Recipes extends Mock implements RecipesRepository {}

void main() {
  setUpAll(() => LocaleSettings.setLocale(AppLocale.en));

  test('pass 10: a failed delete keeps the list and says so over it', () async {
    final repo = _Recipes();
    final soup = RecipeEntity(
      id: 'r1',
      title: 'Soup',
      ingredients: const [],
      steps: const [],
      createdAt: DateTime(2026),
    );
    when(() => repo.getRecipes()).thenAnswer((_) async => [soup]);
    when(() => repo.watchRecipes()).thenAnswer((_) => const Stream.empty());
    when(() => repo.deleteRecipe('r1')).thenThrow(StateError('disk'));
    final bloc = MyRecipesBloc(
      getRecipesUseCase: GetRecipesUseCase(repo),
      deleteRecipeUseCase: DeleteRecipeUseCase(repo),
      watchRecipesUseCase: WatchRecipesUseCase(repo),
    );
    bloc.add(const MyRecipesEvent.init());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final next = bloc.stream.first;
    bloc.add(const MyRecipesEvent.deleteRecipe('r1'));
    // Not an error screen (which lost the Mine/Saved tab and the filters):
    // the same list, with the failure as a notice the page shows.
    final after = await next;
    expect(after, isA<MyRecipesLoaded>());
    after as MyRecipesLoaded;
    expect(after.recipes.map((r) => r.id), ['r1']);
    expect(after.notice, t.common.error);

    // A second failure in a row is still a change the busy card ends on.
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final again = bloc.stream.first;
    bloc.add(const MyRecipesEvent.deleteRecipe('r1'));
    expect(await again, isA<MyRecipesLoaded>());
    await bloc.close();
  });
}
