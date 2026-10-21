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
import 'package:easy_plate/features/shared_recipes/presentation/widgets/shared_feed_query.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSharedRepository implements SharedRecipesRepository {
  List<SharedRecipeEntity> feed = [];
  bool feedThrows = false;
  int feedCalls = 0;
  final feedRefresh = <bool>[];
  bool likeThrows = false;
  int likeCalls = 0;
  bool unshareThrows = false;
  final unshared = <String>[];

  @override
  Future<List<SharedRecipeEntity>> getFeed({
    required String viewerUid,
    int limit = 50,
    bool refresh = false,
  }) async {
    feedCalls++;
    feedRefresh.add(refresh);
    if (feedThrows) throw Exception('offline');
    return feed;
  }

  @override
  Future<SharedRecipeEntity?> getById(
    String id, {
    required String viewerUid,
  }) async => feed.where((r) => r.id == id).firstOrNull;

  @override
  Future<List<SharedRecipeEntity>> getByAuthor(
    String authorUid, {
    int limit = 200,
  }) async => feed.where((r) => r.authorUid == authorUid).toList();

  /// Posts outside the newest window, for the "mine" and "saved" scopes.
  List<SharedRecipeEntity> older = [];
  int mineCalls = 0;
  Completer<void>? mineGate;
  final idsAskedFor = <Set<String>>[];

  @override
  Future<List<SharedRecipeEntity>> getMine({
    required String viewerUid,
    int limit = 200,
    bool refresh = false,
  }) async {
    mineCalls++;
    await mineGate?.future;
    return [
      ...feed,
      ...older,
    ].where((r) => r.authorUid == viewerUid).toList();
  }

  @override
  Future<List<SharedRecipeEntity>> getByIds(
    Set<String> ids, {
    required String viewerUid,
    bool refresh = false,
  }) async {
    idsAskedFor.add(ids);
    return [...feed, ...older].where((r) => ids.contains(r.id)).toList();
  }

  @override
  Future<bool> toggleLike(String id, {required String viewerUid}) async {
    likeCalls++;
    if (likeThrows) throw Exception('offline');
    return true;
  }

  @override
  Future<void> unshare(String id) async {
    if (unshareThrows) throw Exception('offline');
    unshared.add(id);
  }

  final updated = <String, RecipeEntity>{};

  @override
  Future<void> updateShared(String id, RecipeEntity recipe) async =>
      updated[id] = recipe;

  @override
  Future<String> share(
    RecipeEntity recipe, {
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
  }) async => 'post-1';
}

class _FakeRecipesRepository implements RecipesRepository {
  final saved = <RecipeEntity>[];

  @override
  Future<List<RecipeEntity>> getRecipes() async => saved;

  @override
  Future<void> saveRecipe(
    RecipeEntity recipe, {
    bool stampLanguage = true,
  }) async => saved.add(recipe);

  /// Nothing to upload in a test, which is also what the real repository
  /// returns for a recipe with no photo. [persistAsked] records whether the
  /// caller wanted the recipe saved locally as well.
  final persistAsked = <bool>[];

  @override
  Future<RecipeEntity> readyForSharing(
    RecipeEntity recipe, {
    bool persist = true,
  }) async {
    persistAsked.add(persist);
    return recipe;
  }

  final changes = StreamController<List<RecipeEntity>>.broadcast();

