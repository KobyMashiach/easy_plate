import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/recipe_sharing/data/datasources/recipe_sharing_remote_datasource.dart';
import 'package:easy_plate/features/recipe_sharing/data/repositories_impl/recipe_sharing_repository_impl.dart';
import 'package:easy_plate/features/recipe_sharing/domain/entities/collab_recipe_entity.dart';
import 'package:easy_plate/features/recipe_sharing/domain/entities/share_invite_entity.dart';
import 'package:easy_plate/features/recipe_sharing/domain/repositories/recipe_sharing_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRemote implements RecipeSharingRemoteDataSource {
  final log = <String>[];
  Object? joinError;
  CollabRecipeEntity? collab;

  @override
  Future<void> setInviteStatus(
    String inviteId,
    ShareInviteStatus status,
  ) async {
    log.add('status:${status.name}');
  }

  @override
  Future<void> joinCollab(
    String collabId, {
    required String uid,
    required CollabRole role,
  }) async {
    log.add('join');
    if (joinError case final e?) throw e;
  }

  @override
  Future<CollabRecipeEntity?> getCollab(String collabId) async {
    log.add('get');
    return collab;
  }

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

final invite = ShareInviteEntity(
  id: 'collab-1_me',
  collabId: 'collab-1',
  recipeTitle: 'שקשוקה',
  ownerUid: 'owner',
  targetUid: 'me',
  role: CollabRole.viewer,
  status: ShareInviteStatus.pending,
  createdAt: DateTime(2026, 1, 1),
);

CollabRecipeEntity remote() => CollabRecipeEntity(
  id: 'collab-1',
  ownerUid: 'owner',
  members: const {},
  recipe: RecipeEntity(
    id: 'collab-1',
    title: 'שקשוקה',
    ingredients: const [],
    steps: const ['מטגנים'],
    createdAt: DateTime(2026, 1, 1),
  ),
  updatedAt: DateTime(2026, 1, 1),
);

void main() {
  late _FakeRemote remoteSource;
  late RecipeSharingRepositoryImpl repository;

  setUp(() {
    remoteSource = _FakeRemote();
    repository = RecipeSharingRepositoryImpl(remoteDataSource: remoteSource);
  });

  group('acceptInvite', () {
    test('accepts, joins, then reads the document back', () async {
      remoteSource.collab = remote();
      final collab = await repository.acceptInvite(invite);
      expect(collab.id, 'collab-1');
      expect(remoteSource.log, ['status:accepted', 'join', 'get']);
    });

    for (final code in ['not-found', 'permission-denied']) {
      test(
        'a join refused with $code means the document is gone: the invite '
        'is closed and the caller told so',
        () async {
          remoteSource.joinError = FirebaseException(
            plugin: 'cloud_firestore',
            code: code,
          );
          await expectLater(
            repository.acceptInvite(invite),
            throwsA(predicate(RecipeSharingRepository.isCollabMissing)),
          );
          expect(remoteSource.log, [
            'status:accepted',
            'join',
            'status:declined',
          ]);
        },
      );
    }

    test(
      'any other failure is thrown as it is, and nothing is closed',
      () async {
        remoteSource.joinError = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unavailable',
        );
        await expectLater(
          repository.acceptInvite(invite),
          throwsA(isA<FirebaseException>()),
        );
        expect(remoteSource.log, ['status:accepted', 'join']);
      },
    );
  });
}
