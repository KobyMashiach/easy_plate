import 'dart:async';

import 'package:easy_plate/core/hive/user_scope.dart';
import 'package:easy_plate/core/sync/recipe_image_store.dart';
import 'package:easy_plate/core/sync/user_cloud_collection.dart';
import 'package:easy_plate/features/my_recipes/data/datasources/recipes_local_datasource.dart';
import 'package:easy_plate/features/my_recipes/data/models/recipe_model.dart';
import 'package:easy_plate/features/my_recipes/data/repositories_impl/recipes_repository_impl.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:flutter_test/flutter_test.dart';

class _Local implements RecipesLocalDataSource {
  final Map<String, RecipeModel> store = {};
  @override
  Future<List<RecipeModel>> getRecipes() async => store.values.toList();
  @override
  Stream<List<RecipeModel>> watchRecipes() =>
      Stream.value(store.values.toList());
  @override
  Future<RecipeModel?> getRecipeById(String id) async => store[id];
  @override
  Future<void> saveRecipe(RecipeModel recipe) async =>
      store[recipe.id] = recipe;
  @override
  Future<void> deleteRecipe(String id) async => store.remove(id);
}

class _Images implements RecipeImageStore {
  String? result = 'recipe_images/u1/a.jpg';
  Completer<void>? gate;
  @override
  Future<String?> upload(String fileName, {required String uid}) async {
    if (gate != null) await gate!.future;
    return result;
  }

  final removed = <String?>[];
  @override
  Future<void> remove(String? storagePath, {required String? uid}) async =>
      removed.add(storagePath);
  @override
  Future<String?> ensureCached(String fileName, String storagePath) async =>
      null;
  @override
  void resetForTest() {}
}

class _Cloud implements UserCloudCollection<RecipeModel> {
  final pushed = <RecipeModel>[];
  @override
  Future<void> push(RecipeModel value) async => pushed.add(value);
  @override
  Future<void> remove(String id) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Pass 7: the website edits the same records. A write that awaited a photo
// upload must land on the record as it is then, not the one it started with.
void main() {
  late _Local local;
  late _Images images;
  late _Cloud cloud;
  late RecipesRepositoryImpl repository;

  final recipe = RecipeEntity(
    id: 'r1',
    title: 'Soup',
    ingredients: const [],
    steps: const ['Boil'],
    createdAt: DateTime(2026),
    imageFileName: 'a.jpg',
  );

  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  setUp(() async {
    await UserScope().switchTo('u1');
    local = _Local();
    images = _Images();
    cloud = _Cloud();
    repository = RecipesRepositoryImpl(
      localDataSource: local,
      cloud: cloud,
      images: images,
    );
  });
  tearDown(() => UserScope().resetForTest());

  test('a failed upload pushes the recipe as it is now', () async {
    images
      ..result = null
      ..gate = Completer<void>();
    await repository.saveRecipe(recipe);
    // Pulled in from the website while the photo travelled.
    local.store['r1'] = local.store['r1']!.copyWith(title: 'Web soup');
    images.gate!.complete();
    await settle();
    expect(cloud.pushed.last.title, 'Web soup');
  });

  test('a recipe deleted while the upload failed is not pushed back', () async {
    images
      ..result = null
      ..gate = Completer<void>();
    await repository.saveRecipe(recipe);
    local.store.remove('r1');
    images.gate!.complete();
    await settle();
    expect(cloud.pushed, isEmpty);
  });

  test('sharing writes only the storage path onto the stored recipe', () async {
    await local.saveRecipe(recipe.toModel());
    images.gate = Completer<void>();
    final ready = repository.readyForSharing(recipe);
    await settle();
    local.store['r1'] = local.store['r1']!.copyWith(title: 'Web soup');
    images.gate!.complete();
    final shared = await ready;
    expect(shared.imageStoragePath, 'recipe_images/u1/a.jpg');
    final stored = local.store['r1']!;
    expect(stored.title, 'Web soup');
    expect(stored.imageStoragePath, 'recipe_images/u1/a.jpg');
    await settle();
    expect(cloud.pushed.last.title, 'Web soup');
  });

  test(
    'deleting a published or shared recipe keeps its uploaded photo',
    () async {
      const path = 'recipe_images/u1/a.jpg';
      await local.saveRecipe(
        recipe
            .copyWith(imageStoragePath: path, sharedRecipeId: 'post')
            .toModel(),
      );
      await repository.deleteRecipe('r1');
      await local.saveRecipe(
        recipe
            .copyWith(imageStoragePath: path, collabId: 'c')
            .toModel()
            .copyWith(id: 'r2'),
      );
      await repository.deleteRecipe('r2');
      await settle();
      expect(images.removed, isEmpty);

      await local.saveRecipe(
        recipe.copyWith(imageStoragePath: path).toModel().copyWith(id: 'r3'),
      );
      await repository.deleteRecipe('r3');
      await settle();
      expect(images.removed, [path]);
    },
  );
}
