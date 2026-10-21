import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/collab_containers/domain/container_sharing_service.dart';
import 'package:easy_plate/features/collab_containers/domain/entities/collab_container_entity.dart';
import 'package:easy_plate/features/collab_containers/domain/repositories/collab_containers_repository.dart';
import 'package:easy_plate/features/grocery_list/domain/repositories/grocery_lists_repository.dart';
import 'package:easy_plate/features/meal_planner/domain/repositories/meal_plans_repository.dart';
import 'package:easy_plate/features/my_recipes/domain/repositories/recipes_repository.dart';
import 'package:easy_plate/features/recipe_books/domain/repositories/recipe_books_repository.dart';
import 'package:easy_plate/features/recipe_sharing/domain/repositories/recipe_sharing_repository.dart';
import 'package:easy_plate/features/user_profile/domain/repositories/user_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _Containers implements CollabContainersRepository {
  final log = <String>[];
  @override
  Future<CollabContainerEntity?> get(String id) async => CollabContainerEntity(
    id: id,
    kind: CollabKind.book,
    ownerUid: 'owner',
    members: const {'m': CollabRole.editor},
    title: 'Book',
    content: const {
      'recipes': [
        {'collabId': 'r1'},
        {'collabId': 'r2'},
      ],
    },
    updatedAt: DateTime(2026),
  );
  @override
  Future<void> removeMember(
    String containerId,
    String memberUid, {
    bool revokeInvite = false,
  }) async => log.add('$containerId:$memberUid:$revokeInvite');
  @override
  noSuchMethod(Invocation i) => throw UnimplementedError('${i.memberName}');
}

class _Sharing implements RecipeSharingRepository {
  final log = <String>[];
  @override
  Future<void> removeMember(
    String collabId,
    String memberUid, {
    bool revokeInvite = false,
  }) async {
    if (collabId == 'r1') throw StateError('permission-denied');
    log.add('$collabId:$memberUid:$revokeInvite');
  }

  @override
  noSuchMethod(Invocation i) => throw UnimplementedError('${i.memberName}');
}

class _NoRecipesRepository implements RecipesRepository {
  @override
  noSuchMethod(Invocation i) => throw UnimplementedError('${i.memberName}');
}

class _NoUserProfileRepository implements UserProfileRepository {
  @override
  noSuchMethod(Invocation i) => throw UnimplementedError('${i.memberName}');
}

class _NoRecipeBooksRepository implements RecipeBooksRepository {
  @override
  noSuchMethod(Invocation i) => throw UnimplementedError('${i.memberName}');
}

class _NoMealPlansRepository implements MealPlansRepository {
  @override
  noSuchMethod(Invocation i) => throw UnimplementedError('${i.memberName}');
}

class _NoGroceryListsRepository implements GroceryListsRepository {
  @override
  noSuchMethod(Invocation i) => throw UnimplementedError('${i.memberName}');
}

void main() {
  late _Containers containers;
  late _Sharing sharing;
  late ContainerSharingService service;

  setUp(() {
    containers = _Containers();
    sharing = _Sharing();
    service = ContainerSharingService(
      stillSignedIn: (_) => true,
      containers: containers,
      sharing: sharing,
      recipes: _NoRecipesRepository(),
      profiles: _NoUserProfileRepository(),
      booksRepository: _NoRecipeBooksRepository(),
      plansRepository: _NoMealPlansRepository(),
      listsRepository: _NoGroceryListsRepository(),
    );
  });

  test(
    'the owner removing someone revokes the container and recipe invites',
    () async {
      await service.removeMember('c1', 'm', revokeInvite: true);
      expect(containers.log, ['c1:m:true']);
      // r1 is another editor's: refused, and the rest still went.
      expect(sharing.log, ['r2:m:true']);
    },
  );

  test('a member leaving keeps the invites (nothing to revoke)', () async {
    await service.removeMember('c1', 'm');
    expect(containers.log, ['c1:m:false']);
    expect(sharing.log, ['r2:m:false']);
  });
}
