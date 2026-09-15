import 'dart:typed_data';

import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../repositories/recipe_ingestion_repository.dart';

/// A picture from the image model, plus the prompts the app writes for it.
///
/// Prompts are English regardless of the UI language: the image models are
/// tuned on English captions, and a dish name transliterates badly. The
/// title still goes in as written so the picture matches the recipe.
class GenerateImageUseCase {
  final RecipeIngestionRepository repository;
  GenerateImageUseCase(this.repository);

  Future<Uint8List> call(String prompt) => repository.generateImage(prompt);

  /// A plated shot of the dish, in the style of the community photos.
  static String recipePrompt(RecipeEntity recipe) {
    final ingredients = recipe.ingredients.take(8).map((i) => i.name).join(', ');
    return 'Appetizing food photograph of the dish "${recipe.title}"'
        '${ingredients.isEmpty ? '' : ', made with $ingredients'}. '
        'Plated and ready to eat, natural daylight, shallow depth of field, '
        'top-down or 45-degree angle, clean background. No text, no people, no hands.';
  }

  /// A cookbook cover for a recipe book. [theme] sets the mood and the kind
  /// of food; [subject] is what the user typed and is placed front and
  /// centre — both together give "a pile of indulgent burgers", either alone
  /// still gives a cover.
  static String bookCoverPrompt(String title, {CoverTheme? theme, String? subject}) {
    final what = subject?.trim();
    final focus = what == null || what.isEmpty ? null : what;
    final scene = switch ((theme, focus)) {
      (final t?, final f?) => 'featuring $f, ${t.promptFragment}',
      (final t?, null) => t.promptFragment,
      (null, final f?) => 'featuring $f',
      (null, null) => 'a warm, inviting food still life',
    };
    return 'Cookbook cover illustration for a recipe book titled "$title": $scene. '
        'Soft light, tasteful composition, the food is the hero. '
        'No text, no letters, no people.';
  }
}

/// The moods a cover can be asked for. The labels live in the translations;
/// the fragments are the English the image model is prompted with.
enum CoverTheme {
  kids,
  healthy,
  indulgent,
  sweets,
  meat,
  vegan,
  holidays,
  quick;

  String get promptFragment => switch (this) {
        CoverTheme.kids =>
          'playful and colourful, kid-friendly food with fun shapes, bright cheerful palette',
        CoverTheme.healthy =>
          'fresh and healthy — vegetables, grains, greens, light and clean, morning light',
        CoverTheme.indulgent =>
          'gloriously indulgent comfort food, rich, oozing, decadent, moody dramatic light',
        CoverTheme.sweets => 'desserts and baking — cakes, pastries, cookies, soft pastel palette',
        CoverTheme.meat => 'grilled meats and barbecue, smoky, charred, rustic wooden board',
        CoverTheme.vegan => 'plant-based dishes, vibrant vegetables and legumes, earthy tones',
        CoverTheme.holidays =>
          'a festive holiday table, celebratory, abundant, candles and warm golden light',
        CoverTheme.quick => 'quick everyday meals, simple ingredients, bright and practical',
      };
}
