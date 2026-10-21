import 'dart:async';

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
import 'package:easy_plate/features/recipe_sharing/data/datasources/pending_accepts_store.dart';
import 'package:easy_plate/features/recipe_sharing/domain/entities/collab_recipe_entity.dart';
import 'package:easy_plate/features/recipe_sharing/domain/entities/share_invite_entity.dart';
import 'package:easy_plate/features/recipe_sharing/domain/repositories/recipe_sharing_repository.dart';
import 'package:easy_plate/features/recipe_sharing/domain/usecases/share_recipe_usecase.dart';
import 'package:easy_plate/features/user_profile/domain/entities/public_profile_entity.dart';
import 'package:easy_plate/features/user_profile/domain/repositories/user_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const owner = 'owner-uid';
const friend = 'friend-uid';

RecipeEntity recipe(String id, {String? collabId, CollabRole? role}) =>
    RecipeEntity(
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
  _Recipes(Iterable<RecipeEntity> initial)
    : stored = {for (final r in initial) r.id: r};

  /// Runs on a read of the box, standing in for something happening while
  /// a shared item's recipes are being resolved.
  void Function()? onRead;

  @override
  Future<List<RecipeEntity>> getRecipes() async {
    onRead?.call();
    return stored.values.toList();
  }

  @override
  Future<RecipeEntity?> getRecipeById(String id) async => stored[id];
  @override
  Future<void> saveRecipe(
    RecipeEntity recipe, {
    bool stampLanguage = true,
  }) async => stored[recipe.id] = recipe;
  @override
  Future<RecipeEntity> readyForSharing(
    RecipeEntity recipe, {
    bool persist = true,
  }) async => recipe;
  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Sharing implements RecipeSharingRepository {
  final log = <String>[];

  /// Runs while a recipe's document is written, standing in for a save
  /// made meanwhile.
  void Function()? onEnsure;
  var next = 0;
  final Map<String, CollabRecipeEntity> collabs = {};

  @override
  Future<String> ensureCollab(
    RecipeEntity recipe, {
    required String ownerUid,
  }) async {
    if (recipe.collabId case final id?) return id;
    onEnsure?.call();
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

  /// Runs on a document read, standing in for something happening while
  /// the recipes are fetched.
  void Function()? onGetCollab;

  @override
  Future<CollabRecipeEntity?> getCollab(String collabId) async {
    onGetCollab?.call();
    return collabs[collabId];
  }

  @override
  Future<void> removeMember(
    String collabId,
    String memberUid, {
    bool revokeInvite = false,
  }) async =>
      log.add('rm:$collabId:$memberUid${revokeInvite ? ':revoke' : ''}');
  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Containers implements CollabContainersRepository {
  final log = <String>[];
  final Map<String, CollabContainerEntity> docs = {};
  final Map<String, ShareInviteEntity> invitesById = {};
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
  Future<void> write(
    String id, {
    required String title,
    required Map<String, dynamic> content,
    required String byUid,
  }) async {
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

  /// A delete that never completes, as Firestore leaves one offline.
  bool stallDelete = false;

  @override
  Future<void> delete(String id) {
    log.add('delete:$id');
    return stallDelete ? Completer<void>().future : Future.value();
  }

  @override
  Future<void> invite({
    required CollabContainerEntity container,
    required String targetUid,
    required CollabRole role,
    required List<RecipeInvite> recipes,
  }) async => log.add(
    'invite:${container.id}:$targetUid:${role.name}:${recipes.map((r) => r.collabId).join(',')}',
  );

  @override
  Future<void> inviteToRecipes({
    required String containerId,
    required Map<String, CollabRole> participants,
    required List<RecipeInvite> recipes,
    required String byUid,
  }) async => log.add(
    'recipeInvites:${participants.keys.join(',')}:${recipes.map((r) => r.collabId).join(',')}',
  );

  @override
  Future<ShareInviteEntity?> recipeInvite({
    required String collabId,
    required String uid,
  }) async => invitesById['${collabId}_$uid'];

  /// How many batched invite reads were asked for.
  int inviteReads = 0;

  @override
  Future<Map<String, ShareInviteEntity>> recipeInvites({
    required Set<String> collabIds,
    required String uid,
  }) async {
    inviteReads++;
    return {
      for (final collabId in collabIds)
        collabId: ?invitesById['${collabId}_$uid'],
    };
  }

  /// An accept that never answers, as Firestore holds a queued write
  /// offline.
  bool stallAccept = false;

  @override
  Future<CollabContainerEntity> acceptInvite(ShareInviteEntity invite) async {
    log.add('accept:${invite.id}');
    if (stallAccept) return Completer<CollabContainerEntity>().future;
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
  Future<List<CollabContainerEntity>> ownedBy(String uid) async =>
      docs.values.where((d) => d.ownerUid == uid).toList();
  @override
  Future<List<CollabContainerEntity>> sharedWith(String uid) async =>
      docs.values.where((d) => d.members.containsKey(uid)).toList();
  @override
  Future<void> removeMember(
    String containerId,
    String memberUid, {
    bool revokeInvite = false,
  }) async => log.add(
    'leave:$containerId:$memberUid${revokeInvite ? ':revoke' : ''}',
  );
}

class _Profiles implements UserProfileRepository {
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
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Books implements RecipeBooksRepository {
  final Map<String, RecipeBookEntity> stored = {};
  @override
  Future<List<RecipeBookEntity>> getBooks() async => stored.values.toList();
  @override
  Stream<List<RecipeBookEntity>> watchBooks() => const Stream.empty();
  @override
  Future<RecipeBookEntity?> getBookById(String id) async => stored[id];
  @override
  Future<void> saveBook(
    RecipeBookEntity book, {
    bool stampLanguage = true,
  }) async => stored[book.id] = book;
  @override
  Future<void> deleteBook(String id) async => stored.remove(id);

  /// Runs while the cover travels, standing in for a save made meanwhile.
  void Function()? onUpload;

  /// Stands in for the cover upload: a picked cover gains its bucket path,
  /// written onto the stored book as the real repository does.
  @override
  Future<RecipeBookEntity> readyForSharing(RecipeBookEntity book) async {
    onUpload?.call();
    if (book.coverImageFileName == null || book.coverImageStoragePath != null) {
      return book;
    }
    final path = 'users/o/${book.coverImageFileName}';
    final current = stored[book.id];
    if (current != null &&
        current.coverImageFileName == book.coverImageFileName) {
      stored[book.id] = current.copyWith(coverImageStoragePath: path);
    }
    return book.copyWith(coverImageStoragePath: path);
  }
}

class _Plans implements MealPlansRepository {
  final Map<String, MealPlanEntity> stored = {};
  @override
  Future<List<MealPlanEntity>> getPlans() async => stored.values.toList();
  @override
  Stream<List<MealPlanEntity>> watchPlans() => const Stream.empty();
  @override
  Future<MealPlanEntity?> getPlanById(String id) async => stored[id];
  @override
  Future<void> savePlan(
    MealPlanEntity plan, {
    bool stampLanguage = true,
  }) async => stored[plan.id] = plan;
  @override
  Future<void> deletePlan(String id) async => stored.remove(id);
}

RecipeBookEntity book({
  String? collabId,
  CollabRole? role,
  List<String> recipeIds = const ['r1', 'r2'],
}) => RecipeBookEntity(
  id: 'book-1',
  title: 'Weeknights',
  recipeRefs: [
    for (var i = 0; i < recipeIds.length; i++)
      BookRecipeRefEntity(recipeId: recipeIds[i], order: i),
  ],
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

  /// The account the boxes belong to; a test switches it mid-pull.
  var signedIn = friend;
  bool stillSignedIn(String uid) => uid == signedIn || uid == owner;

  ContainerCollab<RecipeBookEntity> bookCollab() => ContainerCollab(
    adapter: BookContainerAdapter(books),
    containers: containers,
    linker: RecipeLinker(
      sharing: sharing,
      recipes: recipes,
      containers: containers,
      pending: InMemoryPendingAcceptsStore(),
    ),
    profiles: profiles,
    pending: InMemoryPendingAcceptsStore(),
    stillSignedIn: stillSignedIn,
  );
  ContainerCollab<MealPlanEntity> planCollab() => ContainerCollab(
    adapter: PlanContainerAdapter(plans),
    containers: containers,
    linker: RecipeLinker(
      sharing: sharing,
      recipes: recipes,
      containers: containers,
      pending: InMemoryPendingAcceptsStore(),
    ),
    profiles: profiles,
    pending: InMemoryPendingAcceptsStore(),
    stillSignedIn: stillSignedIn,
  );

  setUp(() {
    signedIn = friend;
    recipes = _Recipes([
      recipe('r1'),
      recipe('r2', collabId: 'rc-old', role: CollabRole.owner),
    ]);
    sharing = _Sharing();
    containers = _Containers();
    profiles = _Profiles()..directory['friend@x.com'] = friend;
    books = _Books();
    plans = _Plans();
  });

  group('share', () {
    test(
      'makes every own recipe shared, creates the container and invites into all of them',
      () async {
        books.stored['book-1'] = book();
        final owned = await bookCollab().share(
          book(),
          contact: 'friend@x.com',
          role: CollabRole.editor,
          ownerUid: owner,
        );

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
        expect(
          containers.log.last,
          'invite:container-1:$friend:editor:rc-0,rc-old',
        );
      },
    );

    test(
      'pass 8: a first share marks the book as stored now, keeping a save '
      'made while the cover travelled',
      () async {
        books.stored['book-1'] = book();
        books.onUpload = () => books.stored['book-1'] = books.stored['book-1']!
            .copyWith(title: 'Renamed meanwhile');
        await bookCollab().share(
          book(),
          contact: 'friend@x.com',
          role: CollabRole.viewer,
          ownerUid: owner,
        );
        expect(books.stored['book-1']!.title, 'Renamed meanwhile');
        expect(books.stored['book-1']!.collabId, 'container-1');
      },
    );

    test(
      'pass 8: a recipe linked into a share keeps an edit saved while its '
      'document was written',
      () async {
        books.stored['book-1'] = book();
        sharing.onEnsure = () =>
            recipes.stored['r1'] = recipe('r1').copyWith(title: 'Edited');
        await bookCollab().share(
          book(),
          contact: 'friend@x.com',
          role: CollabRole.viewer,
          ownerUid: owner,
        );
        expect(recipes.stored['r1']!.title, 'Edited');
        expect(recipes.stored['r1']!.collabId, 'rc-0');
      },
    );

    test('a first share waits for the cover, so its path travels', () async {
      final covered = book().copyWith(coverImageFileName: 'cover.jpg');
      books.stored['book-1'] = covered;
      final owned = await bookCollab().share(
        covered,
        contact: 'friend@x.com',
        role: CollabRole.viewer,
        ownerUid: owner,
      );

      final content = containers.docs['container-1']!.content;
      expect(content['coverImageStoragePath'], 'users/o/cover.jpg');
      expect(owned.coverImageStoragePath, 'users/o/cover.jpg');
    });

    test('refuses a contact that is not found, and oneself', () async {
      expect(
        () => bookCollab().share(
          book(),
          contact: 'nobody@x.com',
          role: CollabRole.viewer,
          ownerUid: owner,
        ),
        throwsA(
          isA<ShareFailure>().having(
            (f) => f.code,
            'code',
            ShareFailure.notFound,
          ),
        ),
      );
      profiles.directory['me@x.com'] = owner;
      expect(
        () => bookCollab().share(
          book(),
          contact: 'me@x.com',
          role: CollabRole.viewer,
          ownerUid: owner,
        ),
        throwsA(
          isA<ShareFailure>().having((f) => f.code, 'code', ShareFailure.self),
        ),
      );
    });

    test(
      'a copy from before the first share adopts the stored document rather '
      'than creating a second one',
      () async {
        // The sheet holds the book as it opened it; a share code made in
        // between already created the container and re-pointed the book.
        books.stored['book-1'] = book(
          collabId: 'container-1',
          role: CollabRole.owner,
        );
        containers.docs['container-1'] = CollabContainerEntity(
          id: 'container-1',
          kind: CollabKind.book,
          ownerUid: owner,
          members: const {},
          title: 'Weeknights',
          content: const {},
          updatedAt: DateTime(2026),
        );
        final owned = await bookCollab().share(
          book(),
          contact: 'friend@x.com',
          role: CollabRole.viewer,
          ownerUid: owner,
        );
        expect(owned.collabId, 'container-1');
        expect(containers.docs.keys, ['container-1'], reason: 'no second doc');
        expect(containers.log.where((l) => l.startsWith('create')), isEmpty);
      },
    );

    test('a member cannot share on', () async {
      expect(
        () => bookCollab().share(
          book(collabId: 'c', role: CollabRole.editor),
          contact: 'friend@x.com',
          role: CollabRole.viewer,
          ownerUid: friend,
        ),
        throwsStateError,
      );
    });
  });

  test(
    'ensureContainer writes the stored copy, not the one the sheet held',
    () async {
      containers.docs['container-1'] = CollabContainerEntity(
        id: 'container-1',
        kind: CollabKind.book,
        ownerUid: owner,
        members: const {friend: CollabRole.editor},
        title: 'Weeknights',
        content: const {},
        updatedAt: DateTime(2026),
      );
      final held = book(collabId: 'container-1', role: CollabRole.owner);
      // A co-editor's change pulled in after the sheet opened.
      books.stored[held.id] = held.copyWith(title: 'Renamed by friend');

      await bookCollab().ensureContainer(held, ownerUid: owner);
      expect(containers.docs['container-1']!.title, 'Renamed by friend');
    },
  );

  group('publish', () {
    test(
      'rewrites the document and lets participants into recipes new to it',
      () async {
        containers.docs['container-1'] = CollabContainerEntity(
          id: 'container-1',
          kind: CollabKind.book,
          ownerUid: owner,
          members: const {friend: CollabRole.editor},
          title: 'Weeknights',
          content: const {
            'recipes': [
              {'collabId': 'rc-old', 'order': 0},
            ],
          },
          updatedAt: DateTime(2026),
        );
        await bookCollab().publish(
          book(collabId: 'container-1', role: CollabRole.owner),
          uid: owner,
        );

        expect(containers.log, contains('write:container-1'));
        // r1 is new to the share: both of the owner's recipes are offered, the
        // datasource skips the invites that already exist.
        expect(containers.log.last, 'recipeInvites:$owner,$friend:rc-0,rc-old');
      },
    );

    test('a viewer is refused', () async {
      expect(
        () => bookCollab().publish(
          book(collabId: 'container-1', role: CollabRole.viewer),
          uid: friend,
        ),
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
    test(
      'joins, lets itself into each recipe, and builds the local plan with local recipe ids',
      () async {
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
                  {
                    'id': 'i2',
                    'recipeCollabId': 'rc-missing',
                    'label': 'Secret dish',
                  },
                  {
                    'id': 'i3',
                    'freeText': 'Salad',
                    'ingredients': [
                      {'name': 'tomato', 'amount': 2, 'unit': 'piece'},
                    ],
                  },
                ],
              },
            ],
          },
          updatedAt: DateTime(2026),
        );
        containers.invitesById['rc-a_$friend'] = ShareInviteEntity(
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
        // The recipe was accepted and cached locally under a fresh id,
        // after one batched read of the invites rather than one per recipe.
        expect(sharing.log, ['acceptRecipe:rc-a']);
        expect(containers.inviteReads, 1);
        final local = recipes.stored.values.single;
        expect(local.collabId, 'rc-a');
        final items = plan.meals.single.items;
        expect(items[0].recipeId, local.id);
        // A recipe this account was never let into degrades to its label.
        expect(items[1].recipeId, isNull);
        expect(items[1].freeText, 'Secret dish');
        expect(items[2].freeText, 'Salad');
        expect(items[2].ingredients.single.name, 'tomato');
      },
    );
  });

  group('accept bound', () {
    final invite = ShareInviteEntity(
      id: 'book-c_$friend',
      collabId: 'book-c',
      recipeTitle: 'Dinners',
      ownerUid: owner,
      targetUid: friend,
      role: CollabRole.viewer,
      status: ShareInviteStatus.pending,
      createdAt: DateTime(2026),
      kind: CollabKind.book,
    );
    CollabContainerEntity doc({Map<String, CollabRole> members = const {}}) =>
        CollabContainerEntity(
          id: 'book-c',
          kind: CollabKind.book,
          ownerUid: owner,
          members: members,
          title: 'Dinners',
          content: const {'recipes': []},
          updatedAt: DateTime(2026),
        );
    late InMemoryPendingAcceptsStore pending;
    ContainerCollab<RecipeBookEntity> bound() => ContainerCollab(
      adapter: BookContainerAdapter(books),
      containers: containers,
      linker: RecipeLinker(
        sharing: sharing,
        recipes: recipes,
        containers: containers,
        pending: pending,
      ),
      profiles: profiles,
      pending: pending,
      acceptTimeout: const Duration(milliseconds: 20),
      stillSignedIn: stillSignedIn,
    );

    setUp(() {
      pending = InMemoryPendingAcceptsStore();
      containers.docs['book-c'] = doc();
    });

    test('a finished accept leaves no mark', () async {
      final book = await bound().accept(invite, uid: friend);
      expect(book.collabId, 'book-c');
      expect(pending.entries, isEmpty);
    });

    test(
      'a server that does not answer is reported as queued and the mark kept, '
      'so the next refresh can write the copy',
      () async {
        containers.stallAccept = true;
        await expectLater(
          bound().accept(invite, uid: friend),
          throwsA(predicate(RecipeSharingRepository.isAcceptQueued)),
        );
        expect(books.stored, isEmpty, reason: 'no copy without the document');
        expect(pending.entries['book-c']!.kind, CollabKind.book);

        // Later, online: the roster write landed and the document reads.
        containers.docs['book-c'] = doc(members: {friend: CollabRole.viewer});
        final collab = bound();
        expect(await collab.holds('book-c'), isFalse);
        final book = await collab.adopt(
          containers.docs['book-c']!,
          uid: friend,
        );
        expect(book.collabId, 'book-c');
        expect(book.collabRole, CollabRole.viewer);
        expect(await collab.holds('book-c'), isTrue);
      },
    );
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
      books.stored[local.id] = local;
      containers.getError = Exception(
        '[cloud_firestore/permission-denied] Missing or insufficient permissions.',
      );
      final result = await bookCollab().sync(local, uid: friend);
      expect(result.collabId, isNull);
    });

    test(
      'pass 8: a copy deleted during the read is not brought back',
      () async {
        final local = book(collabId: 'gone', role: CollabRole.editor);
        final result = await bookCollab().sync(local, uid: friend);
        expect(identical(result, local), isTrue);
        expect(books.stored, isEmpty);
      },
    );

    test('an unchanged document leaves the copy as it is', () async {
      final local = book(
        collabId: 'c',
        role: CollabRole.owner,
        recipeIds: const ['r2'],
      );
      books.stored[local.id] = local;
      containers.docs['c'] = CollabContainerEntity(
        id: 'c',
        kind: CollabKind.book,
        ownerUid: owner,
        members: const {},
        title: 'Weeknights',
        content: const {
          'recipes': [
            {'collabId': 'rc-old', 'order': 0},
          ],
        },
        updatedAt: DateTime(2026),
      );
      final result = await bookCollab().sync(local, uid: owner);
      expect(identical(result, local), isTrue);
    });

    test(
      "a member's edit keeps the owner's recipes the document never had, "
      'and drops a shared one the member removed',
      () async {
        recipes.stored['r3'] = recipe(
          'r3',
          collabId: 'rc-3',
          role: CollabRole.owner,
        );
        // r1 has no collab id (it could not be shared), r2 and r3 do.
        final local = book(
          collabId: 'c',
          role: CollabRole.owner,
          recipeIds: const ['r1', 'r2', 'r3'],
        );
        books.stored[local.id] = local;
        containers.docs['c'] = CollabContainerEntity(
          id: 'c',
          kind: CollabKind.book,
          ownerUid: owner,
          members: const {friend: CollabRole.editor},
          title: 'Renamed by friend',
          content: const {
            'recipes': [
              {'collabId': 'rc-old', 'order': 0},
            ],
          },
          updatedAt: DateTime(2026),
        );
        final result = await bookCollab().sync(local, uid: owner);
        expect(result.title, 'Renamed by friend');
        expect(result.recipeRefs.map((r) => r.recipeId).toSet(), {'r1', 'r2'});
        expect(
          books.stored[local.id]!.recipeRefs.map((r) => r.recipeId).toSet(),
          {'r1', 'r2'},
        );
      },
    );
  });

  group('refresh', () {
    test(
      'rewrites only the copies whose document changed, and never orphans',
      () async {
        books.stored['book-1'] = book(
          collabId: 'c',
          role: CollabRole.viewer,
          recipeIds: const ['r2'],
        );
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
            content: const {
              'recipes': [
                {'collabId': 'rc-old', 'order': 0},
              ],
            },
            updatedAt: DateTime(2026),
          ),
        ];
        final rewritten = await bookCollab().refresh(fetched, uid: friend);
        expect(rewritten, 1);
        expect(books.stored['book-1']!.title, 'Renamed');
        expect(books.stored['book-2']!.collabId, 'not-in-answer');
      },
    );

    test(
      'a sign-in to another account mid-pull stops the pull before it writes',
      () async {
        books.stored['book-1'] = book(
          collabId: 'c',
          role: CollabRole.viewer,
          recipeIds: const ['r2'],
        );
        final fetched = [
          CollabContainerEntity(
            id: 'c',
            kind: CollabKind.book,
            ownerUid: owner,
            members: const {friend: CollabRole.viewer},
            title: 'Renamed',
            content: const {
              'recipes': [
                {'collabId': 'rc-old', 'order': 0},
              ],
            },
            updatedAt: DateTime(2026),
          ),
        ];
        // The other account signs in while the recipes are being resolved.
        recipes.onRead = () => signedIn = 'account-b';
        final rewritten = await bookCollab().refresh(fetched, uid: friend);
        expect(rewritten, 0);
        expect(books.stored['book-1']!.title, isNot('Renamed'));
      },
    );
  });

  group('retire', () {
    test('the owner deletes the document, a member leaves it', () async {
      await bookCollab().retire(
        book(collabId: 'c', role: CollabRole.owner),
        uid: owner,
      );
      await bookCollab().retire(
        book(collabId: 'c', role: CollabRole.editor),
        uid: friend,
      );
      expect(containers.log, ['delete:c', 'leave:c:$friend']);
    });

    test(
      'pass 8: an offline delete does not hold the local delete up',
      () async {
        containers.stallDelete = true;
        final collab = ContainerCollab<RecipeBookEntity>(
          adapter: BookContainerAdapter(books),
          containers: containers,
          linker: RecipeLinker(
            sharing: sharing,
            recipes: recipes,
            containers: containers,
          ),
          profiles: profiles,
          remoteWriteTimeout: const Duration(milliseconds: 10),
        );
        await collab.retire(
          book(collabId: 'c', role: CollabRole.owner),
          uid: owner,
        );
        expect(containers.log, ['delete:c']);
      },
    );
  });

  test('plan codec round-trips through the adapter', () {
    final adapter = PlanContainerAdapter(plans);
    final plan = MealPlanEntity(
      id: 'p',
      name: 'W',
      meals: [
        const MealEntity(
          id: 'm',
          weekday: 2,
          name: 'Lunch',
          order: 1,
          items: [
            MealItemEntity(id: 'a', recipeId: 'r2'),
            MealItemEntity(id: 'b', freeText: 'Toast'),
          ],
        ),
      ],
      createdAt: DateTime(2026),
      contentLang: 'he',
      contentVersion: 3,
    );
    final content = adapter.encode(
      plan,
      collabIdByRecipeId: {'r2': 'rc-old'},
      titles: {'r2': 'Recipe r2'},
    );
    final container = CollabContainerEntity(
      id: 'c',
      kind: CollabKind.mealPlan,
      ownerUid: owner,
      members: const {},
      title: 'W',
      content: content,
      updatedAt: DateTime(2026),
    );
    final back = adapter.decode(
      container,
      local: plan,
      recipeIdByCollabId: {'rc-old': 'r2'},
      uid: owner,
    );
    expect(back.id, 'p');
    expect(back.contentLang, 'he');
    expect(back.contentVersion, 3);
    expect(back.meals.single.weekday, 2);
    expect(back.meals.single.items[0].recipeId, 'r2');
    expect(back.meals.single.items[1].freeText, 'Toast');
    expect(back.collabRole, CollabRole.owner);
  });

  test("plan decode keeps the owner's recipe that went across as a label", () {
    final adapter = PlanContainerAdapter(plans);
    final plan = MealPlanEntity(
      id: 'p',
      name: 'W',
      meals: [
        const MealEntity(
          id: 'm',
          weekday: 2,
          name: 'Lunch',
          order: 1,
          items: [
            MealItemEntity(id: 'a', recipeId: 'r1'),
            MealItemEntity(id: 'b', recipeId: 'r2'),
          ],
        ),
      ],
      createdAt: DateTime(2026),
    );
    // r1 could not be shared: it travels as a quick entry under its title.
    final content = adapter.encode(
      plan,
      collabIdByRecipeId: {'r2': 'rc-old'},
      titles: {'r1': 'Recipe r1', 'r2': 'Recipe r2'},
    );
    final container = CollabContainerEntity(
      id: 'c',
      kind: CollabKind.mealPlan,
      ownerUid: owner,
      members: const {friend: CollabRole.editor},
      title: 'W',
      content: content,
      updatedAt: DateTime(2026),
    );
    final back = adapter.decode(
      container,
      local: plan,
      recipeIdByCollabId: {'rc-old': 'r2'},
      uid: owner,
    );
    expect(back.meals.single.items[0].recipeId, 'r1');
    expect(back.meals.single.items[0].freeText, isNull);
    expect(back.meals.single.items[1].recipeId, 'r2');

    // On the member's side (no local copy) the same entry is the label.
    final theirs = adapter.decode(
      container,
      local: null,
      recipeIdByCollabId: const {},
      uid: friend,
    );
    expect(theirs.meals.single.items[0].recipeId, isNull);
    expect(theirs.meals.single.items[0].freeText, 'Recipe r1');
  });
}
