import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/repositories/recipes_repository.dart';
import 'package:easy_plate/features/shared_recipes/domain/entities/shared_recipe_entity.dart';
import 'package:easy_plate/features/shared_recipes/domain/usecases/import_shared_recipe_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRecipes implements RecipesRepository {
  final saved = <RecipeEntity>[];
  @override
  Future<List<RecipeEntity>> getRecipes() async => saved;
  @override
  Future<void> saveRecipe(RecipeEntity recipe) async => saved.add(recipe);
  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

SharedRecipeEntity shared() => SharedRecipeEntity(
      id: 's1',
      authorUid: 'dana',
      authorName: 'דנה',
      createdAt: DateTime(2026, 1, 1),
      recipe: RecipeEntity(
        id: 's1',
        title: 'קובה סלק',
        ingredients: const [],
        steps: const ['מבשלים'],
        createdAt: DateTime(2026, 1, 1),
      ),
    );

void main() {
  late _FakeRecipes recipes;
  late ImportSharedRecipeUseCase useCase;

  setUp(() {
    recipes = _FakeRecipes();
    useCase = ImportSharedRecipeUseCase(recipes);
  });

  test('saves a copy under a fresh id, stamped with its origin', () async {
    final outcome = await useCase(shared());
    expect(outcome, ImportOutcome.saved);

    final copy = recipes.saved.single;
    expect(copy.id, isNot('s1'));
    expect(copy.savedFromSharedId, 's1');
    expect(copy.title, 'קובה סלק');
  });

  test('a second import of the same recipe makes no second copy', () async {
    // Reachable from the feed and from a forum reply; either could be tapped
    // twice. One copy per shared recipe, whichever path saved it.
    await useCase(shared());
    final outcome = await useCase(shared());

    expect(outcome, ImportOutcome.alreadySaved);
    expect(recipes.saved, hasLength(1));
  });
}
