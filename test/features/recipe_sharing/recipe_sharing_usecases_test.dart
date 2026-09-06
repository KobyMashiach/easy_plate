import 'dart:io';

import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/errors/app_exception.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_ingredient_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/repositories/recipes_repository.dart';
import 'package:easy_plate/features/recipe_sharing/domain/entities/collab_recipe_entity.dart';
import 'package:easy_plate/features/recipe_sharing/domain/entities/share_invite_entity.dart';
import 'package:easy_plate/features/recipe_sharing/domain/repositories/recipe_sharing_repository.dart';
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

  @override
  Future<String> ensureCollab(RecipeEntity recipe, {required String ownerUid}) async {
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
  }) async =>
      log.add('invite:$collabId:$targetUid:${role.name}');

  @override
  Future<CollabRecipeEntity> acceptInvite(ShareInviteEntity invite) async {
    log.add('accept:${invite.id}');
    return collab!;
  }

  @override
  Future<void> declineInvite(ShareInviteEntity invite) async => log.add('decline:${invite.id}');

  @override
  Future<CollabRecipeEntity?> getCollab(String collabId) async {
    log.add('get:$collabId');
    return collab;
  }

  @override
  Future<void> writeCollab(String collabId, RecipeEntity recipe, {required String byUid}) async =>
      log.add('write:$collabId:$byUid');

  @override
  Future<List<ShareInviteEntity>> incomingInvites(String uid) async => const [];
  @override
  Future<List<ShareInviteEntity>> outgoingInvites(String ownerUid) async => const [];
  @override
  Future<List<CollabRecipeEntity>> collabsOwnedBy(String uid) async => const [];
  @override
  Future<List<CollabRecipeEntity>> collabsSharedWith(String uid) async => const [];
  @override
  Future<void> removeMember(String collabId, String memberUid) async {}
}

class _FakeRecipes implements RecipesRepository {
  final saved = <RecipeEntity>[];
  @override
  Future<void> saveRecipe(RecipeEntity recipe) async => saved.add(recipe);
  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeProfiles implements UserProfileRepository {
  final directory = <String, String>{};
  @override
  Future<String?> findUidByContact(String contact) async => directory[contact];
  @override
  Future<Map<String, PublicProfileEntity>> getPublicProfiles(Set<String> uids) async => const {};
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

RecipeEntity localRecipe({String? collabId, CollabRole? role, String title = 'שקשוקה'}) =>
    RecipeEntity(
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
}) =>
    CollabRecipeEntity(
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

ShareInviteEntity invite({CollabRole role = CollabRole.editor}) => ShareInviteEntity(
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
    setUp(() => useCase = ShareRecipeUseCase(sharing: sharing, profiles: profiles, recipes: recipes));

    test('an unknown contact is refused before anything is created', () async {
      await expectLater(
        useCase(localRecipe(), contact: 'nobody@x.com', role: CollabRole.viewer, ownerUid: 'me'),
        throwsA(isA<ShareFailure>().having((f) => f.code, 'code', ShareFailure.notFound)),
      );
      expect(sharing.log, isEmpty);
      expect(recipes.saved, isEmpty);
    });

    test('an empty directory for the sender itself is reported as a server problem',
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
        throwsA(isA<ShareFailure>()
            .having((f) => f.code, 'code', ShareFailure.directoryUnavailable)),
      );
    });

    test('when the sender resolves but the target does not, it is the target', () async {
      profiles.directory['me@x.com'] = 'me';
      await expectLater(
        useCase(
          localRecipe(),
          contact: 'dana@x.com',
          role: CollabRole.viewer,
          ownerUid: 'me',
          senderContacts: const ['me@x.com'],
        ),
        throwsA(isA<ShareFailure>().having((f) => f.code, 'code', ShareFailure.notFound)),
      );
    });

    test('sharing with yourself is refused', () async {
      profiles.directory['me@x.com'] = 'me';
      await expectLater(
        useCase(localRecipe(), contact: 'me@x.com', role: CollabRole.viewer, ownerUid: 'me'),
        throwsA(isA<ShareFailure>().having((f) => f.code, 'code', ShareFailure.self)),
      );
      expect(sharing.log, isEmpty);
    });

