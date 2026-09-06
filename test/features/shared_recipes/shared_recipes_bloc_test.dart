import 'dart:async';

import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/repositories/recipes_repository.dart';
import 'package:easy_plate/features/my_recipes/domain/usecases/get_recipes_usecase.dart';
import 'package:easy_plate/features/my_recipes/domain/usecases/save_recipe_usecase.dart';
import 'package:easy_plate/features/shared_recipes/domain/entities/shared_recipe_entity.dart';
import 'package:easy_plate/features/shared_recipes/domain/repositories/shared_recipes_repository.dart';
import 'package:easy_plate/features/shared_recipes/domain/usecases/get_shared_recipes_usecase.dart';
import 'package:easy_plate/features/shared_recipes/domain/usecases/share_recipe_usecase.dart';
import 'package:easy_plate/features/shared_recipes/domain/usecases/toggle_shared_recipe_like_usecase.dart';
import 'package:easy_plate/features/shared_recipes/domain/usecases/unshare_recipe_usecase.dart';
import 'package:easy_plate/features/shared_recipes/domain/usecases/update_shared_recipe_usecase.dart';
import 'package:easy_plate/features/shared_recipes/presentation/bloc/shared_recipes_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSharedRepository implements SharedRecipesRepository {
  List<SharedRecipeEntity> feed = [];
  bool feedThrows = false;
  int feedCalls = 0;
  bool likeThrows = false;
  int likeCalls = 0;
  final unshared = <String>[];

  @override
  Future<List<SharedRecipeEntity>> getFeed({required String viewerUid, int limit = 50}) async {
    feedCalls++;
    if (feedThrows) throw Exception('offline');
    return feed;
  }

  @override
  Future<SharedRecipeEntity?> getById(String id, {required String viewerUid}) async =>
      feed.where((r) => r.id == id).firstOrNull;

  @override
  Future<bool> toggleLike(String id, {required String viewerUid}) async {
    likeCalls++;
    if (likeThrows) throw Exception('offline');
    return true;
  }

  @override
  Future<void> unshare(String id) async => unshared.add(id);

  final updated = <String, RecipeEntity>{};

  @override
  Future<void> updateShared(String id, RecipeEntity recipe) async =>
      updated[id] = recipe;

  @override
  Future<void> share(
    RecipeEntity recipe, {
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
  }) async {}
}

class _FakeRecipesRepository implements RecipesRepository {
  final saved = <RecipeEntity>[];

  @override
  Future<List<RecipeEntity>> getRecipes() async => saved;

  @override
  Future<void> saveRecipe(RecipeEntity recipe) async => saved.add(recipe);

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

SharedRecipeEntity buildShared({
  String id = 's1',
  int likeCount = 3,
  bool likedByMe = false,
}) =>
    SharedRecipeEntity(
      id: id,
      authorUid: 'someone',
      authorName: 'דנה',
      createdAt: DateTime(2026, 1, 1),
      likeCount: likeCount,
      likedByMe: likedByMe,
      recipe: RecipeEntity(
        id: id,
        title: 'שקשוקה',
        ingredients: const [],
        steps: const ['ערבוב'],
        createdAt: DateTime(2026, 1, 1),
      ),
    );

void main() {
  late _FakeSharedRepository shared;
  late _FakeRecipesRepository recipes;

  SharedRecipesBloc buildBloc() => SharedRecipesBloc(
        getSharedRecipesUseCase: GetSharedRecipesUseCase(shared),
        shareRecipeUseCase: ShareRecipeUseCase(shared),
        toggleLikeUseCase: ToggleSharedRecipeLikeUseCase(shared),
        unshareRecipeUseCase: UnshareRecipeUseCase(shared),
        updateSharedRecipeUseCase: UpdateSharedRecipeUseCase(shared),
        saveRecipeUseCase: SaveRecipeUseCase(recipes),
        getRecipesUseCase: GetRecipesUseCase(recipes),
        recipesRepository: recipes,
      );

  setUp(() {
    shared = _FakeSharedRepository();
    recipes = _FakeRecipesRepository();
  });

  test('loads the feed on construction', () async {
    shared.feed = [buildShared()];
    final bloc = buildBloc();
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state, isA<SharedRecipesLoaded>());
    expect((bloc.state as SharedRecipesLoaded).recipes, hasLength(1));
  });

