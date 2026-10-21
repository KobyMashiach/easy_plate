import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../community/data/doc_fields.dart';
import '../../../my_recipes/domain/entities/nutrition_entity.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/entities/recipe_ingredient_entity.dart';
import '../../domain/entities/shared_recipe_entity.dart';

abstract class SharedRecipesRemoteDataSource {
  /// [refresh] (pull to refresh) reads the viewer's likes again instead of
  /// trusting the session cache, so a like given on another device shows.
  Future<List<SharedRecipeEntity>> getFeed({
    required String viewerUid,
    int limit = 50,
    bool refresh = false,
  });
  Future<SharedRecipeEntity?> getById(String id, {required String viewerUid});
  Future<List<SharedRecipeEntity>> getByAuthor(
    String authorUid, {
    int limit = 200,
  });

  /// The viewer's own posts with `likedByMe` resolved — the "mine" scope,
  /// which the newest-first window alone would cut short.
  Future<List<SharedRecipeEntity>> getMine({
    required String viewerUid,
    int limit = 200,
    bool refresh = false,
  });

  /// The posts among [ids] that still exist, in no particular order — the
  /// "saved" scope's posts older than the newest-first window.
  Future<List<SharedRecipeEntity>> getByIds(
    Set<String> ids, {
    required String viewerUid,
    bool refresh = false,
  });
  Future<String> share(
    RecipeEntity recipe, {
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
  });
  Future<bool> toggleLike(String sharedRecipeId, {required String viewerUid});
  Future<void> updateShared(String sharedRecipeId, RecipeEntity recipe);
  Future<void> unshare(String sharedRecipeId);
}

