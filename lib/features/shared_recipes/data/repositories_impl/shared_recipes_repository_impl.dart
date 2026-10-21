import 'package:flutter/foundation.dart';

import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../user_profile/domain/entities/public_profile_entity.dart';
import '../../../user_profile/domain/repositories/user_profile_repository.dart';
import '../../domain/entities/shared_recipe_entity.dart';
import '../../domain/repositories/shared_recipes_repository.dart';
import '../datasources/shared_recipes_remote_datasource.dart';

class SharedRecipesRepositoryImpl implements SharedRecipesRepository {
  final SharedRecipesRemoteDataSource remoteDataSource;

  /// Used to resolve author display info at read time. Each document still
  /// stores the name it was published with, but only as a fallback for authors
  /// whose public profile is missing — a live read is what makes a rename show
  /// up on old posts.
  final UserProfileRepository userProfileRepository;

  SharedRecipesRepositoryImpl({
    required this.remoteDataSource,
    required this.userProfileRepository,
  });

  Future<List<SharedRecipeEntity>> _withLiveAuthors(
    List<SharedRecipeEntity> recipes, {
    bool refresh = false,
  }) async {
    if (recipes.isEmpty) return recipes;

    final Map<String, PublicProfileEntity> profiles;
    try {
      profiles = await userProfileRepository.getPublicProfiles(
        recipes.map((r) => r.authorUid).toSet(),
        refresh: refresh,
      );
    } catch (e) {
      // Every post keeps the name it was published with: the feed shows
      // with those rather than failing whole over a name lookup.
      debugPrint('Author lookup failed: $e');
      return recipes;
    }

    return [
      for (final shared in recipes)
        if (profiles[shared.authorUid] case final profile?)
          shared.copyWith(
            authorName: profile.fullName,
            authorPhotoUrl: profile.photoUrl,
          )
        else
          shared,
    ];
  }

  @override
  Future<List<SharedRecipeEntity>> getFeed({
    required String viewerUid,
    int limit = 50,
    bool refresh = false,
  }) async {
    return _withLiveAuthors(
      await remoteDataSource.getFeed(
        viewerUid: viewerUid,
        limit: limit,
        refresh: refresh,
      ),
      refresh: refresh,
    );
  }

  @override
  Future<List<SharedRecipeEntity>> getByAuthor(
    String authorUid, {
    int limit = 200,
  }) => remoteDataSource.getByAuthor(authorUid, limit: limit);

  @override
  Future<List<SharedRecipeEntity>> getMine({
    required String viewerUid,
    int limit = 200,
    bool refresh = false,
  }) async => _withLiveAuthors(
    await remoteDataSource.getMine(
      viewerUid: viewerUid,
      limit: limit,
      refresh: refresh,
    ),
    refresh: refresh,
  );

  @override
  Future<List<SharedRecipeEntity>> getByIds(
    Set<String> ids, {
    required String viewerUid,
    bool refresh = false,
  }) async => _withLiveAuthors(
    await remoteDataSource.getByIds(
      ids,
      viewerUid: viewerUid,
      refresh: refresh,
    ),
    refresh: refresh,
  );

  @override
  Future<SharedRecipeEntity?> getById(
    String id, {
    required String viewerUid,
  }) async {
    final shared = await remoteDataSource.getById(id, viewerUid: viewerUid);
    if (shared == null) return null;
    return (await _withLiveAuthors([shared])).single;
  }

  @override
  Future<String> share(
    RecipeEntity recipe, {
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
  }) => remoteDataSource.share(
    recipe,
    authorUid: authorUid,
    authorName: authorName,
    authorPhotoUrl: authorPhotoUrl,
  );

  @override
  Future<bool> toggleLike(String sharedRecipeId, {required String viewerUid}) =>
      remoteDataSource.toggleLike(sharedRecipeId, viewerUid: viewerUid);

  @override
  Future<void> updateShared(String sharedRecipeId, RecipeEntity recipe) =>
      remoteDataSource.updateShared(sharedRecipeId, recipe);

  @override
  Future<void> unshare(String sharedRecipeId) =>
      remoteDataSource.unshare(sharedRecipeId);
}
