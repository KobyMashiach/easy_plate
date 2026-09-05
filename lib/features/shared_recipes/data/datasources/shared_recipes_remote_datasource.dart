import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/entities/recipe_ingredient_entity.dart';
import '../../domain/entities/shared_recipe_entity.dart';

abstract class SharedRecipesRemoteDataSource {
  Future<List<SharedRecipeEntity>> getFeed({required String viewerUid, int limit = 50});
  Future<void> share(
    RecipeEntity recipe, {
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
  });
  Future<bool> toggleLike(String sharedRecipeId, {required String viewerUid});
  Future<void> unshare(String sharedRecipeId);
}

class SharedRecipesFirestoreDataSource implements SharedRecipesRemoteDataSource {
  static const collection = 'shared_recipes';
  static const _likes = 'likes';
  static const _uuid = Uuid();

  final FirebaseFirestore _firestore;

  SharedRecipesFirestoreDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _root => _firestore.collection(collection);

  @override
  Future<List<SharedRecipeEntity>> getFeed({required String viewerUid, int limit = 50}) async {
    final snapshot = await _root.orderBy('createdAt', descending: true).limit(limit).get();

    // One like lookup per row rather than a read of every like: the feed only
    // needs to know about this viewer.
    final liked = await Future.wait(
      snapshot.docs.map((doc) => doc.reference.collection(_likes).doc(viewerUid).get()),
    );

    return [
      for (var i = 0; i < snapshot.docs.length; i++)
        _toEntity(snapshot.docs[i], likedByMe: liked[i].exists),
    ];
  }

  SharedRecipeEntity _toEntity(
    QueryDocumentSnapshot<Map<String, dynamic>> doc, {
    required bool likedByMe,
  }) {
    final data = doc.data();
    final ingredients = ((data['ingredients'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((raw) => RecipeIngredientEntity(
              name: (raw['name'] as String?) ?? '',
              amount: (raw['amount'] as num?)?.toDouble(),
              unit: MeasurementUnit.values.firstWhere(
                (u) => u.name == raw['unit'],
                orElse: () => MeasurementUnit.unspecified,
              ),
            ))
        .toList();

    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    return SharedRecipeEntity(
      id: doc.id,
      authorUid: (data['authorUid'] as String?) ?? '',
      authorName: (data['authorName'] as String?) ?? '',
      authorPhotoUrl: data['authorPhotoUrl'] as String?,
      createdAt: createdAt,
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      likedByMe: likedByMe,
      recipe: RecipeEntity(
        // The feed id doubles as the recipe id; importing re-keys it so a saved
        // copy never collides with the shared original.
        id: doc.id,
        title: (data['title'] as String?) ?? '',
        prepTimeMinutes: (data['prepTimeMinutes'] as num?)?.toInt(),
        cookTimeMinutes: (data['cookTimeMinutes'] as num?)?.toInt(),
        ingredients: ingredients,
        steps: ((data['steps'] as List?) ?? const []).whereType<String>().toList(),
        dietaryTags: ((data['dietaryTags'] as List?) ?? const [])
            .whereType<String>()
            .map((name) => DietaryPreference.values.where((d) => d.name == name).firstOrNull)
            .nonNulls
            .toList(),
        createdAt: createdAt,
      ),
    );
  }

  @override
  Future<void> share(
    RecipeEntity recipe, {
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
  }) {
    return _root.doc(_uuid.v4()).set({
      'title': recipe.title,
      'prepTimeMinutes': recipe.prepTimeMinutes,
      'cookTimeMinutes': recipe.cookTimeMinutes,
      'ingredients': [
        for (final i in recipe.ingredients)
          {'name': i.name, 'amount': i.amount, 'unit': i.unit.name},
      ],
      'steps': recipe.steps,
      'dietaryTags': [for (final tag in recipe.dietaryTags) tag.name],
      'authorUid': authorUid,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'likeCount': 0,
      'createdAt': Timestamp.now(),
    });
  }

  /// The per-user like document and the denormalised counter have to move
  /// together, or a double tap inflates the count.
  @override
  Future<bool> toggleLike(String sharedRecipeId, {required String viewerUid}) {
    final post = _root.doc(sharedRecipeId);
    final like = post.collection(_likes).doc(viewerUid);

    return _firestore.runTransaction<bool>((transaction) async {
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
  }

  /// Firestore does not cascade, so the per-user like documents have to go
  /// explicitly or they linger as unreachable — and still billed — storage.
  @override
  Future<void> unshare(String sharedRecipeId) async {
    final post = _root.doc(sharedRecipeId);
    final likes = await post.collection(_likes).get();

    final batch = _firestore.batch();
    for (final like in likes.docs) {
      batch.delete(like.reference);
    }
    batch.delete(post);
    await batch.commit();
  }
}