class SharedRecipesFirestoreDataSource
    implements SharedRecipesRemoteDataSource {
  static const collection = 'shared_recipes';
  static const _likes = 'likes';
  static const _uuid = Uuid();

  /// A batch takes 500 writes; a little under, per commit.
  static const _batchLimit = 450;

  /// `whereIn` takes at most 30 values per query.
  static const _idChunk = 30;

  final FirebaseFirestore _firestore;

  /// Whether the viewer has liked a post, keyed by `postId/viewerUid` so two
  /// accounts on one device never read each other's hearts.
  ///
  /// A like is a document named after the liker with nothing else in it —
  /// no uid or post id field a collection-group query could filter on — so
  /// the lookups cannot be batched. Instead each row is looked up once per
  /// session; a like given through [toggleLike] updates the entry, so a
  /// reload costs reads only for posts not seen before.
  final _viewerLikes = <String, bool>{};

  SharedRecipesFirestoreDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _root =>
      _firestore.collection(collection);

  @override
  Future<List<SharedRecipeEntity>> getFeed({
    required String viewerUid,
    int limit = 50,
    bool refresh = false,
  }) async {
    final snapshot = await _root
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return _withLikes(snapshot.docs, viewerUid, refresh: refresh);
  }

  /// Rows with the viewer's like resolved: from [_viewerLikes] when known,
  /// otherwise one lookup per row (only this viewer's like, never every one).
  /// [refresh] looks every row up again: the cache only follows likes given
  /// on this device.
  Future<List<SharedRecipeEntity>> _withLikes(
    List<DocumentSnapshot<Map<String, dynamic>>> docs,
    String viewerUid, {
    bool refresh = false,
  }) async {
    final liked = await Future.wait([
      for (final doc in docs)
        if (_viewerLikes['${doc.id}/$viewerUid'] case final known?
            when !refresh)
          Future.value(known)
        else
          doc.reference.collection(_likes).doc(viewerUid).get().then(
            (like) {
              _viewerLikes['${doc.id}/$viewerUid'] = like.exists;
              return like.exists;
            },
            // One row's lookup failing (offline, on a post not seen
            // before) must not fail the whole feed: the row shows what
            // was last known, or not liked, and is asked again next time.
            onError: (Object _) =>
                _viewerLikes['${doc.id}/$viewerUid'] ?? false,
          ),
    ]);
    return parseEach(
      [for (var i = 0; i < docs.length; i++) i],
      (i) => _toEntity(docs[i], likedByMe: liked[i]),
      label: 'Shared recipes',
    );
  }

  @override
  Future<List<SharedRecipeEntity>> getMine({
    required String viewerUid,
    int limit = 200,
    bool refresh = false,
  }) async {
    final snapshot = await _root
        .where('authorUid', isEqualTo: viewerUid)
        .limit(limit)
        .get();
    return _withLikes(snapshot.docs, viewerUid, refresh: refresh);
  }

  @override
  Future<List<SharedRecipeEntity>> getByIds(
    Set<String> ids, {
    required String viewerUid,
    bool refresh = false,
  }) async {
    if (ids.isEmpty) return const [];
    final list = ids.toList();
    final snapshots = await Future.wait([
      for (var i = 0; i < list.length; i += _idChunk)
        _root
            .where(
              FieldPath.documentId,
              whereIn: list.sublist(
                i,
                i + _idChunk > list.length ? list.length : i + _idChunk,
              ),
            )
            .get(),
    ]);
    return _withLikes(
      [for (final snapshot in snapshots) ...snapshot.docs],
      viewerUid,
      refresh: refresh,
    );
  }

  @override
  Future<List<SharedRecipeEntity>> getByAuthor(
    String authorUid, {
    int limit = 200,
  }) async {
    // Equality on one field: no composite index needed, and no ordering so
    // none is needed for that either.
    final snapshot = await _root
        .where('authorUid', isEqualTo: authorUid)
        .limit(limit)
        .get();
    return parseEach(
      snapshot.docs,
      (doc) => _toEntity(doc, likedByMe: false),
      label: 'Shared recipes by author',
    );
  }

  /// Null when the recipe has been unshared since the link to it was posted.
  @override
  Future<SharedRecipeEntity?> getById(
    String id, {
    required String viewerUid,
  }) async {
    final doc = await _root.doc(id).get();
    if (!doc.exists) return null;
    final liked = await doc.reference.collection(_likes).doc(viewerUid).get();
    _viewerLikes['$id/$viewerUid'] = liked.exists;
    return _toEntity(doc, likedByMe: liked.exists);
  }

  SharedRecipeEntity _toEntity(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required bool likedByMe,
  }) {
    final data = doc.data() ?? const <String, dynamic>{};
    final ingredients = docMaps(data['ingredients'])
        .map(
          (raw) => RecipeIngredientEntity(
            name: docString(raw['name']),
            amount: docDouble(raw['amount']),
            unit: MeasurementUnit.values.firstWhere(
              (u) => u.name == raw['unit'],
              orElse: () => MeasurementUnit.unspecified,
            ),
          ),
        )
        .toList();

    final createdAt = docDate(data['createdAt']) ?? DateTime.now();

    return SharedRecipeEntity(
      id: doc.id,
      authorUid: docString(data['authorUid']),
      authorName: docString(data['authorName']),
      authorPhotoUrl: docNonEmpty(data['authorPhotoUrl']),
      createdAt: createdAt,
      likeCount: docInt(data['likeCount']) ?? 0,
      likedByMe: likedByMe,
      recipe: RecipeEntity(
        // The feed id doubles as the recipe id; importing re-keys it so a saved
        // copy never collides with the shared original.
        id: doc.id,
        title: docString(data['title']),
        prepTimeMinutes: docInt(data['prepTimeMinutes']),
        cookTimeMinutes: docInt(data['cookTimeMinutes']),
        ingredients: ingredients,
        steps: docList(data['steps']).whereType<String>().toList(),
        dietaryTags: docList(data['dietaryTags'])
            .whereType<String>()
            .map(
              (name) => DietaryPreference.values
                  .where((d) => d.name == name)
                  .firstOrNull,
            )
            .nonNulls
            .toList(),
        allergens: Allergen.fromNames(data['allergens']),
        mayContain: Allergen.fromNames(data['mayContain']),
        imageFileName: docStringOrNull(data['imageFileName']),
        imageStoragePath: docStringOrNull(data['imageStoragePath']),
        servings: docInt(data['servings']),
        nutrition: docOrNull(() => NutritionEntity.fromJson(data['nutrition'])),
        createdAt: createdAt,
      ),
    );
  }

  @override
  Future<String> share(
    RecipeEntity recipe, {
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
  }) async {
    final id = _uuid.v4();
    await _root.doc(id).set({
      // Which local recipe this post came from, so the author's later edits
      // can find it.
      'sourceRecipeId': recipe.id,
      'title': recipe.title,
      'prepTimeMinutes': recipe.prepTimeMinutes,
      'cookTimeMinutes': recipe.cookTimeMinutes,
      'ingredients': [
        for (final i in recipe.ingredients)
          {'name': i.name, 'amount': i.amount, 'unit': i.unit.name},
      ],
      'steps': recipe.steps,
      'dietaryTags': [for (final tag in recipe.dietaryTags) tag.name],
      'allergens': recipe.allergens.names,
      'mayContain': recipe.mayContain.names,
      // The picture, as a Storage path plus the name to cache it under. The
      // feed used to show the author's avatar but never the dish.
      'imageFileName': recipe.imageFileName,
      'imageStoragePath': recipe.imageStoragePath,
      'servings': recipe.servings,
      'nutrition': recipe.nutrition?.toJson(),
      'authorUid': authorUid,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'likeCount': 0,
      'createdAt': Timestamp.now(),
    });
    return id;
  }

  /// The per-user like document and the denormalised counter have to move
  /// together, or a double tap inflates the count.
  @override
  Future<bool> toggleLike(
    String sharedRecipeId, {
    required String viewerUid,
  }) async {
    final post = _root.doc(sharedRecipeId);
    final like = post.collection(_likes).doc(viewerUid);

    final liked = await _firestore.runTransaction<bool>((transaction) async {
      final existing = await transaction.get(like);
      if (existing.exists) {
        transaction.delete(like);
        transaction.update(post, {'likeCount': FieldValue.increment(-1)});
        return false;
      }
      transaction.set(like, {'createdAt': Timestamp.now()});
      transaction.update(post, {'likeCount': FieldValue.increment(1)});
      return true;
    });
    _viewerLikes['$sharedRecipeId/$viewerUid'] = liked;
    return liked;
  }

  /// Only the recipe's own fields move. The author, the created date and the
  /// like counter are left alone — the rules reject a write that touches them.
  @override
  Future<void> updateShared(String sharedRecipeId, RecipeEntity recipe) {
    return _root.doc(sharedRecipeId).update({
      'title': recipe.title,
      'prepTimeMinutes': recipe.prepTimeMinutes,
      'cookTimeMinutes': recipe.cookTimeMinutes,
      'ingredients': [
        for (final i in recipe.ingredients)
          {'name': i.name, 'amount': i.amount, 'unit': i.unit.name},
      ],
      'steps': recipe.steps,
      'dietaryTags': [for (final tag in recipe.dietaryTags) tag.name],
      'allergens': recipe.allergens.names,
      'mayContain': recipe.mayContain.names,
      'imageFileName': recipe.imageFileName,
      'imageStoragePath': recipe.imageStoragePath,
      'servings': recipe.servings,
      'nutrition': recipe.nutrition?.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Firestore does not cascade, so the per-user like documents have to go
  /// explicitly or they linger as unreachable — and still billed — storage.
  @override
  Future<void> unshare(String sharedRecipeId) async {
    final post = _root.doc(sharedRecipeId);
    final likes = await post.collection(_likes).get();
    // A well-liked post has more likes than one batch holds. The post goes
    // in the last batch, so a failure part-way leaves it standing (with
    // fewer likes) rather than orphaning what remains.
    final refs = [for (final like in likes.docs) like.reference, post];
    for (var i = 0; i < refs.length; i += _batchLimit) {
      final batch = _firestore.batch();
      for (final ref in refs.skip(i).take(_batchLimit)) {
        batch.delete(ref);
      }
      await batch.commit();
    }
  }
}
