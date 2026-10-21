import 'dart:async';
import 'dart:io';

import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/errors/app_exception.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/nutrition_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_ingredient_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/repositories/recipes_repository.dart';
import 'package:easy_plate/features/recipe_sharing/data/datasources/pending_accepts_store.dart';
import 'package:easy_plate/features/recipe_sharing/domain/entities/collab_recipe_entity.dart';
import 'package:easy_plate/features/recipe_sharing/domain/entities/share_invite_entity.dart';
import 'package:easy_plate/features/recipe_sharing/domain/repositories/recipe_sharing_repository.dart';
import 'package:easy_plate/features/recipe_sharing/domain/usecases/refresh_collab_recipes_usecase.dart';
import 'package:easy_plate/features/recipe_sharing/domain/usecases/respond_to_share_invite_usecase.dart';
import 'package:easy_plate/features/recipe_sharing/domain/usecases/save_collab_recipe_usecase.dart';
import 'package:easy_plate/features/recipe_sharing/domain/usecases/share_recipe_usecase.dart';
import 'package:easy_plate/features/recipe_sharing/domain/usecases/sync_collab_recipe_usecase.dart';
import 'package:easy_plate/features/user_profile/domain/entities/public_profile_entity.dart';
import 'package:easy_plate/features/user_profile/domain/entities/user_profile_entity.dart';
import 'package:easy_plate/features/user_profile/domain/repositories/user_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSharing implements RecipeSharingRepository {
  final log = <String>[];
  CollabRecipeEntity? collab;
  String createdId = 'collab-new';

  /// The recipe the collab document was written from.
  RecipeEntity? ensured;

  /// Runs while the queries are out, standing in for a save made meanwhile.
  void Function()? onQuery;

  /// What the two collab queries answer with.
  List<CollabRecipeEntity> owned = const [];
  List<CollabRecipeEntity> sharedWith = const [];

  /// A write that never completes, standing in for Firestore queuing one
  /// offline; and one that is refused outright.
  bool stallWrite = false;
  Object? writeError;

  @override
  Future<String> ensureCollab(
    RecipeEntity recipe, {
    required String ownerUid,
  }) async {
    ensured = recipe;
    if (recipe.collabId case final id?) return id;
    log.add('create');
    return createdId;
  }

  @override
  Future<void> invite({
    required String collabId,
    required String recipeTitle,
    required String ownerUid,
    required String targetUid,
    required CollabRole role,
  }) async => log.add('invite:$collabId:$targetUid:${role.name}');

  @override
  Future<CollabRecipeEntity> acceptInvite(ShareInviteEntity invite) async {
    log.add('accept:${invite.id}');
    return collab!;
  }

  @override
  Future<void> declineInvite(ShareInviteEntity invite) async =>
      log.add('decline:${invite.id}');

  /// Thrown by the next document read, standing in for the rules refusing
  /// it or the network being away.
  Object? getError;

  @override
  Future<CollabRecipeEntity?> getCollab(String collabId) async {
    log.add('get:$collabId');
    if (getError case final e?) throw e;
    return collab;
  }

  @override
  Future<void> writeCollab(
    String collabId,
    RecipeEntity recipe, {
    required String byUid,
  }) {
    log.add('write:$collabId:$byUid');
    if (writeError case final error?) return Future.error(error);
    if (stallWrite) return Completer<void>().future;
    return Future.value();
  }

  @override
  Future<List<ShareInviteEntity>> incomingInvites(String uid) async => const [];
  @override
  Future<List<ShareInviteEntity>> outgoingInvites(String ownerUid) async =>
      const [];
  @override
  Future<List<CollabRecipeEntity>> collabsOwnedBy(String uid) async {
    log.add('owned:$uid');
    onQuery?.call();
    return owned;
  }

  @override
  Future<List<CollabRecipeEntity>> collabsSharedWith(String uid) async {
    log.add('sharedWith:$uid');
    return sharedWith;
  }

  @override
  Future<void> removeMember(
    String collabId,
    String memberUid, {
    bool revokeInvite = false,
  }) async {}
}