  @override
  Stream<List<RecipeEntity>> watchRecipes() => changes.stream;

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

SharedRecipeEntity buildShared({
  String id = 's1',
  int likeCount = 3,
  bool likedByMe = false,
  String authorUid = 'someone',
}) => SharedRecipeEntity(
  id: id,
  authorUid: authorUid,
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
    shareRecipeUseCase: ShareRecipeUseCase(shared, recipes),
    toggleLikeUseCase: ToggleSharedRecipeLikeUseCase(shared),
    unshareRecipeUseCase: UnshareRecipeUseCase(shared),
    updateSharedRecipeUseCase: UpdateSharedRecipeUseCase(shared, recipes),
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
      // The first load trusts the caches; the pull reads past them, so a
      // like from another device shows.
      expect(shared.feedRefresh.first, isFalse);
      expect(shared.feedRefresh.last, isTrue);
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
      // The feed on screen stays, flagged for the page to say so.
      final state = bloc.state as SharedRecipesLoaded;
      expect(state.recipes, isNotEmpty);
      expect(state.notice, SharedFeedNotice.loadFailed);
    });
  });

  test(
    'liking flips the row and bumps the count before the write lands',
    () async {
      shared.feed = [buildShared(likeCount: 3, likedByMe: false)];
      final bloc = buildBloc();
      await Future<void>.delayed(Duration.zero);

      bloc.add(const SharedRecipesEvent.toggleLike('s1'));
      await Future<void>.delayed(Duration.zero);

      final row = (bloc.state as SharedRecipesLoaded).recipes.single;
      expect(row.likedByMe, isTrue);
      expect(row.likeCount, 4);
    },
  );

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
    expect(
      copy.id,
      isNot('s1'),
      reason: 'a copy must not collide with the shared original',
    );
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

  test('a removal that failed keeps the feed and flags it', () async {
    shared.feed = [buildShared()];
    shared.unshareThrows = true;
    final bloc = buildBloc();
    await Future<void>.delayed(Duration.zero);

    bloc.add(const SharedRecipesEvent.unshare('s1'));
    await Future<void>.delayed(const Duration(milliseconds: 5));

    var state = bloc.state as SharedRecipesLoaded;
    expect(state.recipes, hasLength(1));
    expect(state.notice, SharedFeedNotice.unshareFailed);

    bloc.add(const SharedRecipesEvent.dismissNotice());
    await Future<void>.delayed(Duration.zero);
    state = bloc.state as SharedRecipesLoaded;
    expect(state.notice, isNull);
  });

  test(
    'editing says so through the state and never saves the post as a recipe',
    () async {
      shared.feed = [buildShared()];
      final bloc = buildBloc();
      await Future<void>.delayed(Duration.zero);

      final edited = shared.feed.single.recipe.copyWith(title: 'שקשוקה חריפה');
      bloc.add(SharedRecipesEvent.updateShared('s1', edited));
      await Future<void>.delayed(const Duration(milliseconds: 5));

      final state = bloc.state as SharedRecipesLoaded;
      expect(state.notice, SharedFeedNotice.updated);
      expect(state.recipes.single.recipe.title, 'שקשוקה חריפה');
      expect(recipes.persistAsked, [false]);
      expect(recipes.saved, isEmpty);
    },
  );

  test('unsharing drops the row from the feed', () async {
    shared.feed = [buildShared(id: 's1'), buildShared(id: 's2')];
    final bloc = buildBloc();
    await Future<void>.delayed(Duration.zero);

    bloc.add(const SharedRecipesEvent.unshare('s1'));
    await Future<void>.delayed(Duration.zero);

    expect(shared.unshared, ['s1']);
    expect((bloc.state as SharedRecipesLoaded).recipes.map((r) => r.id), [
      's2',
    ]);
  });

  group('saved mark', () {
    test(
      'follows the local recipes: a removal on the recipes tab unmarks the row',
      () async {
        shared.feed = [buildShared(id: 's1')];
        recipes.saved.add(
          RecipeEntity(
            id: 'local',
            title: 'שקשוקה',
            ingredients: const [],
            steps: const [],
            savedFromSharedId: 's1',
            createdAt: DateTime(2026, 1, 1),
          ),
        );
        final bloc = buildBloc();
        await Future<void>.delayed(Duration.zero);
        expect((bloc.state as SharedRecipesLoaded).savedIds, {'s1'});

        // The box reports the recipe gone; nothing here was reloaded.
        recipes.changes.add(const []);
        await Future<void>.delayed(Duration.zero);

        expect((bloc.state as SharedRecipesLoaded).savedIds, isEmpty);
        await bloc.close();
      },
    );
  });

  group('scopes past the newest window', () {
    RecipeEntity savedCopy(String sharedId) => RecipeEntity(
      id: 'local-$sharedId',
      title: 'שקשוקה',
      ingredients: const [],
      steps: const [],
      savedFromSharedId: sharedId,
      createdAt: DateTime(2026, 1, 1),
    );

    test('"all" fetches nothing beyond the feed', () async {
      shared.feed = [buildShared(id: 's1')];
      final bloc = buildBloc();
      await Future<void>.delayed(Duration.zero);

      bloc.add(const SharedRecipesEvent.scopeOpened(SharedFeedScope.all));
      await Future<void>.delayed(Duration.zero);

      expect(shared.mineCalls, 0);
      expect(shared.idsAskedFor, isEmpty);
      expect((bloc.state as SharedRecipesLoaded).older, isEmpty);
      await bloc.close();
    });

    test(
      'two quick opens of "mine" read once and list each post once',
      () async {
        shared.feed = [buildShared(id: 's1')];
        shared.older = [buildShared(id: 'old-mine', authorUid: '')];
        final bloc = buildBloc();
        await Future<void>.delayed(Duration.zero);

        shared.mineGate = Completer<void>();
        bloc.add(const SharedRecipesEvent.scopeOpened(SharedFeedScope.mine));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SharedRecipesEvent.scopeOpened(SharedFeedScope.all));
        bloc.add(const SharedRecipesEvent.scopeOpened(SharedFeedScope.mine));
        await Future<void>.delayed(Duration.zero);
        shared.mineGate!.complete();
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        expect(shared.mineCalls, 1);
        expect(
          (bloc.state as SharedRecipesLoaded).older.map((r) => r.id),
          ['old-mine'],
        );
        await bloc.close();
      },
    );

    test('"mine" reads the viewer\'s posts once per load', () async {
      // The viewer's uid is '' with no session in a test.
      shared.feed = [buildShared(id: 's1')];
      shared.older = [buildShared(id: 'old-mine', authorUid: '')];
      final bloc = buildBloc();
      await Future<void>.delayed(Duration.zero);

      bloc.add(const SharedRecipesEvent.scopeOpened(SharedFeedScope.mine));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const SharedRecipesEvent.scopeOpened(SharedFeedScope.mine));
      await Future<void>.delayed(Duration.zero);

      final state = bloc.state as SharedRecipesLoaded;
      expect(state.recipes.map((r) => r.id), ['s1']);
      expect(state.older.map((r) => r.id), ['old-mine']);
      expect(shared.mineCalls, 1);

      // A reload starts over, and re-reads for the scope still open.
      final done = Completer<void>();
      bloc.add(SharedRecipesEvent.refresh(done));
      await done.future;
      expect(shared.mineCalls, 2);
      expect((bloc.state as SharedRecipesLoaded).older, hasLength(1));
      await bloc.close();
    });

    test('"saved" asks only for saved ids the window does not hold', () async {
      shared.feed = [buildShared(id: 's1')];
      shared.older = [buildShared(id: 'old-saved')];
      recipes.saved
        ..add(savedCopy('s1'))
        ..add(savedCopy('old-saved'))
        ..add(savedCopy('gone'));
      final bloc = buildBloc();
      await Future<void>.delayed(Duration.zero);

      bloc.add(const SharedRecipesEvent.scopeOpened(SharedFeedScope.saved));
      await Future<void>.delayed(Duration.zero);

      expect(shared.idsAskedFor, [
        {'old-saved', 'gone'},
      ]);
      final state = bloc.state as SharedRecipesLoaded;
      expect(state.older.map((r) => r.id), ['old-saved']);

      // An unshared post that came back empty is not asked for again.
      bloc.add(const SharedRecipesEvent.scopeOpened(SharedFeedScope.saved));
      await Future<void>.delayed(Duration.zero);
      expect(shared.idsAskedFor, hasLength(1));
      await bloc.close();
    });

    test('a like on an older post flips that row', () async {
      shared.feed = [buildShared(id: 's1')];
      shared.older = [buildShared(id: 'old-mine', authorUid: '')];
      final bloc = buildBloc();
      await Future<void>.delayed(Duration.zero);
      bloc.add(const SharedRecipesEvent.scopeOpened(SharedFeedScope.mine));
      await Future<void>.delayed(Duration.zero);

      bloc.add(const SharedRecipesEvent.toggleLike('old-mine'));
      await Future<void>.delayed(Duration.zero);

      final row = (bloc.state as SharedRecipesLoaded).older.single;
      expect(row.likedByMe, isTrue);
      expect(row.likeCount, 4);
      await bloc.close();
    });

    test('unsharing an older post drops it', () async {
      shared.feed = [buildShared(id: 's1')];
      shared.older = [buildShared(id: 'old-mine', authorUid: '')];
      final bloc = buildBloc();
      await Future<void>.delayed(Duration.zero);
      bloc.add(const SharedRecipesEvent.scopeOpened(SharedFeedScope.mine));
      await Future<void>.delayed(Duration.zero);

      bloc.add(const SharedRecipesEvent.unshare('old-mine'));
      await Future<void>.delayed(Duration.zero);

      expect((bloc.state as SharedRecipesLoaded).older, isEmpty);
      await bloc.close();
    });
  });
}
