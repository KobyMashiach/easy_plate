import '../../../my_recipes/domain/entities/recipe_entity.dart';

/// A recipe page as fetched, before any structuring.
class OriginalRecipePageEntity {
  final String url;
  final String? title;
  final String text;

  /// Present when the site published schema.org JSON-LD for the recipe. It is
  /// the site's own structured statement — nothing a model inferred — and it
  /// arrives in the same HTTP round trip as the text, so it costs nothing.
  final RecipeEntity? structured;

  const OriginalRecipePageEntity({
    required this.url,
    required this.text,
    this.title,
    this.structured,
  });

  bool get hasStructured => structured != null;
}
