import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/collab_containers/domain/container_adapter.dart';
import 'package:easy_plate/features/collab_containers/domain/entities/collab_container_entity.dart';
import 'package:easy_plate/features/collab_containers/domain/repositories/collab_containers_repository.dart';
import 'package:easy_plate/features/collab_containers/domain/usecases/container_collab.dart';
import 'package:easy_plate/features/collab_containers/domain/usecases/recipe_linker.dart';
import 'package:easy_plate/features/meal_planner/domain/entities/meal_entity.dart';
import 'package:easy_plate/features/meal_planner/domain/entities/meal_item_entity.dart';
import 'package:easy_plate/features/meal_planner/domain/entities/meal_plan_entity.dart';
import 'package:easy_plate/features/meal_planner/domain/repositories/meal_plans_repository.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/repositories/recipes_repository.dart';
import 'package:easy_plate/features/recipe_books/domain/entities/book_recipe_ref_entity.dart';
import 'package:easy_plate/features/recipe_books/domain/entities/recipe_book_entity.dart';
import 'package:easy_plate/features/recipe_books/domain/repositories/recipe_books_repository.dart';
import 'package:easy_plate/features/recipe_sharing/domain/entities/collab_recipe_entity.dart';
import 'package:easy_plate/features/recipe_sharing/domain/entities/share_invite_entity.dart';
import 'package:easy_plate/features/recipe_sharing/domain/repositories/recipe_sharing_repository.dart';
import 'package:easy_plate/features/recipe_sharing/domain/usecases/share_recipe_usecase.dart';
import 'package:easy_plate/features/user_profile/domain/entities/public_profile_entity.dart';
import 'package:easy_plate/features/user_profile/domain/repositories/user_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const owner = 'owner-uid';
const friend = 'friend-uid';

RecipeEntity recipe(String id, {String? collabId, CollabRole? role}) => RecipeEntity(
      id: id,
      title: 'Recipe $id',
      ingredients: const [],
      steps: const [],
      createdAt: DateTime(2026),
      collabId: collabId,
      collabRole: role,
    );

class _Recipes implements RecipesRepository {
  final Map<String, RecipeEntity> stored;
  _Recipes(Iterable<RecipeEntity> initial) : stored = {for (final r in initial) r.id: r};

