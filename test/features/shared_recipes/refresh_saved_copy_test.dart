import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/nutrition_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/repositories/recipes_repository.dart';
import 'package:easy_plate/features/recipe_sharing/domain/repositories/recipe_sharing_repository.dart';
import 'package:easy_plate/features/shared_recipes/domain/entities/shared_recipe_entity.dart';
import 'package:easy_plate/features/shared_recipes/domain/repositories/shared_recipes_repository.dart';
import 'package:easy_plate/features/shared_recipes/domain/usecases/refresh_saved_copy_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _Shared implements SharedRecipesRepository {
  SharedRecipeEntity? post;
  @override
  Future<SharedRecipeEntity?> getById(
    String id, {
    required String viewerUid,
  }) async => post;
  @override
  noSuchMethod(Invocation i) => throw UnimplementedError('${i.memberName}');
}

class _Recipes implements RecipesRepository {
  final List<RecipeEntity> stored;
  RecipeEntity? saved;
  bool? stamped;
  _Recipes(this.stored);
  @override
  Future<List<RecipeEntity>> getRecipes() async => stored;
  @override
  Future<void> saveRecipe(
    RecipeEntity recipe, {
    bool stampLanguage = true,
  }) async {
    saved = recipe;
    stamped = stampLanguage;
  }

  @override
  Future<RecipeEntity> readyForSharing(
    RecipeEntity recipe, {
    bool persist = true,
  }) async => recipe;
  @override
  noSuchMethod(Invocation i) => throw UnimplementedError('${i.memberName}');
}

class _Sharing implements RecipeSharingRepository {
  final written = <String>[];
  Object? writeError;
  @override
  Future<void> writeCollab(
    String collabId,
    RecipeEntity recipe, {
    required String byUid,
  }) async {
    if (writeError case final e?) throw e;
    written.add('$collabId:$byUid:${recipe.title}');
  }

  @override
  noSuchMethod(Invocation i) => throw UnimplementedError('${i.memberName}');
}

void main() {
  final local = RecipeEntity(
    id: 'local-1',
    title: 'ישן',
    ingredients: const [],
    steps: const ['א'],
    createdAt: DateTime(2026, 1, 1),
    savedFromSharedId: 'post-1',
  );
  final newer = RecipeEntity(
    id: 'post-1',
    title: 'חדש',
    ingredients: const [],
    steps: const ['א', 'ב'],
    createdAt: DateTime(2026, 2, 1),
    servings: 4,
    nutrition: const NutritionEntity(
      calories: 300,
      proteinGrams: 1,
      carbsGrams: 2,
      fatGrams: 3,
    ),
  );

  test('the copy takes the new content but keeps its own identity', () async {
    final shared = _Shared()
      ..post = SharedRecipeEntity(
        id: 'post-1',
        recipe: newer,
        authorUid: 'a',
        authorName: 'A',
        authorPhotoUrl: null,
        createdAt: DateTime(2026),
        likeCount: 0,
        likedByMe: false,
      );
    final recipes = _Recipes([local]);
    final result = await RefreshSavedCopyUseCase(
      shared: shared,
      recipes: recipes,
    )('post-1', viewerUid: 'me');
    expect(result, isNotNull);
    expect(recipes.saved!.id, 'local-1');
    expect(recipes.saved!.title, 'חדש');
    expect(recipes.saved!.steps.length, 2);
    expect(recipes.saved!.servings, 4);
    expect(recipes.saved!.savedFromSharedId, 'post-1');
    expect(recipes.saved!.createdAt, DateTime(2026, 1, 1));
  });

  test('a copy shared on in a book keeps its collab and source', () async {
    final inBook = RecipeEntity(
      id: 'local-1',
      title: 'ישן',
      ingredients: const [],
      steps: const ['א'],
      createdAt: DateTime(2026, 1, 1),
      savedFromSharedId: 'post-1',
      collabId: 'collab-9',
      collabRole: CollabRole.owner,
      sourceUrl: 'https://example.com/r',
    );
    final shared = _Shared()
      ..post = SharedRecipeEntity(
        id: 'post-1',
        recipe: newer,
        authorUid: 'a',
        authorName: 'A',
        authorPhotoUrl: null,
        createdAt: DateTime(2026),
        likeCount: 0,
        likedByMe: false,
      );
    final recipes = _Recipes([inBook]);
    await RefreshSavedCopyUseCase(shared: shared, recipes: recipes)(
      'post-1',
      viewerUid: 'me',
    );
    expect(recipes.saved!.title, 'חדש');
    expect(recipes.saved!.collabId, 'collab-9');
    expect(recipes.saved!.collabRole, CollabRole.owner);
    expect(recipes.saved!.sourceUrl, 'https://example.com/r');
  });

  group('a copy shared on', () {
    final post = SharedRecipeEntity(
      id: 'post-1',
      recipe: newer,
      authorUid: 'a',
      authorName: 'A',
      authorPhotoUrl: null,
      createdAt: DateTime(2026),
      likeCount: 0,
      likedByMe: false,
    );
    RecipeEntity inBook(CollabRole role) => RecipeEntity(
      id: 'local-1',
      title: 'ישן',
      ingredients: const [],
      steps: const ['א'],
      createdAt: DateTime(2026, 1, 1),
      savedFromSharedId: 'post-1',
      collabId: 'collab-9',
      collabRole: role,
    );

    test('publishes the new version to its document, then the copy', () async {
      final sharing = _Sharing();
      final recipes = _Recipes([inBook(CollabRole.owner)]);
      final result = await RefreshSavedCopyUseCase(
        shared: _Shared()..post = post,
        recipes: recipes,
        sharing: sharing,
      )('post-1', viewerUid: 'me');
      expect(sharing.written, ['collab-9:me:חדש']);
      expect(recipes.saved!.title, 'חדש');
      expect(recipes.saved!.collabId, 'collab-9');
      expect(result!.id, 'local-1');
    });

    test('a refused document write leaves the copy as it was', () async {
      final sharing = _Sharing()..writeError = StateError('permission-denied');
      final recipes = _Recipes([inBook(CollabRole.editor)]);
      await expectLater(
        RefreshSavedCopyUseCase(
          shared: _Shared()..post = post,
          recipes: recipes,
          sharing: sharing,
        )('post-1', viewerUid: 'me'),
        throwsA(isA<StateError>()),
      );
      expect(recipes.saved, isNull);
    });

    test('a viewer refreshes only its own cache', () async {
      final sharing = _Sharing();
      final recipes = _Recipes([inBook(CollabRole.viewer)]);
      await RefreshSavedCopyUseCase(
        shared: _Shared()..post = post,
        recipes: recipes,
        sharing: sharing,
      )('post-1', viewerUid: 'me');
      expect(sharing.written, isEmpty);
      expect(recipes.saved!.title, 'חדש');
    });

    test(
      'without a sharing repository the copy is refreshed locally',
      () async {
        final recipes = _Recipes([inBook(CollabRole.owner)]);
        await RefreshSavedCopyUseCase(
          shared: _Shared()..post = post,
          recipes: recipes,
        )('post-1', viewerUid: 'me');
        expect(recipes.saved!.title, 'חדש');
        expect(recipes.stamped, isTrue);
      },
    );
  });

  test('a post that is gone leaves the copy alone', () async {
    final recipes = _Recipes([local]);
    final result = await RefreshSavedCopyUseCase(
      shared: _Shared(),
      recipes: recipes,
    )('post-1', viewerUid: 'me');
    expect(result, isNull);
    expect(recipes.saved, isNull);
  });
}
