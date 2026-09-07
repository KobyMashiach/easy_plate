import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/entities/recipe_ingredient_entity.dart';
import '../../../my_recipes/domain/repositories/recipes_repository.dart';
import '../repositories/recipe_sharing_repository.dart';
import 'sync_collab_recipe_usecase.dart';

/// Brings every locally cached shared recipe up to date in one pass.
///
/// [SyncCollabRecipeUseCase] does the same for a single recipe, but only when
/// that recipe is opened — which is too late to be the only mechanism. A
/// co-editor's change reached the details screen and nothing else: the recipe
/// list, the book, the meal planner and the grocery list all went on showing
/// the stale cache until someone happened to tap into the recipe. This runs on
/// sign-in and on every resume instead, and since the recipe box is watched,
/// the screens follow on their own.
class RefreshCollabRecipesUseCase {
  final RecipeSharingRepository sharing;
  final RecipesRepository recipes;

  const RefreshCollabRecipesUseCase({required this.sharing, required this.recipes});

  /// Returns how many local copies were actually rewritten, so a caller can
  /// tell "nothing changed" from "nothing was shared".
  Future<int> call({required String uid}) async {
    final cached = (await recipes.getRecipes()).where((recipe) => recipe.isShared).toList();
    // Two queries, both billed, for an account that shares nothing. Most do.
    if (cached.isEmpty) return 0;

    final fetched = await Future.wait([
      sharing.collabsOwnedBy(uid),
      sharing.collabsSharedWith(uid),
    ]);
    final byId = {for (final collab in fetched.expand((list) => list)) collab.id: collab};

    var rewritten = 0;
    for (final recipe in cached) {
      final collab = byId[recipe.collabId];
      // A recipe whose document is in neither answer is left exactly as it is,
      // rather than orphaned. Firestore serves a query from cache when offline,
      // so an empty answer is indistinguishable from having been removed from
      // the share — and orphaning on that would quietly unshare the account's
      // recipes every time it opened the app on a plane. The direct document
      // read in SyncCollabRecipeUseCase can tell the two apart; this cannot.
      if (collab == null) continue;

      final merged = SyncCollabRecipeUseCase.merged(recipe, collab, uid: uid);
      // Saving unconditionally would push all of them through the cloud mirror
      // on every resume, for recipes nobody touched.
      if (!differs(recipe, merged)) continue;

      await recipes.saveRecipe(merged);
      rewritten++;
    }
    return rewritten;
  }

  /// Whether the merge actually changed anything the user would see.
  ///
  /// Field by field because [RecipeEntity] carries no equality, and adding one
  /// would change how it behaves everywhere else it is compared.
  static bool differs(RecipeEntity a, RecipeEntity b) =>
      a.title != b.title ||
      a.prepTimeMinutes != b.prepTimeMinutes ||
      a.cookTimeMinutes != b.cookTimeMinutes ||
      a.imageFileName != b.imageFileName ||
      a.imageStoragePath != b.imageStoragePath ||
      a.collabRole != b.collabRole ||
      !_sameStrings(a.steps, b.steps) ||
      !_sameStrings(
        [for (final tag in a.dietaryTags) tag.name],
        [for (final tag in b.dietaryTags) tag.name],
      ) ||
      !_sameIngredients(a.ingredients, b.ingredients);

  static bool _sameStrings(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _sameIngredients(
    List<RecipeIngredientEntity> a,
    List<RecipeIngredientEntity> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].name != b[i].name || a[i].amount != b[i].amount || a[i].unit != b[i].unit) {
        return false;
      }
    }
    return true;
  }
}
