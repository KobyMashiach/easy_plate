import 'recipe_entity.dart';

extension RecipeCommunityTexts on RecipeEntity {
  /// Every piece of text a community post of this recipe shows, for the
  /// swear filter.
  Iterable<String> get communityTexts => [
    title,
    for (final i in ingredients) ...[i.name, ?i.section],
    ...steps,
  ];
}