    test('a first share creates the document, marks the local copy owner, then invites',
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
    });

    test('an already-shared recipe reuses its document and is not re-saved', () async {
      profiles.directory['dana@x.com'] = 'dana';
      await useCase(
        localRecipe(collabId: 'collab-1', role: CollabRole.owner),
        contact: 'dana@x.com',
        role: CollabRole.viewer,
        ownerUid: 'me',
      );
      expect(sharing.log, ['invite:collab-1:dana:viewer']);
      expect(recipes.saved, isEmpty);
    });
  });

  group('RespondToShareInviteUseCase', () {
    late RespondToShareInviteUseCase useCase;
    setUp(() => useCase = RespondToShareInviteUseCase(sharing: sharing, recipes: recipes));

    test('accepting creates a local cache under a fresh id with the granted role', () async {
      sharing.collab = remote();
      final local = await useCase.accept(invite(role: CollabRole.editor));

      expect(sharing.log, ['accept:collab-1_target']);
      expect(local.id, isNot('collab-1'), reason: 'never the shared document id');
      expect(local.collabId, 'collab-1');
      expect(local.collabRole, CollabRole.editor);
      expect(local.title, 'שקשוקה חריפה');
      expect(recipes.saved.single.id, local.id);
    });

    test('declining marks the invite and writes nothing locally', () async {
      await useCase.decline(invite());
      expect(sharing.log, ['decline:collab-1_target']);
      expect(recipes.saved, isEmpty);
    });
  });

  group('SyncCollabRecipeUseCase', () {
    late SyncCollabRecipeUseCase useCase;
    setUp(() => useCase = SyncCollabRecipeUseCase(sharing: sharing, recipes: recipes));

    test('an unshared recipe is returned untouched with no fetch', () async {
      final same = await useCase(localRecipe(), uid: 'me');
      expect(same.title, 'שקשוקה');
      expect(sharing.log, isEmpty);
      expect(recipes.saved, isEmpty);
    });

    test('the document replaces the content but the cache keeps its identity', () async {
      sharing.collab = remote(members: {'me': CollabRole.viewer});
      final synced = await useCase(localRecipe(collabId: 'collab-1', role: CollabRole.viewer), uid: 'me');

      expect(synced.title, 'שקשוקה חריפה');
      expect(synced.steps, ['קוצצים', 'מטגנים']);
      expect(synced.id, 'local-1');
      // The photo is device-local and not part of what is shared.
      expect(synced.imageFileName, 'photo.jpg');
      expect(recipes.saved.single.title, 'שקשוקה חריפה');
    });

    test('the role comes from the document, not the one cached at accept time', () async {
      // The owner promoted this account since it accepted as a viewer.
      sharing.collab = remote(members: {'me': CollabRole.editor});
      final synced = await useCase(localRecipe(collabId: 'collab-1', role: CollabRole.viewer), uid: 'me');
      expect(synced.collabRole, CollabRole.editor);
      expect(synced.canEdit, isTrue);
    });

    test('the owner reads back as owner', () async {
      sharing.collab = remote();
      final synced = await useCase(localRecipe(collabId: 'collab-1', role: CollabRole.owner), uid: 'owner');
      expect(synced.collabRole, CollabRole.owner);
    });

    test('a deleted document turns the cache into an ordinary private recipe', () async {
      sharing.collab = null;
      final orphaned = await useCase(localRecipe(collabId: 'collab-1', role: CollabRole.viewer), uid: 'me');

      expect(orphaned.collabId, isNull);
      expect(orphaned.collabRole, isNull);
      expect(orphaned.canEdit, isTrue, reason: 'nothing left to be a viewer of');
      expect(orphaned.title, 'שקשוקה', reason: 'the last content is kept, not lost');
      expect(recipes.saved.single.collabId, isNull);
    });
  });

  group('SaveCollabRecipeUseCase', () {
    late SaveCollabRecipeUseCase useCase;
    setUp(() => useCase = SaveCollabRecipeUseCase(sharing: sharing, recipes: recipes));

    test('an unshared recipe saves locally only', () async {
      await useCase(localRecipe(), byUid: 'me');
      expect(sharing.log, isEmpty);
      expect(recipes.saved, hasLength(1));
    });

    test('an editor writes the document before the cache', () async {
      await useCase(localRecipe(collabId: 'collab-1', role: CollabRole.editor), byUid: 'me');
      expect(sharing.log, ['write:collab-1:me']);
      expect(recipes.saved, hasLength(1));
    });

    test('a viewer is refused and nothing is written anywhere', () async {
      await expectLater(
        useCase(localRecipe(collabId: 'collab-1', role: CollabRole.viewer), byUid: 'me'),
        throwsA(isA<AppException>().having((e) => e.type, 'type', AppErrorType.unauthorized)),
      );
      expect(sharing.log, isEmpty);
      expect(recipes.saved, isEmpty);
    });
  });
}