  group('pull to refresh', () {
    test('re-reads the feed and completes the indicator\'s future', () async {
      shared.feed = [buildShared(id: 's1')];
      final bloc = buildBloc();
      await Future<void>.delayed(Duration.zero);
      final callsBefore = shared.feedCalls;

      shared.feed = [buildShared(id: 's1'), buildShared(id: 's2')];
      final done = Completer<void>();
      bloc.add(SharedRecipesEvent.refresh(done));
      await done.future;

      expect(shared.feedCalls, callsBefore + 1);
      expect((bloc.state as SharedRecipesLoaded).recipes, hasLength(2));
    });

    test('completes even when the reloaded data is identical', () async {
      // The reason refresh carries a completer at all: bloc skips emitting a
      // state equal to the current one, so a future derived from the state
      // stream would never resolve here and the spinner would hang forever.
      shared.feed = [buildShared(id: 's1')];
      final bloc = buildBloc();
      await Future<void>.delayed(Duration.zero);

      final done = Completer<void>();
      bloc.add(SharedRecipesEvent.refresh(done));

      await done.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => fail('refresh future never completed'),
      );
    });

    test('completes even when the reload fails', () async {
      shared.feed = [buildShared(id: 's1')];
      final bloc = buildBloc();
      await Future<void>.delayed(Duration.zero);

      // A spinner left turning after a failed refresh is worse than the error.
      shared.feedThrows = true;
      final done = Completer<void>();
      bloc.add(SharedRecipesEvent.refresh(done));

      await done.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => fail('refresh future never completed'),
      );
      expect(bloc.state, isA<SharedRecipesError>());
    });
  });

  test('liking flips the row and bumps the count before the write lands', () async {
    shared.feed = [buildShared(likeCount: 3, likedByMe: false)];
    final bloc = buildBloc();
    await Future<void>.delayed(Duration.zero);

    bloc.add(const SharedRecipesEvent.toggleLike('s1'));
    await Future<void>.delayed(Duration.zero);

    final row = (bloc.state as SharedRecipesLoaded).recipes.single;
    expect(row.likedByMe, isTrue);
    expect(row.likeCount, 4);
  });

  test('unliking a liked row steps the count back down', () async {
    shared.feed = [buildShared(likeCount: 3, likedByMe: true)];
    final bloc = buildBloc();
    await Future<void>.delayed(Duration.zero);

    bloc.add(const SharedRecipesEvent.toggleLike('s1'));
    await Future<void>.delayed(Duration.zero);

    final row = (bloc.state as SharedRecipesLoaded).recipes.single;
    expect(row.likedByMe, isFalse);
    expect(row.likeCount, 2);
  });

  test('a failed like is rolled back rather than left showing a lie', () async {
    shared.feed = [buildShared(likeCount: 3, likedByMe: false)];
    shared.likeThrows = true;
    final bloc = buildBloc();
    await Future<void>.delayed(Duration.zero);

    bloc.add(const SharedRecipesEvent.toggleLike('s1'));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final row = (bloc.state as SharedRecipesLoaded).recipes.single;
    expect(shared.likeCalls, 1);
    expect(row.likedByMe, isFalse);
    expect(row.likeCount, 3);
  });

  test('importing saves a copy under a fresh id, not the shared one', () async {
    shared.feed = [buildShared()];
    final bloc = buildBloc();
    await Future<void>.delayed(Duration.zero);

    bloc.add(SharedRecipesEvent.importToMyRecipes(shared.feed.single));
    await Future<void>.delayed(Duration.zero);

    expect(recipes.saved, hasLength(1));
    final copy = recipes.saved.single;
    expect(copy.title, 'שקשוקה');
    expect(copy.steps, ['ערבוב']);
    expect(copy.id, isNot('s1'), reason: 'a copy must not collide with the shared original');
  });

  test('editing a shared recipe replaces the row in place', () async {
    shared.feed = [buildShared(id: 's1', likeCount: 7, likedByMe: true)];
    final bloc = buildBloc();
    await Future<void>.delayed(Duration.zero);

    final edited = RecipeEntity(
      id: 's1',
      title: 'שקשוקה חריפה',
      ingredients: const [],
      steps: const ['ערבוב', 'בישול'],
      createdAt: DateTime(2026, 1, 1),
    );
    bloc.add(SharedRecipesEvent.updateShared('s1', edited));
    await Future<void>.delayed(Duration.zero);

    expect(shared.updated['s1']?.title, 'שקשוקה חריפה');
    final row = (bloc.state as SharedRecipesLoaded).recipes.single;
    expect(row.recipe.title, 'שקשוקה חריפה');
    expect(row.recipe.steps, ['ערבוב', 'בישול']);
    // The edit must not disturb what the post already accumulated.
    expect(row.likeCount, 7);
    expect(row.likedByMe, isTrue);
    expect(row.authorUid, 'someone');
  });

  test('a saved recipe is reported back so the feed can mark it', () async {
    shared.feed = [buildShared(id: 's1'), buildShared(id: 's2')];
    final bloc = buildBloc();
    await Future<void>.delayed(Duration.zero);
    expect((bloc.state as SharedRecipesLoaded).savedIds, isEmpty);

    bloc.add(SharedRecipesEvent.importToMyRecipes(shared.feed.first));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    // Read back off the local copy's savedFromSharedId, not tracked separately.
    expect(recipes.saved.single.savedFromSharedId, 's1');
    expect((bloc.state as SharedRecipesLoaded).savedIds, {'s1'});
  });

  test('unsharing drops the row from the feed', () async {
    shared.feed = [buildShared(id: 's1'), buildShared(id: 's2')];
    final bloc = buildBloc();
    await Future<void>.delayed(Duration.zero);

    bloc.add(const SharedRecipesEvent.unshare('s1'));
    await Future<void>.delayed(Duration.zero);

    expect(shared.unshared, ['s1']);
    expect((bloc.state as SharedRecipesLoaded).recipes.map((r) => r.id), ['s2']);
  });
}
