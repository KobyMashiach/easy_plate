import 'dart:typed_data';

import '../../../my_recipes/domain/entities/recipe_entity.dart';

/// Where a candidate picture came from.
enum RecipeImageCandidateKind {
  /// The post's own cover — the platform's thumbnail for the video.
  cover,

  /// A still cut from the video at a moment the model found the food on
  /// screen without anyone in the frame.
  frame,
}

/// A picture the server offers for a recipe read from a video. Bytes, not
/// a file: nothing touches the disk until the user picks one, and the
/// candidates go with the review screen when it closes.
class RecipeImageCandidate {
  final RecipeImageCandidateKind kind;
  final Uint8List bytes;

  /// For a still, seconds from the start of the video.
  final double? atSeconds;

  const RecipeImageCandidate({
    required this.kind,
    required this.bytes,
    this.atSeconds,
  });

  bool get isCover => kind == RecipeImageCandidateKind.cover;
}

/// A recipe read from a social video together with the pictures offered
/// for it: the cover first when there is one, then the stills.
class SocialVideoRecipe {
  final RecipeEntity recipe;
  final List<RecipeImageCandidate> images;

  const SocialVideoRecipe({required this.recipe, this.images = const []});

  RecipeImageCandidate? get cover => images.where((i) => i.isCover).firstOrNull;
}
