import '../../../../core/constants/app_enums.dart';
import 'recipe_ingredient_entity.dart';

class RecipeEntity {
  final String id;
  final String title;
  final int? prepTimeMinutes;
  final int? cookTimeMinutes;
  final List<RecipeIngredientEntity> ingredients;
  final List<String> steps;
  final List<DietaryPreference> dietaryTags;
  final RecipeIngestionChannel? sourceChannel;
  final String? sourceUrl;

  /// File name of the recipe photo inside the app's image directory — never an
  /// absolute path, which would not survive a reinstall.
  final String? imageFileName;

  /// Firebase Storage path of that same photo, once it has been uploaded.
  ///
  /// [imageFileName] alone only means something on the device that took the
  /// picture, which is why a photo reached neither a shared copy, nor the
  /// community feed, nor a reinstall. This is what every other copy resolves
  /// the image through. Null until the upload succeeds, and the save path
  /// tries again next time rather than recording a path that leads nowhere.
  final String? imageStoragePath;

  /// Set when this recipe was saved from the community feed. It is what
  /// separates "recipes I saved" from "recipes I wrote", and the copy stays
  /// fully editable — editing it changes only this local copy.
  final String? savedFromSharedId;

  /// True for a recipe saved as a raw-text template because the analysis
  /// timed out or failed. Its steps hold the original text, one line each, so
  /// the analysis can be run later from the details screen. Cleared the moment
  /// the user structures it — by the model or by hand in the editor.
  final bool pendingAnalysis;

  /// Set once this recipe is shared between accounts. Points at the Firestore
  /// document that is then the source of truth; the local copy is a cache of
  /// it, refreshed when the recipe is opened.
  final String? collabId;

  /// This account's standing on the shared recipe. Null for a recipe that is
  /// not shared at all.
  final CollabRole? collabRole;
  final DateTime createdAt;

  const RecipeEntity({
    required this.id,
    required this.title,
    required this.ingredients,
    required this.steps,
    required this.createdAt,
    this.prepTimeMinutes,
    this.cookTimeMinutes,
    this.dietaryTags = const [],
    this.sourceChannel,
    this.sourceUrl,
    this.imageFileName,
    this.imageStoragePath,
    this.savedFromSharedId,
    this.pendingAnalysis = false,
    this.collabId,
    this.collabRole,
  });

  bool get isShared => collabId != null;

  /// Viewers read; everyone else on a shared recipe — and anyone on an
  /// unshared one — may edit.
  bool get canEdit => collabRole != CollabRole.viewer;

  bool get isSavedFromCommunity => savedFromSharedId != null;

  /// The original text a template was saved from, for a later analysis.
  String get rawText => steps.join('\n');

  RecipeEntity copyWith({
    String? title,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    List<RecipeIngredientEntity>? ingredients,
    List<String>? steps,
    List<DietaryPreference>? dietaryTags,
    String? imageFileName,
    // A null `imageFileName` means "unchanged", so clearing needs its own flag.
    bool removeImage = false,
    String? imageStoragePath,
    bool? pendingAnalysis,
    String? collabId,
    CollabRole? collabRole,
  }) {
    return RecipeEntity(
      id: id,
      title: title ?? this.title,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      dietaryTags: dietaryTags ?? this.dietaryTags,
      sourceChannel: sourceChannel,
      sourceUrl: sourceUrl,
      imageFileName: removeImage ? null : (imageFileName ?? this.imageFileName),
      // A new photo invalidates the uploaded one. Carrying the old path over
      // would leave every other copy of this recipe — the shared one, the
      // community post, the same account on another phone — showing the
      // picture that was just replaced.
      imageStoragePath: removeImage
          ? null
          : (imageStoragePath ?? (imageFileName != null ? null : this.imageStoragePath)),
      savedFromSharedId: savedFromSharedId,
      pendingAnalysis: pendingAnalysis ?? this.pendingAnalysis,
      collabId: collabId ?? this.collabId,
      collabRole: collabRole ?? this.collabRole,
      createdAt: createdAt,
    );
  }
}