class _FakeRecipes implements RecipesRepository {
  final saved = <RecipeEntity>[];

  /// What the local box holds before the use case runs.
  List<RecipeEntity> stored = const [];

  @override
  Future<List<RecipeEntity>> getRecipes() async => stored;

  @override
  Future<RecipeEntity?> getRecipeById(String id) async =>
      stored.where((r) => r.id == id).firstOrNull;

  @override
  Future<void> saveRecipe(
    RecipeEntity recipe, {
    bool stampLanguage = true,
  }) async => saved.add(recipe);

  /// Nothing to upload in a test, which is also what the real repository
  /// returns for a recipe with no photo.
  @override
  Future<RecipeEntity> readyForSharing(
    RecipeEntity recipe, {
    bool persist = true,
  }) async => recipe;

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeProfiles implements UserProfileRepository {
  @override
  Future<void> touchDevice(
    String uid, {
    required String platform,
    String? appVersion,
  }) async {}

  @override
  Future<String?> blockMessage(String uid) async => null;

  final directory = <String, String>{};
  @override
  Future<String?> findUidByContact(String contact) async => directory[contact];
  @override
  Future<Map<String, PublicProfileEntity>> getPublicProfiles(
    Set<String> uids, {
    bool refresh = false,
  }) async => const {};
  @override
  Future<UserProfileEntity?> getProfile(String uid) async => null;
  @override
  Future<void> saveProfile(UserProfileEntity profile) async {}
  @override
  Future<String> uploadPhoto(String uid, File file) async => '';
  @override
  Future<void> savePushToken(String uid, String token) async {}
  @override
  Future<void> publishPublicProfile(UserProfileEntity profile) async {}
}

RecipeEntity localRecipe({
  String? collabId,
  CollabRole? role,
  String title = 'שקשוקה',
}) => RecipeEntity(
  id: 'local-1',
  title: title,
  ingredients: const [RecipeIngredientEntity(name: 'ביצים', amount: 4)],
  steps: const ['מטגנים'],
  imageFileName: 'photo.jpg',
  collabId: collabId,
  collabRole: role,
  createdAt: DateTime(2026, 1, 1),
);

CollabRecipeEntity remote({
  String id = 'collab-1',
  String title = 'שקשוקה חריפה',
  Map<String, CollabRole> members = const {},
}) => CollabRecipeEntity(
  id: id,
  ownerUid: 'owner',
  members: members,
  recipe: RecipeEntity(
    id: id,
    title: title,
    ingredients: const [RecipeIngredientEntity(name: 'פלפל', amount: 1)],
    steps: const ['קוצצים', 'מטגנים'],
    createdAt: DateTime(2026, 1, 1),
  ),
  updatedAt: DateTime(2026, 2, 1),
);

/// A shared document whose content already equals [localRecipe]'s, so a test
/// can change exactly one thing and see whether that alone is picked up.
CollabRecipeEntity remoteMatchingLocal({
  Map<String, CollabRole> members = const {},
}) => CollabRecipeEntity(
  id: 'collab-1',
  ownerUid: 'owner',
  members: members,
  recipe: RecipeEntity(
    id: 'collab-1',
    title: 'שקשוקה',
    ingredients: const [RecipeIngredientEntity(name: 'ביצים', amount: 4)],
    steps: const ['מטגנים'],
    createdAt: DateTime(2026, 1, 1),
  ),
  updatedAt: DateTime(2026, 2, 1),
);

ShareInviteEntity invite({CollabRole role = CollabRole.editor}) =>
    ShareInviteEntity(
      id: 'collab-1_target',
      collabId: 'collab-1',
      recipeTitle: 'שקשוקה',
      ownerUid: 'owner',
      targetUid: 'target',
      role: role,
      status: ShareInviteStatus.pending,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  late _FakeSharing sharing;
  late _FakeRecipes recipes;
  late _FakeProfiles profiles;

  setUp(() {
    sharing = _FakeSharing();
    recipes = _FakeRecipes();
    profiles = _FakeProfiles();
  });

  group('ShareRecipeUseCase', () {
    late ShareRecipeUseCase useCase;
    setUp(
      () => useCase = ShareRecipeUseCase(
        sharing: sharing,
        profiles: profiles,
        recipes: recipes,
      ),
    );

    test('an unknown contact is refused before anything is created', () async {
      await expectLater(
        useCase(
          localRecipe(),
          contact: 'nobody@x.com',
          role: CollabRole.viewer,
          ownerUid: 'me',
        ),
        throwsA(
          isA<ShareFailure>().having(
            (f) => f.code,
            'code',
            ShareFailure.notFound,
          ),
        ),
      );
      expect(sharing.log, isEmpty);
      expect(recipes.saved, isEmpty);
    });

    test(
      'an empty directory for the sender itself is reported as a server problem',
      () async {
        // Neither the target nor the sender's own email resolves: the directory
        // was never populated for this account, so the remedy is deploying the
        // rules and signing in again — not asking the other person to check.
        await expectLater(
          useCase(
            localRecipe(),
            contact: 'dana@x.com',
            role: CollabRole.viewer,
            ownerUid: 'me',
            senderContacts: const ['me@x.com'],
          ),
          throwsA(
            isA<ShareFailure>().having(
              (f) => f.code,
              'code',
              ShareFailure.directoryUnavailable,
            ),
          ),
        );
      },
    );

    test(
      'when the sender resolves but the target does not, it is the target',
      () async {
        profiles.directory['me@x.com'] = 'me';
        await expectLater(
          useCase(
            localRecipe(),
            contact: 'dana@x.com',
            role: CollabRole.viewer,
            ownerUid: 'me',
            senderContacts: const ['me@x.com'],
          ),
          throwsA(
            isA<ShareFailure>().having(
              (f) => f.code,
              'code',
              ShareFailure.notFound,
            ),
          ),
        );
      },
    );

    test('sharing with yourself is refused', () async {
      profiles.directory['me@x.com'] = 'me';
      await expectLater(
        useCase(
          localRecipe(),
          contact: 'me@x.com',
          role: CollabRole.viewer,
          ownerUid: 'me',
        ),
        throwsA(
          isA<ShareFailure>().having((f) => f.code, 'code', ShareFailure.self),
        ),
      );
      expect(sharing.log, isEmpty);
    });

    test(
      'a first share creates the document, marks the local copy owner, then invites',
      () async {
        profiles.directory['dana@x.com'] = 'dana';
        final owned = await useCase(
          localRecipe(),
          contact: 'dana@x.com',
          role: CollabRole.editor,
          ownerUid: 'me',
        );

        expect(sharing.log, ['create', 'invite:collab-new:dana:editor']);
        expect(owned.collabId, 'collab-new');
        expect(owned.collabRole, CollabRole.owner);
        // The local copy is written before the invite goes out, so a crash in
        // between leaves a shareable recipe rather than an orphaned document.
        expect(recipes.saved.single.collabId, 'collab-new');
      },
    );

    test(
      'an already-shared recipe reuses its document and is not re-saved',
      () async {
        profiles.directory['dana@x.com'] = 'dana';
        await useCase(
          localRecipe(collabId: 'collab-1', role: CollabRole.owner),
          contact: 'dana@x.com',
          role: CollabRole.viewer,
          ownerUid: 'me',
        );
        expect(sharing.log, ['invite:collab-1:dana:viewer']);
        expect(recipes.saved, isEmpty);
      },
    );

    test(
      'a copy from before the first share adopts the stored document rather '
      'than creating a second one',
      () async {
        // The sheet still holds the recipe as it opened it; a code made a
        // moment ago already made the recipe shared.
        recipes.stored = [
          localRecipe(collabId: 'collab-1', role: CollabRole.owner),
        ];
        profiles.directory['dana@x.com'] = 'dana';
        final owned = await useCase(
          localRecipe(),
          contact: 'dana@x.com',
          role: CollabRole.viewer,
          ownerUid: 'me',
        );
        expect(sharing.log, ['invite:collab-1:dana:viewer']);
        expect(owned.collabId, 'collab-1');
        expect(recipes.saved, isEmpty);
      },
    );
  });

  group('ShareRecipeUseCase.prepare', () {
    test(
      'pass 8: the first share marks the copy as stored now, not the one the '
      'sheet opened with',
      () async {
        recipes.stored = [localRecipe(title: 'שקשוקה מתורגמת')];
        final useCase = ShareRecipeUseCase(
          sharing: sharing,
          profiles: profiles,
          recipes: recipes,
        );
        await useCase.prepare(localRecipe(), ownerUid: 'me');
        expect(recipes.saved.single.title, 'שקשוקה מתורגמת');
        expect(recipes.saved.single.collabId, 'collab-new');
        expect(recipes.saved.single.collabRole, CollabRole.owner);
      },
    );

    test(
      'the document is written from the stored copy, not the sheet\'s',
      () async {
        recipes.stored = [
          localRecipe(title: 'שקשוקה מתורגמת', collabId: 'collab-1'),
        ];
        final useCase = ShareRecipeUseCase(
          sharing: sharing,
          profiles: profiles,
          recipes: recipes,
        );
        await useCase.prepare(localRecipe(), ownerUid: 'me');
        expect(sharing.ensured!.title, 'שקשוקה מתורגמת');
        expect(sharing.ensured!.collabId, 'collab-1');
        expect(sharing.log, isNot(contains('create')));
      },
    );
  });

  group('RespondToShareInviteUseCase', () {
    late RespondToShareInviteUseCase useCase;
    setUp(
      () => useCase = RespondToShareInviteUseCase(
        sharing: sharing,
        recipes: recipes,
        pending: InMemoryPendingAcceptsStore(),
      ),
    );

    test(
      'accepting creates a local cache under a fresh id with the granted role',
      () async {
        sharing.collab = remote();
        final local = await useCase.accept(invite(role: CollabRole.editor));

        expect(sharing.log, ['accept:collab-1_target']);
        expect(
          local.id,
          isNot('collab-1'),
          reason: 'never the shared document id',
        );
        expect(local.collabId, 'collab-1');
        expect(local.collabRole, CollabRole.editor);
        expect(local.title, 'שקשוקה חריפה');
        expect(recipes.saved.single.id, local.id);
      },
    );

    test(
      'accepting a document this account already holds a copy of lays it '
      'over that copy rather than adding a second one',
      () async {
        // Accepted on another device, or removed and invited again: the
        // copy is already in the box, under its own id.
        recipes.stored = [
          localRecipe(collabId: 'collab-1', role: CollabRole.viewer),
        ];
        sharing.collab = remote();
        final local = await useCase.accept(invite(role: CollabRole.editor));

        expect(local.id, 'local-1');
        expect(local.collabId, 'collab-1');
        expect(local.collabRole, CollabRole.editor);
        expect(local.title, 'שקשוקה חריפה');
        // Device-local traces of the copy survive the overlay.
        expect(local.imageFileName, 'photo.jpg');
        expect(local.createdAt, DateTime(2026, 1, 1));
        expect(recipes.saved.single.id, 'local-1');
      },
    );

    test('declining marks the invite and writes nothing locally', () async {
      await useCase.decline(invite());
      expect(sharing.log, ['decline:collab-1_target']);
      expect(recipes.saved, isEmpty);
    });
  });

  group('SyncCollabRecipeUseCase', () {
    late SyncCollabRecipeUseCase useCase;
    setUp(
      () =>
          useCase = SyncCollabRecipeUseCase(sharing: sharing, recipes: recipes),
    );

    /// Syncs [local] as the copy the box holds.
    Future<RecipeEntity> sync(RecipeEntity local, {required String uid}) {
      recipes.stored = [local];
      return useCase(local, uid: uid);
    }

    test('an unshared recipe is returned untouched with no fetch', () async {
      final same = await sync(localRecipe(), uid: 'me');
      expect(same.title, 'שקשוקה');
      expect(sharing.log, isEmpty);
      expect(recipes.saved, isEmpty);
    });

    test(
      'a read the rules refuse (removed from the share) orphans the copy',
      () async {
        sharing.getError = Exception('[cloud_firestore/permission-denied]');
        final synced = await sync(
          localRecipe(collabId: 'collab-1', role: CollabRole.viewer),
          uid: 'me',
        );
        expect(synced.collabId, isNull);
        expect(synced.collabRole, isNull);
        expect(recipes.saved.single.collabId, isNull);
      },
    );

    test('any other failure is thrown and the copy kept as it is', () async {
      sharing.getError = Exception('[cloud_firestore/unavailable]');
      await expectLater(
        sync(localRecipe(collabId: 'collab-1'), uid: 'me'),
        throwsException,
      );
      expect(recipes.saved, isEmpty);
    });

    test(
      'the document replaces the content but the cache keeps its identity',
      () async {
        sharing.collab = remote(members: {'me': CollabRole.viewer});
        final synced = await sync(
          localRecipe(collabId: 'collab-1', role: CollabRole.viewer),
          uid: 'me',
        );

        expect(synced.title, 'שקשוקה חריפה');
        expect(synced.steps, ['קוצצים', 'מטגנים']);
        expect(synced.id, 'local-1');
        // The photo is device-local and not part of what is shared.
        expect(synced.imageFileName, 'photo.jpg');
        expect(recipes.saved.single.title, 'שקשוקה חריפה');
      },
    );

    test(
      'servings and macros travel with the document, the post stays local',
      () async {
        sharing.collab = CollabRecipeEntity(
          id: 'collab-1',
          ownerUid: 'owner',
          members: {'me': CollabRole.viewer},
          recipe: remote().recipe.copyWith(
            servings: 6,
            nutrition: const NutritionEntity(
              calories: 320,
              proteinGrams: 20,
              carbsGrams: 30,
              fatGrams: 10,
            ),
          ),
          updatedAt: DateTime(2026, 2, 1),
        );
        final synced = await sync(
          localRecipe(
            collabId: 'collab-1',
            role: CollabRole.viewer,
          ).copyWith(sharedRecipeId: 'post-9', servings: 2),
          uid: 'me',
        );
        // Used to come back null on every refresh, the owner's copy included.
        expect(synced.servings, 6);
        expect(synced.nutrition?.calories, 320);
        expect(synced.sharedRecipeId, 'post-9');
      },
    );

    test(
      'the role comes from the document, not the one cached at accept time',
      () async {
        // The owner promoted this account since it accepted as a viewer.
        sharing.collab = remote(members: {'me': CollabRole.editor});
        final synced = await sync(
          localRecipe(collabId: 'collab-1', role: CollabRole.viewer),
          uid: 'me',
        );
        expect(synced.collabRole, CollabRole.editor);
        expect(synced.canEdit, isTrue);
      },
    );

    test('the owner reads back as owner', () async {
      sharing.collab = remote();
      final synced = await sync(
        localRecipe(collabId: 'collab-1', role: CollabRole.owner),
        uid: 'owner',
      );
      expect(synced.collabRole, CollabRole.owner);
    });

    test(
      'a deleted document turns the cache into an ordinary private recipe',
      () async {
        sharing.collab = null;
        final orphaned = await sync(
          localRecipe(collabId: 'collab-1', role: CollabRole.viewer),
          uid: 'me',
        );

        expect(orphaned.collabId, isNull);
        expect(orphaned.collabRole, isNull);
        expect(
          orphaned.canEdit,
          isTrue,
          reason: 'nothing left to be a viewer of',
        );
        expect(
          orphaned.title,
          'שקשוקה',
          reason: 'the last content is kept, not lost',
        );
        expect(recipes.saved.single.collabId, isNull);
      },
    );

    test(
      'pass 8: the merge lands on the copy as stored now, not the one '
      'handed in before the fetch',
      () async {
        sharing.collab = remote(members: {'me': CollabRole.viewer});
        final handedIn = localRecipe(
          collabId: 'collab-1',
          role: CollabRole.viewer,
        );
        // Saved while the document was being read.
        recipes.stored = [handedIn.copyWith(sharedRecipeId: 'post-new')];
        final synced = await useCase(handedIn, uid: 'me');
        expect(synced.title, 'שקשוקה חריפה');
        expect(synced.sharedRecipeId, 'post-new');
        expect(recipes.saved.single.sharedRecipeId, 'post-new');
      },
    );

    test(
      'pass 8: a copy deleted during the fetch is not brought back',
      () async {
        sharing.collab = remote(members: {'me': CollabRole.viewer});
        recipes.stored = const [];
        await useCase(
          localRecipe(collabId: 'collab-1', role: CollabRole.viewer),
          uid: 'me',
        );
        expect(recipes.saved, isEmpty);
      },
    );
  });

  group('SaveCollabRecipeUseCase', () {
    late SaveCollabRecipeUseCase useCase;
    setUp(
      () =>
          useCase = SaveCollabRecipeUseCase(sharing: sharing, recipes: recipes),
    );

    test('an unshared recipe saves locally only', () async {
      await useCase(localRecipe(), byUid: 'me');
      expect(sharing.log, isEmpty);
      expect(recipes.saved, hasLength(1));
    });

    test('an editor writes the document before the cache', () async {
      await useCase(
        localRecipe(collabId: 'collab-1', role: CollabRole.editor),
        byUid: 'me',
      );
      expect(sharing.log, ['write:collab-1:me']);
      expect(recipes.saved, hasLength(1));
    });

    test('a viewer is refused and nothing is written anywhere', () async {
      await expectLater(
        useCase(
          localRecipe(collabId: 'collab-1', role: CollabRole.viewer),
          byUid: 'me',
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.type,
            'type',
            AppErrorType.unauthorized,
          ),
        ),
      );
      expect(sharing.log, isEmpty);
      expect(recipes.saved, isEmpty);
    });

    test('a write that is only queued still reaches the local cache', () async {
      // Offline, Firestore takes the write but its future waits for a server
      // ack. Blocking the editor on that would hang it for the whole outage.
      sharing.stallWrite = true;
      final quick = SaveCollabRecipeUseCase(
        sharing: sharing,
        recipes: recipes,
        remoteWriteTimeout: const Duration(milliseconds: 10),
      );

      await quick(
        localRecipe(collabId: 'collab-1', role: CollabRole.editor),
        byUid: 'me',
      );
      expect(recipes.saved, hasLength(1));
    });

    test('a refused write is not cached', () async {
      // A revoked member, or the rules saying no: the local copy must not be
      // left holding an edit the shared document rejected.
      sharing.writeError = StateError('permission-denied');
      await expectLater(
        useCase(
          localRecipe(collabId: 'collab-1', role: CollabRole.editor),
          byUid: 'me',
        ),
        throwsA(isA<StateError>()),
      );
      expect(recipes.saved, isEmpty);
    });

    test('the stored recipe is returned, not the one handed in', () async {
      final stored = await useCase(localRecipe(), byUid: 'me');
      expect(identical(stored, recipes.saved.single), isTrue);
    });
  });

