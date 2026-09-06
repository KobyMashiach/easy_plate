import '../../../../core/constants/app_enums.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';

/// A recipe made from unanalysed text, for when the model timed out or failed.
///
/// Every non-empty line becomes a step, *including* the first one that also
/// serves as the title — the steps have to hold the complete original text,
/// because that is what a later analysis is run on. Nothing is guessed:
/// ingredients stay empty until the model or the user fills them.
RecipeEntity buildTemplateRecipe({
  required String id,
  required String text,
  required RecipeIngestionChannel channel,
  required String untitled,
  String? sourceUrl,
}) {
  final lines = text
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  final firstLine = lines.isEmpty ? untitled : lines.first;
  // A pasted first line can be a whole paragraph; a title is not.
  final title = firstLine.length > 80 ? '${firstLine.substring(0, 77)}…' : firstLine;

  return RecipeEntity(
    id: id,
    title: title,
    ingredients: const [],
    steps: lines,
    sourceChannel: channel,
    sourceUrl: sourceUrl,
    pendingAnalysis: true,
    createdAt: DateTime.now(),
  );
}

/// The blank the structured editor opens on for a recipe written by hand.
RecipeEntity buildBlankRecipe({required String id}) => RecipeEntity(
      id: id,
      title: '',
      ingredients: const [],
      steps: const [],
      sourceChannel: RecipeIngestionChannel.manual,
      createdAt: DateTime.now(),
    );
