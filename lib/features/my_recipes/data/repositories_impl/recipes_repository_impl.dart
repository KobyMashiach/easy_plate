import 'package:flutter/foundation.dart';
import 'dart:async';

import '../../../../core/hive/user_scope.dart';
import '../../../../core/sync/recipe_image_store.dart';
import '../../../../core/sync/user_cloud_collection.dart';
import '../../../../core/translation/content_translation.dart';
import '../../domain/entities/recipe_entity.dart';
import '../../domain/repositories/recipes_repository.dart';
import '../datasources/recipes_local_datasource.dart';
import '../models/recipe_model.dart';

class RecipesRepositoryImpl implements RecipesRepository {
  final RecipesLocalDataSource localDataSource;

  /// Mirrors every write into the account's own Firestore subtree so the
  /// recipes come back after an uninstall or on a second device. Optional so
  /// tests can exercise the repository without Firebase.
  final UserCloudCollection<RecipeModel>? cloud;

  /// Sends the photo itself to Storage. Separate from [cloud] because the
  /// mirror carries only the recipe's fields — the picture is a file, and
  /// without this it stayed on the one device that took it.
  final RecipeImageStore? images;

  RecipesRepositoryImpl({
    required this.localDataSource,
    this.cloud,
    this.images,
  });

  @override
  Future<List<RecipeEntity>> getRecipes() async {
    final models = await localDataSource.getRecipes();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Stream<List<RecipeEntity>> watchRecipes() => localDataSource
      .watchRecipes()
      .map((models) => models.map((m) => m.toEntity()).toList());

  @override
  Future<RecipeEntity?> getRecipeById(String id) async {
    final model = await localDataSource.getRecipeById(id);
    return model?.toEntity();
  }

  @override
  Future<void> saveRecipe(
    RecipeEntity recipe, {
    bool stampLanguage = true,
  }) async {
    if (stampLanguage) {
      recipe = await _stamped(recipe);
    }
    final model = recipe.toModel();
    await localDataSource.saveRecipe(model);
    // Deliberately not awaited: offline, Firestore holds the write in its own
    // queue and only completes once a server acknowledges it, and a photo
    // upload over a slow connection is worse still. Both would leave the editor
    // spinning until the network came back, for work the user is not waiting on.
    unawaited(_publish(model));
  }

  /// Uploads the photo if it has not travelled yet, then mirrors the recipe.
  Future<void> _publish(RecipeModel model) async {
    final uploaded = await _uploadImage(model);
    // Written back to the box as well, so the next save does not re-upload the
    // same file and every screen reading the box can resolve the picture.
    if (uploaded != null) await localDataSource.saveRecipe(uploaded);
    await (cloud?.push(uploaded ?? model) ?? Future.value());
  }

  /// The recipe with its photo's Storage path filled in, or null when there was
  /// nothing to do — no photo, no account resolved, already uploaded, or the
  /// upload failed. A failure deliberately leaves the path null so the next
  /// save tries again, rather than recording one that leads nowhere.
  Future<RecipeModel?> _uploadImage(RecipeModel model) async {
    final store = images;
    final fileName = model.imageFileName;
    final uid = UserScope().uid;
    if (store == null || fileName == null || uid == null) {
      debugPrint(
        'Photo upload skipped for ${model.id}: '
        '${store == null
            ? 'no store'
            : fileName == null
            ? 'no photo'
            : 'no uid'}',
      );
      return null;
    }
    if (model.imageStoragePath != null) return null;

    final path = await store.upload(fileName, uid: uid);
    debugPrint('Photo upload for ${model.id}: ${path ?? 'FAILED'}');
    return path == null ? null : model.copyWith(imageStoragePath: path);
  }

  /// Uploads the photo and returns the recipe that names it, awaiting the
  /// upload rather than letting it run behind.
  ///
  /// Sharing is the one path that cannot tolerate the fire-and-forget above: a
  /// recipe shared in the seconds after its photo was picked would be published
  /// with `imageStoragePath` still null, and the copy the other account gets
  /// would be permanently pictureless — the upload finishing afterwards does
  /// not go back and fix what was already sent.
  @override
  Future<RecipeEntity> readyForSharing(
    RecipeEntity recipe, {
    bool persist = true,
  }) async {
    final model = recipe.toModel();
    final uploaded = await _uploadImage(model);
    if (uploaded == null) return recipe;

    if (persist) {
      await localDataSource.saveRecipe(uploaded);
      unawaited(cloud?.push(uploaded) ?? Future.value());
    }
    return uploaded.toEntity();
  }

  @override
  Future<void> deleteRecipe(String id) async {
    // Read before the delete, so the photo it points at can go too — otherwise
    // every deleted recipe leaves its picture in the bucket, billed forever
    // with nothing left that can reach it.
    final doomed = await localDataSource.getRecipeById(id);
    await localDataSource.deleteRecipe(id);
    unawaited(cloud?.remove(id) ?? Future.value());
    unawaited(
      images?.remove(doomed?.imageStoragePath, uid: UserScope().uid) ??
          Future.value(),
    );
  }

  /// Marks a record with the language it is being written in, and moves its
  /// version on when the words actually changed. Translations made from the
  /// old wording then stop matching and are made again; a save that only
  /// touched a photo or a tag leaves them alone.
  Future<RecipeEntity> _stamped(RecipeEntity recipe) async {
    final previous = (await localDataSource.getRecipeById(
      recipe.id,
    ))?.toEntity();
    final edited = previous == null || _words(previous) != _words(recipe);
    if (!edited && recipe.contentLang != null) return recipe;
    return recipe.copyWith(
      contentLang: currentContentLanguage().code,
      contentVersion: edited && previous != null
          ? previous.contentVersion + 1
          : recipe.contentVersion,
    );
  }

  static String _words(RecipeEntity r) => [
    r.title,
    for (final i in r.ingredients) i.name,
    ...r.steps,
  ].join('\n');
}