  group('RefreshCollabRecipesUseCase', () {
    late RefreshCollabRecipesUseCase useCase;
    setUp(
      () => useCase = RefreshCollabRecipesUseCase(
        sharing: sharing,
        recipes: recipes,
        pending: InMemoryPendingAcceptsStore(),
        stillSignedIn: (_) => true,
      ),
    );

    test('an account that shares nothing is not queried at all', () async {
      recipes.stored = [localRecipe()];
      expect(await useCase(uid: 'me'), 0);
      expect(sharing.log, isEmpty, reason: 'two billed queries for no reason');
    });

    test(
      "a co-editor's change reaches the cache without the recipe being opened",
      () async {
        recipes.stored = [
          localRecipe(collabId: 'collab-1', role: CollabRole.editor),
        ];
        sharing.sharedWith = [
          remote(members: {'me': CollabRole.editor}),
        ];

        expect(await useCase(uid: 'me'), 1);
        expect(recipes.saved.single.title, 'שקשוקה חריפה');
        expect(
          recipes.saved.single.id,
          'local-1',
          reason: 'still this account\'s copy',
        );
      },
    );

    test('a cache that already matches is not rewritten', () async {
      // Otherwise every resume pushes every shared recipe through the cloud
      // mirror for nothing.
      recipes.stored = [
        localRecipe(collabId: 'collab-1', role: CollabRole.editor),
      ];
      sharing.sharedWith = [
        remoteMatchingLocal(members: {'me': CollabRole.editor}),
      ];

      expect(await useCase(uid: 'me'), 0);
      expect(recipes.saved, isEmpty);
    });

    test('a changed servings count alone is picked up', () async {
      recipes.stored = [
        localRecipe(collabId: 'collab-1', role: CollabRole.editor),
      ];
      final matching = remoteMatchingLocal(members: {'me': CollabRole.editor});
      sharing.sharedWith = [
        CollabRecipeEntity(
          id: matching.id,
          ownerUid: matching.ownerUid,
          members: matching.members,
          recipe: matching.recipe.copyWith(servings: 8),
          updatedAt: matching.updatedAt,
        ),
      ];

      expect(await useCase(uid: 'me'), 1);
      expect(recipes.saved.single.servings, 8);
    });

    test('a role changed by the owner is picked up on its own', () async {
      recipes.stored = [
        localRecipe(collabId: 'collab-1', role: CollabRole.editor),
      ];
      // Content identical to the cache: the demotion is the only difference,
      // so this also pins that `differs` looks at the role at all.
      sharing.sharedWith = [
        remoteMatchingLocal(members: {'me': CollabRole.viewer}),
      ];

      expect(await useCase(uid: 'me'), 1);
      expect(recipes.saved.single.collabRole, CollabRole.viewer);
    });

    test(
      'a recipe the queries did not answer for is left alone, not orphaned',
      () async {
        // An offline query answers from cache and can come back empty; concluding
        // "removed from the share" here would quietly unshare the whole account.
        recipes.stored = [
          localRecipe(collabId: 'collab-1', role: CollabRole.editor),
        ];
        sharing.sharedWith = const [];
        sharing.owned = const [];

        expect(await useCase(uid: 'me'), 0);
        expect(recipes.saved, isEmpty);
      },
    );

    test('recipes this account owns are refreshed too', () async {
      // The owner's own second device is as stale as anyone else's.
      recipes.stored = [
        localRecipe(collabId: 'collab-1', role: CollabRole.owner),
      ];
      sharing.owned = [remote()];

      expect(await useCase(uid: 'owner'), 1);
      expect(recipes.saved.single.collabRole, CollabRole.owner);
      expect(recipes.saved.single.title, 'שקשוקה חריפה');
    });

    test(
      'pass 8: an edit saved while the queries were out survives the refresh',
      () async {
        final cached = localRecipe(
          collabId: 'collab-1',
          role: CollabRole.owner,
        );
        recipes.stored = [cached];
        sharing.owned = [remote()];
        sharing.onQuery = () =>
            recipes.stored = [cached.copyWith(sharedRecipeId: 'post-new')];

        expect(await useCase(uid: 'owner'), 1);
        expect(recipes.saved.single.title, 'שקשוקה חריפה');
        expect(recipes.saved.single.sharedRecipeId, 'post-new');
      },
    );

    test(
      'pass 8: a copy deleted while the queries were out stays deleted',
      () async {
        recipes.stored = [
          localRecipe(collabId: 'collab-1', role: CollabRole.owner),
        ];
        sharing.owned = [remote()];
        sharing.onQuery = () => recipes.stored = const [];

        expect(await useCase(uid: 'owner'), 0);
        expect(recipes.saved, isEmpty);
      },
    );
  });
}