  @override
  Future<List<RecipeEntity>> getRecipes() async => stored.values.toList();
  @override
  Future<RecipeEntity?> getRecipeById(String id) async => stored[id];
  @override
  Future<void> saveRecipe(RecipeEntity recipe) async => stored[recipe.id] = recipe;
  @override
  Future<RecipeEntity> readyForSharing(RecipeEntity recipe, {bool persist = true}) async => recipe;
  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Sharing implements RecipeSharingRepository {
  final log = <String>[];
  var next = 0;
  final Map<String, CollabRecipeEntity> collabs = {};

  @override
  Future<String> ensureCollab(RecipeEntity recipe, {required String ownerUid}) async {
    if (recipe.collabId case final id?) return id;
    final id = 'rc-${next++}';
    log.add('ensure:${recipe.id}->$id');
    collabs[id] = CollabRecipeEntity(
      id: id,
      ownerUid: ownerUid,
      members: const {},
      recipe: recipe,
      updatedAt: DateTime(2026),
    );
    return id;
  }

  @override
  Future<CollabRecipeEntity> acceptInvite(ShareInviteEntity invite) async {
    log.add('acceptRecipe:${invite.collabId}');
    return collabs[invite.collabId]!;
  }

  @override
  Future<CollabRecipeEntity?> getCollab(String collabId) async => collabs[collabId];
  @override
  Future<void> removeMember(String collabId, String memberUid) async => log.add('rm:$collabId:$memberUid');
  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Containers implements CollabContainersRepository {
  final log = <String>[];
  final Map<String, CollabContainerEntity> docs = {};
  final Map<String, ShareInviteEntity> recipeInvites = {};
  Object? getError;

  @override
  Future<String> create({
    required CollabKind kind,
    required String title,
    required Map<String, dynamic> content,
    required String ownerUid,
  }) async {
    const id = 'container-1';
    docs[id] = CollabContainerEntity(
      id: id,
      kind: kind,
      ownerUid: ownerUid,
      members: const {},
      title: title,
      content: content,
      updatedAt: DateTime(2026),
    );
    log.add('create:$id');
    return id;
  }

  @override
  Future<CollabContainerEntity?> get(String id) async {
    if (getError case final e?) throw e;
    return docs[id];
  }

  @override
  Future<void> write(String id, {required String title, required Map<String, dynamic> content, required String byUid}) async {
    final old = docs[id]!;
    docs[id] = CollabContainerEntity(
      id: id,
      kind: old.kind,
      ownerUid: old.ownerUid,
      members: old.members,
      title: title,
      content: content,
      updatedAt: DateTime(2026),
      updatedBy: byUid,
    );
    log.add('write:$id');
  }

  @override
  Future<void> delete(String id) async => log.add('delete:$id');

  @override
  Future<void> invite({
    required CollabContainerEntity container,
    required String targetUid,
    required CollabRole role,
    required List<RecipeInvite> recipes,
  }) async =>
      log.add('invite:${container.id}:$targetUid:${role.name}:${recipes.map((r) => r.collabId).join(',')}');

  @override
  Future<void> inviteToRecipes({
    required String containerId,
    required Map<String, CollabRole> participants,
    required List<RecipeInvite> recipes,
    required String byUid,
  }) async =>
      log.add('recipeInvites:${participants.keys.join(',')}:${recipes.map((r) => r.collabId).join(',')}');

  @override
  Future<ShareInviteEntity?> recipeInvite({required String collabId, required String uid}) async =>
      recipeInvites['${collabId}_$uid'];

  @override
  Future<CollabContainerEntity> acceptInvite(ShareInviteEntity invite) async {
    log.add('accept:${invite.id}');
    final old = docs[invite.collabId]!;
    return docs[invite.collabId] = CollabContainerEntity(
      id: old.id,
      kind: old.kind,
      ownerUid: old.ownerUid,
      members: {...old.members, invite.targetUid: invite.role},
      title: old.title,
      content: old.content,
      updatedAt: old.updatedAt,
    );
  }

  @override
  Future<void> declineInvite(ShareInviteEntity invite) async {}
  @override
  Future<List<CollabContainerEntity>> ownedBy(String uid) async => docs.values.where((d) => d.ownerUid == uid).toList();
  @override
  Future<List<CollabContainerEntity>> sharedWith(String uid) async =>
      docs.values.where((d) => d.members.containsKey(uid)).toList();
  @override
  Future<void> removeMember(String containerId, String memberUid) async => log.add('leave:$containerId:$memberUid');
}

class _Profiles implements UserProfileRepository {
  final directory = <String, String>{};
  @override
  Future<String?> findUidByContact(String contact) async => directory[contact];
  @override
  Future<Map<String, PublicProfileEntity>> getPublicProfiles(Set<String> uids) async => const {};
  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Books implements RecipeBooksRepository {
  final Map<String, RecipeBookEntity> stored = {};
  @override
  Future<List<RecipeBookEntity>> getBooks() async => stored.values.toList();
  @override
  Future<RecipeBookEntity?> getBookById(String id) async => stored[id];
  @override
  Future<void> saveBook(RecipeBookEntity book) async => stored[book.id] = book;
  @override
  Future<void> deleteBook(String id) async => stored.remove(id);
}

class _Plans implements MealPlansRepository {
  final Map<String, MealPlanEntity> stored = {};
  @override
  Future<List<MealPlanEntity>> getPlans() async => stored.values.toList();
  @override
  Future<MealPlanEntity?> getPlanById(String id) async => stored[id];
  @override
  Future<void> savePlan(MealPlanEntity plan) async => stored[plan.id] = plan;
  @override
  Future<void> deletePlan(String id) async => stored.remove(id);
}

RecipeBookEntity book({String? collabId, CollabRole? role, List<String> recipeIds = const ['r1', 'r2']}) =>
    RecipeBookEntity(
      id: 'book-1',
      title: 'Weeknights',
      recipeRefs: [for (var i = 0; i < recipeIds.length; i++) BookRecipeRefEntity(recipeId: recipeIds[i], order: i)],
      createdAt: DateTime(2026),
      collabId: collabId,
      collabRole: role,
    );

void main() {
  late _Recipes recipes;
  late _Sharing sharing;
  late _Containers containers;
  late _Profiles profiles;
  late _Books books;
  late _Plans plans;

  ContainerCollab<RecipeBookEntity> bookCollab() => ContainerCollab(
        adapter: BookContainerAdapter(books),
        containers: containers,
        linker: RecipeLinker(sharing: sharing, recipes: recipes, containers: containers),
        profiles: profiles,
      );
  ContainerCollab<MealPlanEntity> planCollab() => ContainerCollab(
        adapter: PlanContainerAdapter(plans),
        containers: containers,
        linker: RecipeLinker(sharing: sharing, recipes: recipes, containers: containers),
        profiles: profiles,
      );

  setUp(() {
    recipes = _Recipes([recipe('r1'), recipe('r2', collabId: 'rc-old', role: CollabRole.owner)]);
    sharing = _Sharing();
    containers = _Containers();
    profiles = _Profiles()..directory['friend@x.com'] = friend;
    books = _Books();
    plans = _Plans();
  });

  group('share', () {
    test('makes every own recipe shared, creates the container and invites into all of them', () async {
      books.stored['book-1'] = book();
      final owned = await bookCollab().share(book(), contact: 'friend@x.com', role: CollabRole.editor, ownerUid: owner);

      expect(owned.collabId, 'container-1');
      expect(owned.collabRole, CollabRole.owner);
      expect(books.stored['book-1']!.collabId, 'container-1');
      // r1 was private and got a collab; r2 already had one.
      expect(sharing.log, ['ensure:r1->rc-0']);
      expect(recipes.stored['r1']!.collabId, 'rc-0');
      expect(recipes.stored['r1']!.collabRole, CollabRole.owner);
      // Both recipes are in the document by collab id, in order.
      final doc = containers.docs['container-1']!;
      expect(doc.recipeCollabIds, {'rc-0', 'rc-old'});
      expect(containers.log.last, 'invite:container-1:$friend:editor:rc-0,rc-old');
    });

    test('refuses a contact that is not found, and oneself', () async {
      expect(
        () => bookCollab().share(book(), contact: 'nobody@x.com', role: CollabRole.viewer, ownerUid: owner),
        throwsA(isA<ShareFailure>().having((f) => f.code, 'code', ShareFailure.notFound)),
      );
      profiles.directory['me@x.com'] = owner;
      expect(
        () => bookCollab().share(book(), contact: 'me@x.com', role: CollabRole.viewer, ownerUid: owner),
        throwsA(isA<ShareFailure>().having((f) => f.code, 'code', ShareFailure.self)),
      );
    });

    test('a member cannot share on', () async {
      expect(
        () => bookCollab().share(book(collabId: 'c', role: CollabRole.editor), contact: 'friend@x.com', role: CollabRole.viewer, ownerUid: friend),
        throwsStateError,
      );
    });
  });

  group('publish', () {
    test('rewrites the document and lets participants into recipes new to it', () async {
      containers.docs['container-1'] = CollabContainerEntity(
        id: 'container-1',
        kind: CollabKind.book,
        ownerUid: owner,
        members: const {friend: CollabRole.editor},
        title: 'Weeknights',
        content: const {'recipes': [{'collabId': 'rc-old', 'order': 0}]},
        updatedAt: DateTime(2026),
      );
      await bookCollab().publish(book(collabId: 'container-1', role: CollabRole.owner), uid: owner);

      expect(containers.log, contains('write:container-1'));
      // r1 is new to the share: both of the owner's recipes are offered, the
      // datasource skips the invites that already exist.
      expect(containers.log.last, 'recipeInvites:$owner,$friend:rc-0,rc-old');
    });

    test('a viewer is refused', () async {
      expect(
        () => bookCollab().publish(book(collabId: 'container-1', role: CollabRole.viewer), uid: friend),
        throwsA(anything),
      );
      expect(containers.log, isEmpty);
    });

    test('nothing to do for a private book', () async {
      await bookCollab().publish(book(), uid: owner);
      expect(containers.log, isEmpty);
    });
  });

  group('accept', () {
    test('joins, lets itself into each recipe, and builds the local plan with local recipe ids', () async {
      recipes = _Recipes(const []);
      sharing.collabs['rc-a'] = CollabRecipeEntity(
        id: 'rc-a',
        ownerUid: owner,
        members: const {},
        recipe: recipe('x')..title,
        updatedAt: DateTime(2026),
      );
      containers.docs['plan-c'] = CollabContainerEntity(
        id: 'plan-c',
        kind: CollabKind.mealPlan,
        ownerUid: owner,
        members: const {},
        title: 'Week 1',
        content: const {
          'meals': [
            {
              'id': 'm1',
              'weekday': 0,
              'name': 'Dinner',
              'order': 0,
              'items': [
                {'id': 'i1', 'recipeCollabId': 'rc-a', 'label': 'Recipe x'},
                {'id': 'i2', 'recipeCollabId': 'rc-missing', 'label': 'Secret dish'},
                {'id': 'i3', 'freeText': 'Salad', 'ingredients': [{'name': 'tomato', 'amount': 2, 'unit': 'piece'}]},
              ],
            },
          ],
        },
        updatedAt: DateTime(2026),
      );
      containers.recipeInvites['rc-a_$friend'] = ShareInviteEntity(
        id: 'rc-a_$friend',
        collabId: 'rc-a',
        recipeTitle: 'Recipe x',
        ownerUid: owner,
        targetUid: friend,
        role: CollabRole.viewer,
        status: ShareInviteStatus.pending,
        createdAt: DateTime(2026),
        via: 'plan-c',
      );
      final invite = ShareInviteEntity(
        id: 'plan-c_$friend',
        collabId: 'plan-c',
        recipeTitle: 'Week 1',
        ownerUid: owner,
        targetUid: friend,
        role: CollabRole.viewer,
        status: ShareInviteStatus.pending,
        createdAt: DateTime(2026),
        kind: CollabKind.mealPlan,
      );

      final plan = await planCollab().accept(invite, uid: friend);

      expect(plan.collabId, 'plan-c');
      expect(plan.collabRole, CollabRole.viewer);
      expect(plan.name, 'Week 1');
      expect(plans.stored[plan.id], isNotNull);
      // The recipe was accepted and cached locally under a fresh id.
      expect(sharing.log, ['acceptRecipe:rc-a']);
      final local = recipes.stored.values.single;
      expect(local.collabId, 'rc-a');
      final items = plan.meals.single.items;
      expect(items[0].recipeId, local.id);
      // A recipe this account was never let into degrades to its label.
      expect(items[1].recipeId, isNull);
      expect(items[1].freeText, 'Secret dish');
      expect(items[2].freeText, 'Salad');
      expect(items[2].ingredients.single.name, 'tomato');
    });
  });

  group('sync', () {
    test('a document that is gone orphans the local copy', () async {
      final local = book(collabId: 'gone', role: CollabRole.editor);
      books.stored[local.id] = local;
      final result = await bookCollab().sync(local, uid: friend);
      expect(result.collabId, isNull);
      expect(result.collabRole, isNull);
      expect(books.stored[local.id]!.collabId, isNull);
    });

    test('a refused read (removed from the share) orphans too', () async {
      final local = book(collabId: 'c', role: CollabRole.viewer);
      containers.getError = Exception('[cloud_firestore/permission-denied] Missing or insufficient permissions.');
      final result = await bookCollab().sync(local, uid: friend);
      expect(result.collabId, isNull);
    });

    test('an unchanged document leaves the copy as it is', () async {
      final local = book(collabId: 'c', role: CollabRole.owner, recipeIds: const ['r2']);
      books.stored[local.id] = local;
      containers.docs['c'] = CollabContainerEntity(
        id: 'c',
        kind: CollabKind.book,
        ownerUid: owner,
        members: const {},
        title: 'Weeknights',
        content: const {'recipes': [{'collabId': 'rc-old', 'order': 0}]},
        updatedAt: DateTime(2026),
      );
      final result = await bookCollab().sync(local, uid: owner);
      expect(identical(result, local), isTrue);
    });
  });

  group('refresh', () {
    test('rewrites only the copies whose document changed, and never orphans', () async {
      books.stored['book-1'] = book(collabId: 'c', role: CollabRole.viewer, recipeIds: const ['r2']);
      books.stored['book-2'] = RecipeBookEntity(
        id: 'book-2',
        title: 'Other',
        recipeRefs: const [],
        createdAt: DateTime(2026),
        collabId: 'not-in-answer',
        collabRole: CollabRole.viewer,
      );
      final fetched = [
        CollabContainerEntity(
          id: 'c',
          kind: CollabKind.book,
          ownerUid: owner,
          members: const {friend: CollabRole.viewer},
          title: 'Renamed',
          content: const {'recipes': [{'collabId': 'rc-old', 'order': 0}]},
          updatedAt: DateTime(2026),
        ),
      ];
      final rewritten = await bookCollab().refresh(fetched, uid: friend);
      expect(rewritten, 1);
      expect(books.stored['book-1']!.title, 'Renamed');
      expect(books.stored['book-2']!.collabId, 'not-in-answer');
    });
  });

  group('retire', () {
    test('the owner deletes the document, a member leaves it', () async {
      await bookCollab().retire(book(collabId: 'c', role: CollabRole.owner), uid: owner);
      await bookCollab().retire(book(collabId: 'c', role: CollabRole.editor), uid: friend);
      expect(containers.log, ['delete:c', 'leave:c:$friend']);
    });
  });

  test('plan codec round-trips through the adapter', () {
    final adapter = PlanContainerAdapter(plans);
    final plan = MealPlanEntity(
      id: 'p',
      name: 'W',
      meals: [
        const MealEntity(id: 'm', weekday: 2, name: 'Lunch', order: 1, items: [
          MealItemEntity(id: 'a', recipeId: 'r2'),
          MealItemEntity(id: 'b', freeText: 'Toast'),
        ]),
      ],
      createdAt: DateTime(2026),
    );
    final content = adapter.encode(plan, collabIdByRecipeId: {'r2': 'rc-old'}, titles: {'r2': 'Recipe r2'});
    final container = CollabContainerEntity(
      id: 'c',
      kind: CollabKind.mealPlan,
      ownerUid: owner,
      members: const {},
      title: 'W',
      content: content,
      updatedAt: DateTime(2026),
    );
    final back = adapter.decode(container, local: plan, recipeIdByCollabId: {'rc-old': 'r2'}, uid: owner);
    expect(back.id, 'p');
    expect(back.meals.single.weekday, 2);
    expect(back.meals.single.items[0].recipeId, 'r2');
    expect(back.meals.single.items[1].freeText, 'Toast');
    expect(back.collabRole, CollabRole.owner);
  });
}
