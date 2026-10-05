import '../../features/my_recipes/domain/entities/recipe_entity.dart';
import '../../features/my_recipes/domain/entities/recipe_ingredient_entity.dart';
import 'content_translation.dart';

/// A shared recipe refreshed from its shared document, without losing this
/// account's translation of it.
///
/// The shared document holds the author's words. When this account reads the
/// recipe in another language, a refresh would otherwise pour the original
/// back over the translation on every resume. So when the only thing standing
/// between the two is the language, the local words are kept and everything
/// else — photo, times, servings, tags, the quantities — comes from the share.
/// A real rewrite by another member changes the structure (a step added, an
/// ingredient dropped) and is taken as it is.
///
/// Returns the recipe to save, and whether it is still a translation — the
/// caller saves those without re-stamping the language.
({RecipeEntity recipe, bool keptTranslation}) keepTranslation(
  RecipeEntity local,
  RecipeEntity merged,
) {
  final localLang = AppLanguageCode.fromCode(local.contentLang);
  if (localLang == null) return (recipe: merged, keptTranslation: false);
  final sharedLang = guessLanguage(merged.title, fallback: localLang);
  if (sharedLang == localLang) return (recipe: merged, keptTranslation: false);

  final sameShape =
      local.ingredients.length == merged.ingredients.length &&
      local.steps.length == merged.steps.length;
  if (!sameShape) return (recipe: merged, keptTranslation: false);

  return (
    recipe: merged.copyWith(
      title: local.title,
      ingredients: [
        for (final (index, shared) in merged.ingredients.indexed)
          RecipeIngredientEntity(
            name: local.ingredients[index].name,
            amount: shared.amount,
            unit: shared.unit,
          ),
      ],
      steps: local.steps,
      contentLang: local.contentLang,
      contentVersion: local.contentVersion,
    ),
    keptTranslation: true,
  );
}
