import 'dart:async';

import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/errors/app_exception.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/repositories/recipes_repository.dart';
import 'package:easy_plate/features/recipe_sharing/data/datasources/pending_accepts_store.dart';
import 'package:easy_plate/features/recipe_sharing/domain/entities/collab_recipe_entity.dart';
import 'package:easy_plate/features/recipe_sharing/domain/entities/share_invite_entity.dart';
import 'package:easy_plate/features/recipe_sharing/domain/repositories/recipe_sharing_repository.dart';
import 'package:easy_plate/features/recipe_sharing/domain/usecases/refresh_collab_recipes_usecase.dart';
import 'package:easy_plate/features/recipe_sharing/domain/usecases/respond_to_share_invite_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _Sharing implements RecipeSharingRepository {
  final log = <String>[];
  final collabs = <String, CollabRecipeEntity>{};

  /// The accept never answers (Firestore holding a queued write offline),
  /// or fails with this.
  bool stallAccept = false;
  Object? acceptError;

  /// Thrown by a document read: the rules refusing it, or no network.
  Object? getError;

  @override
  Future<CollabRecipeEntity> acceptInvite(ShareInviteEntity invite) {
    log.add('accept:${invite.collabId}');
    if (acceptError case final e?) return Future.error(e);
    if (stallAccept) return Completer<CollabRecipeEntity>().future;
    return Future.value(collabs[invite.collabId]!);
  }

  @override
  Future<CollabRecipeEntity?> getCollab(String collabId) async {
    log.add('get:$collabId');
    if (getError case final e?) throw e;
    return collabs[collabId];
  }

  /// Runs while the queries are out, standing in for a sign-out and a
  /// sign-in to another account meanwhile.
  void Function()? onQuery;

  @override
  Future<List<CollabRecipeEntity>> collabsOwnedBy(String uid) async {
    onQuery?.call();
    return const [];
  }

  @override
  Future<List<CollabRecipeEntity>> collabsSharedWith(String uid) async =>
      collabs.values.where((c) => c.members.containsKey(uid)).toList();

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Recipes implements RecipesRepository {
  List<RecipeEntity> stored = [];
  final saved = <RecipeEntity>[];
  @override
  Future<List<RecipeEntity>> getRecipes() async => stored;
  @override
  Future<RecipeEntity?> getRecipeById(String id) async =>
      stored.where((r) => r.id == id).firstOrNull;
  @override
  Future<void> saveRecipe(
    RecipeEntity recipe, {
    bool stampLanguage = true,
  }) async {
    saved.add(recipe);
    stored = [...stored.where((r) => r.id != recipe.id), recipe];
  }

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

CollabRecipeEntity collab(String id, {Map<String, CollabRole>? members}) =>
    CollabRecipeEntity(
      id: id,
      ownerUid: 'owner',
      members: members ?? const {'me': CollabRole.editor},
      recipe: RecipeEntity(
        id: id,
        title: 'Recipe $id',
        ingredients: const [],
        steps: const ['step'],
        createdAt: DateTime(2026),
      ),
      updatedAt: DateTime(2026),
    );

ShareInviteEntity inviteTo(String collabId) => ShareInviteEntity(
  id: '${collabId}_me',
  collabId: collabId,
  recipeTitle: 'Recipe $collabId',
  ownerUid: 'owner',
  targetUid: 'me',
  role: CollabRole.editor,
  status: ShareInviteStatus.pending,
  createdAt: DateTime(2026),
);

void main() {
  late _Sharing sharing;
  late _Recipes recipes;
  late InMemoryPendingAcceptsStore pending;

  RespondToShareInviteUseCase useCase({
    Duration timeout = const Duration(milliseconds: 20),
  }) => RespondToShareInviteUseCase(
    sharing: sharing,
    recipes: recipes,
    pending: pending,
    remoteTimeout: timeout,
  );

  setUp(() {
    sharing = _Sharing()..collabs['c1'] = collab('c1');
    recipes = _Recipes();
    pending = InMemoryPendingAcceptsStore();
  });

  group('PendingAccept', () {
    test('survives the round trip through json', () {
      final mark = PendingAccept(
        collabId: 'c1',
        kind: CollabKind.mealPlan,
        at: DateTime(2026, 10, 18, 9, 30),
      );
      final back = PendingAccept.fromJson(mark.toJson());
      expect(back!.collabId, 'c1');
      expect(back.kind, CollabKind.mealPlan);
      expect(back.at, DateTime(2026, 10, 18, 9, 30));
    });

    test('a damaged entry is dropped rather than thrown on', () {
      expect(PendingAccept.fromJson('garbage'), isNull);
      expect(PendingAccept.fromJson({'collabId': ''}), isNull);
      expect(
        PendingAccept.fromJson({'collabId': 'c1', 'at': 'not a date'}),
        isNull,
      );
    });

    test('is due after a minute and stale after a week', () {
      final mark = PendingAccept(
        collabId: 'c1',
        kind: CollabKind.recipe,
        at: DateTime(2026, 10, 18),
      );
      expect(mark.isDue(DateTime(2026, 10, 18, 0, 0, 30)), isFalse);
      expect(mark.isDue(DateTime(2026, 10, 18, 0, 1)), isTrue);
      expect(mark.isStale(DateTime(2026, 10, 24)), isFalse);
      expect(mark.isStale(DateTime(2026, 10, 25)), isTrue);
    });
  });

  group('accept', () {
    test('a completed accept leaves no mark behind', () async {
      final local = await useCase().accept(inviteTo('c1'));
      expect(local.collabId, 'c1');
      expect(pending.entries, isEmpty);
    });

    test(
      'a server that does not answer in time is reported as queued, '
      'with the mark kept for the next refresh',
      () async {
        sharing.stallAccept = true;
        await expectLater(
          useCase().accept(inviteTo('c1')),
          throwsA(predicate(RecipeSharingRepository.isAcceptQueued)),
        );
        expect(recipes.saved, isEmpty, reason: 'no copy without the document');
        expect(pending.entries.keys, ['c1']);
        expect(pending.entries['c1']!.kind, CollabKind.recipe);
      },
    );

    test(
      'a share that is gone clears the mark: nothing left to finish',
      () async {
        sharing.acceptError = const AppException(
          AppErrorType.notFound,
          message: RecipeSharingRepository.collabMissing,
        );
        await expectLater(
          useCase().accept(inviteTo('c1')),
          throwsA(predicate(RecipeSharingRepository.isCollabMissing)),
        );
        expect(pending.entries, isEmpty);
      },
    );

    test(
      'any other failure keeps the mark (the writes may have landed)',
      () async {
        sharing.acceptError = StateError('unavailable');
        await expectLater(
          useCase().accept(inviteTo('c1')),
          throwsA(isA<StateError>()),
        );
        expect(pending.entries.keys, ['c1']);
      },
    );
  });

  group('repairPending', () {
    final now = DateTime(2026, 10, 18, 12);
    PendingAccept mark(
      String id, {
      CollabKind kind = CollabKind.recipe,
      Duration age = const Duration(minutes: 5),
    }) => PendingAccept(collabId: id, kind: kind, at: now.subtract(age));

    Future<void> repair({String signedIn = 'me'}) =>
        RespondToShareInviteUseCase.repairPending(
          sharing: sharing,
          recipes: recipes,
          pending: pending,
          uid: 'me',
          now: now,
          stillSignedIn: (uid) => uid == signedIn,
        );

    test(
      'writes the copy once the document can be read, with the role it says',
      () async {
        await pending.add(mark('c1'));
        await repair();
        final copy = recipes.saved.single;
        expect(copy.collabId, 'c1');
        expect(copy.collabRole, CollabRole.editor);
        expect(copy.title, 'Recipe c1');
        expect(pending.entries, isEmpty);
      },
    );

    test(
      'a mark younger than a minute may still be an accept in flight',
      () async {
        await pending.add(mark('c1', age: const Duration(seconds: 10)));
        await repair();
        expect(recipes.saved, isEmpty);
        expect(sharing.log, isEmpty, reason: 'not even read');
        expect(pending.entries.keys, ['c1']);
      },
    );

    test('a copy that arrived meanwhile is not written twice', () async {
      recipes.stored = [
        RecipeEntity(
          id: 'local',
          title: 'x',
          ingredients: const [],
          steps: const [],
          createdAt: DateTime(2026),
          collabId: 'c1',
          collabRole: CollabRole.editor,
        ),
      ];
      await pending.add(mark('c1'));
      await repair();
      expect(recipes.saved, isEmpty);
      expect(pending.entries, isEmpty);
    });

    test('a document the rules still refuse waits for the next pass', () async {
      sharing.getError = StateError('permission-denied');
      await pending.add(mark('c1'));
      await repair();
      expect(recipes.saved, isEmpty);
      expect(pending.entries.keys, ['c1']);
    });

    test(
      'a document that is gone, or a mark a week old, is given up',
      () async {
        await pending.add(mark('gone'));
        await pending.add(mark('c1', age: const Duration(days: 8)));
        await repair();
        expect(recipes.saved, isEmpty);
        expect(pending.entries, isEmpty);
      },
    );

    test(
      'another account signed in meanwhile gets no copy and keeps the mark',
      () async {
        await pending.add(mark('c1'));
        await repair(signedIn: 'someone-else');
        expect(recipes.saved, isEmpty);
        expect(pending.entries.keys, ['c1']);
      },
    );

    test('container marks are left to the container service', () async {
      await pending.add(mark('book-1', kind: CollabKind.book));
      await repair();
      expect(sharing.log, isEmpty);
      expect(pending.entries.keys, ['book-1']);
    });

    test(
      'the refresh stops before writing when another account signed in '
      'while its queries were out',
      () async {
        recipes.stored = [
          RecipeEntity(
            id: 'local',
            title: 'old title',
            ingredients: const [],
            steps: const [],
            createdAt: DateTime(2026),
            collabId: 'c1',
            collabRole: CollabRole.editor,
          ),
        ];
        var signedIn = 'me';
        sharing.onQuery = () => signedIn = 'account-b';
        final rewritten = await RefreshCollabRecipesUseCase(
          sharing: sharing,
          recipes: recipes,
          pending: pending,
          stillSignedIn: (uid) => uid == signedIn,
        )(uid: 'me');
        expect(rewritten, 0);
        expect(recipes.saved, isEmpty, reason: 'account B keeps its boxes');
      },
    );

    test(
      'the refresh runs it first, even for an account with no shared copy',
      () async {
        await pending.add(mark('c1'));
        final rewritten = await RefreshCollabRecipesUseCase(
          sharing: sharing,
          recipes: recipes,
          pending: pending,
          stillSignedIn: (_) => true,
        )(uid: 'me');
        expect(recipes.saved.single.collabId, 'c1');
        expect(pending.entries, isEmpty);
        // The copy was just written from the document; nothing to rewrite.
        expect(rewritten, 0);
      },
    );
  });
}
