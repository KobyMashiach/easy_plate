// Native reference renders for the web-app parity harness
// (webapp/scripts/preview). Each main screen of the app is drawn at a
// phone's 390×844 logical size, in Hebrew and the light theme, from the same
// sample data the web screenshots are taken with
// (webapp/scripts/preview/sample-data.json), and written to
//   webapp/scripts/preview/out/native/<screen>.png   (780×1688, @2x)
//
// Off by default — it writes files — and run on purpose with:
//
//   flutter test test/store_assets/web_parity_screens_test.dart \
//     --dart-define=WEB_PARITY_SCREENS=true
//
// (or `npm run preview:native` in webapp/). The screens are the app's own
// router, pages, blocs and repositories: the local collections are real
// Hive boxes filled from the sample, the account is a ready session
// (AuthSessionService.signInForTest) and the server-side parts (community,
// forum, inbox, sharing, support) are in-memory fakes answering with the
// sample's records. Nothing reaches Firebase.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/features/features_flags.dart';
import 'package:easy_plate/core/hive/user_scope.dart';
import 'package:easy_plate/core/monetization/daily_usage_model.dart';
import 'package:easy_plate/core/monetization/entitlement_service.dart';
import 'package:easy_plate/core/navigation/main_tabs.dart';
import 'package:easy_plate/core/services/auth_session_service.dart';
import 'package:easy_plate/core/services/image_storage_service.dart';
import 'package:easy_plate/core/services/notifications_service.dart';
import 'package:easy_plate/core/styles/app_theme.dart';
import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/core/utils/routing/app_router.dart';
import 'package:easy_plate/core/utils/routing/routing.dart';
import 'package:easy_plate/features/auth/domain/entities/app_user_entity.dart';
import 'package:easy_plate/features/auth/domain/repositories/auth_repository.dart';
import 'package:easy_plate/features/collab_containers/domain/container_sharing_service.dart';
import 'package:easy_plate/features/collab_containers/domain/entities/collab_container_entity.dart';
import 'package:easy_plate/features/collab_containers/domain/repositories/collab_containers_repository.dart';
import 'package:easy_plate/features/feedback/domain/entities/feedback_entity.dart';
import 'package:easy_plate/features/feedback/domain/repositories/feedback_repository.dart';
import 'package:easy_plate/features/forum/domain/entities/forum_post_entity.dart';
import 'package:easy_plate/features/forum/domain/entities/forum_reply_entity.dart';
import 'package:easy_plate/features/forum/domain/repositories/forum_repository.dart';
import 'package:easy_plate/features/grocery_list/data/datasources/grocery_lists_local_datasource.dart';
import 'package:easy_plate/features/grocery_list/data/models/grocery_list_model.dart';
import 'package:easy_plate/features/grocery_list/data/repositories_impl/grocery_lists_repository_impl.dart';
import 'package:easy_plate/features/grocery_list/domain/repositories/grocery_lists_repository.dart';
import 'package:easy_plate/features/meal_planner/data/datasources/meal_plans_local_datasource.dart';
import 'package:easy_plate/features/meal_planner/data/models/meal_plan_model.dart';
import 'package:easy_plate/features/meal_planner/data/repositories_impl/meal_plans_repository_impl.dart';
import 'package:easy_plate/features/meal_planner/domain/repositories/meal_plans_repository.dart';
import 'package:easy_plate/features/meal_planner/presentation/pages/nutrition_dashboard_page.dart';
import 'package:easy_plate/features/my_recipes/data/datasources/recipes_local_datasource.dart';
import 'package:easy_plate/features/my_recipes/data/models/recipe_model.dart';
import 'package:easy_plate/features/my_recipes/data/repositories_impl/recipes_repository_impl.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/my_recipes/domain/repositories/recipes_repository.dart';
import 'package:easy_plate/features/my_recipes/presentation/pages/recipe_details_page.dart';
import 'package:easy_plate/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:easy_plate/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:easy_plate/features/premium/domain/paywall_offer.dart';
import 'package:easy_plate/features/premium/presentation/pages/paywall_page.dart';
import 'package:easy_plate/features/price_book/data/datasources/community_prices_remote_datasource.dart';
import 'package:easy_plate/features/price_book/data/datasources/price_records_local_datasource.dart';
import 'package:easy_plate/features/price_book/data/models/price_record_model.dart';
import 'package:easy_plate/features/price_book/data/models/product_pricing_model.dart';
import 'package:easy_plate/features/price_book/data/models/receipt_model.dart';
import 'package:easy_plate/features/price_book/data/repositories_impl/price_book_repository_impl.dart';
import 'package:easy_plate/features/price_book/domain/repositories/price_book_repository.dart';
import 'package:easy_plate/features/recipe_books/data/datasources/recipe_books_local_datasource.dart';
import 'package:easy_plate/features/recipe_books/data/models/recipe_book_model.dart';
import 'package:easy_plate/features/recipe_books/data/repositories_impl/recipe_books_repository_impl.dart';
import 'package:easy_plate/features/recipe_books/domain/repositories/recipe_books_repository.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/repositories/recipe_ingestion_repository.dart';
import 'package:easy_plate/features/recipe_sharing/domain/entities/collab_recipe_entity.dart';
import 'package:easy_plate/features/recipe_sharing/domain/entities/share_invite_entity.dart';
import 'package:easy_plate/features/recipe_sharing/domain/repositories/recipe_sharing_repository.dart';
import 'package:easy_plate/features/share_codes/domain/share_code_service.dart';
import 'package:easy_plate/features/share_codes/domain/share_codes_repository.dart';
import 'package:easy_plate/features/shared_recipes/domain/entities/shared_recipe_entity.dart';
import 'package:easy_plate/features/shared_recipes/domain/repositories/shared_recipes_repository.dart';
import 'package:easy_plate/features/user_profile/data/datasources/user_preferences_local_datasource.dart';
import 'package:easy_plate/features/user_profile/data/models/user_preferences_model.dart';
import 'package:easy_plate/features/user_profile/data/repositories_impl/user_preferences_repository_impl.dart';
import 'package:easy_plate/features/user_profile/domain/entities/public_profile_entity.dart';
import 'package:easy_plate/features/user_profile/domain/entities/user_profile_entity.dart';
import 'package:easy_plate/features/user_profile/domain/repositories/user_preferences_repository.dart';
import 'package:easy_plate/features/user_profile/domain/repositories/user_profile_repository.dart';
import 'package:easy_plate/hive_registrar.g.dart';
// The Firebase plugins are built but never answer: singletons that take
// `FirebaseFirestore.instance` in a constructor need a default app to exist.
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/single_child_widget.dart';

const _enabled = bool.fromEnvironment('WEB_PARITY_SCREENS');
const _preview = 'webapp/scripts/preview';
const _outDir = '$_preview/out/native';

/// A phone: 390×844 logical points at 2×, the web shots' frame.
const _logical = Size(390, 844);
const _dpr = 2.0;

late Map<String, dynamic> _sample;
late String _uid;
final _now = DateTime.now();

DateTime _ago(num days) =>
    _now.subtract(Duration(milliseconds: (days * 86400000).round()));

Map<String, dynamic> _map(Object? v) => Map<String, dynamic>.from(v! as Map);
List<Map<String, dynamic>> _list(String key) => [
  for (final v in _sample[key] as List) _map(v),
];

List<RecipeEntity> _recipes() => [
  for (final j in _list('recipes')) RecipeModel.fromJson(j).toEntity(),
];
RecipeEntity _recipe(int index) => _recipes()[index];

String _nameOf(String uid) {
  final user = _map(_sample['user']);
  if (uid == user['uid']) return user['fullName'] as String;
  for (final p in _list('people')) {
    if (p['uid'] == uid) return p['fullName'] as String;
  }
  return '';
}

// ── Fakes for the server-side repositories ─────────────────────────────────

RecipeEntity _sharedBody(Map<String, dynamic> s) => RecipeModel.fromJson({
  'id': s['id'],
  'title': s['title'],
  'prepTimeMinutes': s['prepTimeMinutes'],
  'cookTimeMinutes': s['cookTimeMinutes'],
  'ingredients': s['ingredients'],
  'steps': s['steps'],
  'dietaryTags': s['dietaryTags'],
  'sourceChannel': null,
  'sourceUrl': null,
  'createdAt': _ago(s['daysAgo'] as num).toIso8601String(),
  'imageFileName': s['imageKey'] == null ? null : '${s['imageKey']}.jpg',
  'savedFromSharedId': null,
  'pendingAnalysis': false,
  'collabId': null,
  'collabRole': null,
  'imageStoragePath': null,
  'allergens': <String>[],
  'mayContain': <String>[],
  'servings': s['servings'],
  'nutrition': s['nutrition'],
  'sharedRecipeId': null,
  'contentLang': 'he',
  'contentVersion': 0,
}).toEntity();

List<SharedRecipeEntity> _feed() => [
  for (final s in _list('shared_recipes'))
    SharedRecipeEntity(
      id: s['id'] as String,
      recipe: _sharedBody(s),
      authorUid: s['authorUid'] as String,
      authorName: _nameOf(s['authorUid'] as String),
      createdAt: _ago(s['daysAgo'] as num),
      likeCount: s['likeCount'] as int,
      likedByMe: s['likedByMe'] as bool,
    ),
];

class _FakeSharedRecipes implements SharedRecipesRepository {
  @override
  Future<List<SharedRecipeEntity>> getFeed({
    required String viewerUid,
    int limit = 50,
    bool refresh = false,
  }) async => _feed();

  @override
  Future<SharedRecipeEntity?> getById(
    String id, {
    required String viewerUid,
  }) async => _feed().where((p) => p.id == id).firstOrNull;

  @override
  Future<List<SharedRecipeEntity>> getByAuthor(
    String authorUid, {
    int limit = 200,
  }) async => _feed().where((p) => p.authorUid == authorUid).toList();

  @override
  Future<List<SharedRecipeEntity>> getMine({
    required String viewerUid,
    int limit = 200,
    bool refresh = false,
  }) async => _feed().where((p) => p.authorUid == viewerUid).toList();

  @override
  Future<List<SharedRecipeEntity>> getByIds(
    Set<String> ids, {
    required String viewerUid,
    bool refresh = false,
  }) async => _feed().where((p) => ids.contains(p.id)).toList();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<ForumPostEntity> _posts() => [
  for (final p in _list('forum_posts'))
    ForumPostEntity(
      id: p['id'] as String,
      title: p['title'] as String,
      body: p['body'] as String,
      authorUid: p['authorUid'] as String,
      authorName: _nameOf(p['authorUid'] as String),
      createdAt: _ago(p['daysAgo'] as num),
      replyCount: (p['replies'] as List).length,
      likeCount: p['likeCount'] as int,
      likedByMe: p['likedByMe'] as bool,
    ),
];

List<ForumReplyEntity> _replies(String postId) {
  final post = _list('forum_posts').firstWhere((p) => p['id'] == postId);
  return [
    for (final r in (post['replies'] as List).map(_map))
      ForumReplyEntity(
        id: r['id'] as String,
        body: r['body'] as String,
        authorUid: r['authorUid'] as String,
        authorName: _nameOf(r['authorUid'] as String),
        createdAt: _ago(r['daysAgo'] as num),
        sharedRecipeId: r['sharedRecipeId'] as String?,
        sharedRecipeTitle: r['sharedRecipeTitle'] as String?,
        likeCount: r['likeCount'] as int,
      ),
  ];
}

class _FakeForum implements ForumRepository {
  @override
  Future<List<ForumPostEntity>> getPosts({
    required String viewerUid,
    int limit = 50,
    bool refresh = false,
  }) async => _posts();

  @override
  Stream<List<ForumPostEntity>> watchPosts({
    required String viewerUid,
    int limit = 50,
  }) => Stream.value(_posts());

  @override
  Future<ForumPostEntity?> getPost(
    String postId, {
    required String viewerUid,
  }) async => _posts().where((p) => p.id == postId).firstOrNull;

  @override
  Future<List<ForumReplyEntity>> getReplies(
    String postId, {
    required String viewerUid,
    bool refresh = false,
  }) async => _replies(postId);

  @override
  Stream<List<ForumReplyEntity>> watchReplies(
    String postId, {
    required String viewerUid,
  }) => Stream.value(_replies(postId));

  @override
  Future<ForumReplyEntity?> getReply(
    String postId,
    String replyId, {
    required String viewerUid,
  }) async => _replies(postId).where((r) => r.id == replyId).firstOrNull;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<AppNotificationEntity> _notifications() => [
  for (final n in _list('notifications'))
    AppNotificationEntity(
      id: n['id'] as String,
      type: AppNotificationType.values.byName(n['type'] as String),
      fromUid: (n['fromUid'] as String?) ?? '',
      fromName: n['fromUid'] == null ? null : _nameOf(n['fromUid'] as String),
      read: n['read'] as bool,
      createdAt: _ago(n['daysAgo'] as num),
      inviteId: n['inviteId'] as String?,
      collabId: n['collabId'] as String?,
      recipeTitle: n['recipeTitle'] as String?,
      role: n['role'] == null
          ? null
          : CollabRole.values.byName(n['role'] as String),
      kind: n['kind'] == null
          ? CollabKind.recipe
          : CollabKind.values.byName(n['kind'] as String),
      sharedId: n['sharedId'] as String?,
      message: n['message'] as String?,
      title: n['title'] as String?,
      postId: n['postId'] as String?,
      replyId: n['replyId'] as String?,
      postTitle: n['postTitle'] as String?,
      excerpt: n['excerpt'] as String?,
      onMyPost: (n['onMyPost'] as bool?) ?? false,
    ),
];

class _FakeNotifications implements NotificationsRepository {
  @override
  Stream<List<AppNotificationEntity>> watch(String uid) =>
      Stream.value(_notifications());

  @override
  Future<void> markRead(String uid, String notificationId) async {}

  @override
  Future<void> markAllRead(String uid) async {}

  @override
  Future<void> delete(String uid, String notificationId) async {}

  @override
  Future<void> deleteAll(String uid) async {}
}

class _FakeProfiles implements UserProfileRepository {
  @override
  Future<UserProfileEntity?> getProfile(String uid) async => _profile();

  @override
  Future<Map<String, PublicProfileEntity>> getPublicProfiles(
    Set<String> uids, {
    bool refresh = false,
  }) async => {
    for (final uid in uids)
      if (_nameOf(uid).isNotEmpty)
        uid: PublicProfileEntity(uid: uid, fullName: _nameOf(uid)),
  };

  @override
  Future<String?> blockMessage(String uid) async => null;

  @override
  Future<String?> findUidByContact(String contact) async => null;

  @override
  Future<void> touchDevice(
    String uid, {
    required String platform,
    String? appVersion,
  }) async {}

  @override
  Future<void> savePushToken(String uid, String token) async {}

  @override
  Future<void> publishPublicProfile(UserProfileEntity profile) async {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ShareInviteEntity _invite(Map<String, dynamic> i) => ShareInviteEntity(
  id: '${i['collabId']}_${i['targetUid']}',
  collabId: i['collabId'] as String,
  recipeTitle: i['title'] as String,
  ownerUid: i['ownerUid'] as String,
  targetUid: i['targetUid'] as String,
  role: CollabRole.values.byName(i['role'] as String),
  status: ShareInviteStatus.values.byName(i['status'] as String),
  createdAt: _ago(i['daysAgo'] as num),
  kind: i['kind'] == null
      ? CollabKind.recipe
      : CollabKind.values.byName(i['kind'] as String),
);

class _FakeSharing implements RecipeSharingRepository {
  List<CollabRecipeEntity> _collabs() => [
    for (final c in _list('collab_recipes'))
      CollabRecipeEntity(
        id: c['id'] as String,
        ownerUid: c['ownerUid'] as String,
        members: {
          for (final e in _map(c['members']).entries)
            e.key: CollabRole.values.byName(e.value as String),
        },
        recipe: c['recipeId'] == null
            ? _recipe(0).copyWith(title: _map(c['inline'])['title'] as String)
            : _recipes().firstWhere((r) => r.id == c['recipeId']),
        updatedAt: _ago(c['daysAgo'] as num),
      ),
  ];

  @override
  Future<List<ShareInviteEntity>> incomingInvites(String uid) async => [
    for (final i in _list('share_invites'))
      if (i['targetUid'] == uid && i['status'] == 'pending') _invite(i),
  ];

  @override
  Future<List<ShareInviteEntity>> outgoingInvites(String ownerUid) async => [
    for (final i in _list('share_invites'))
      if (i['ownerUid'] == ownerUid) _invite(i),
  ];

  @override
  Future<CollabRecipeEntity?> getCollab(String collabId) async =>
      _collabs().where((c) => c.id == collabId).firstOrNull;

  @override
  Future<List<CollabRecipeEntity>> collabsOwnedBy(String uid) async =>
      _collabs().where((c) => c.ownerUid == uid).toList();

  @override
  Future<List<CollabRecipeEntity>> collabsSharedWith(String uid) async =>
      _collabs().where((c) => c.members.containsKey(uid)).toList();

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeContainers implements CollabContainersRepository {
  @override
  Future<List<CollabContainerEntity>> ownedBy(String uid) async => const [];

  @override
  Future<List<CollabContainerEntity>> sharedWith(String uid) async => const [];

  @override
  Future<CollabContainerEntity?> get(String id) async => null;

  @override
  Future<Map<String, ShareInviteEntity>> recipeInvites({
    required Set<String> collabIds,
    required String uid,
  }) async => const {};

  @override
  Future<ShareInviteEntity?> recipeInvite({
    required String collabId,
    required String uid,
  }) async => null;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<FeedbackEntity> _conversations() => [
  for (final f in _list('feedback'))
    FeedbackEntity(
      id: f['id'] as String,
      type: FeedbackType.values.byName(f['type'] as String),
      message: f['message'] as String,
      authorUid: _uid,
      authorName: _nameOf(_uid),
      createdAt: _ago(f['daysAgo'] as num),
      followUps: [
        for (final l in (f['followUps'] as List).map(_map))
          FeedbackReply(
            text: l['text'] as String,
            at: _ago(l['daysAgo'] as num),
          ),
      ],
      replies: [
        for (final l in (f['replies'] as List).map(_map))
          FeedbackReply(
            text: l['text'] as String,
            at: _ago(l['daysAgo'] as num),
          ),
      ],
      userUnread: f['userUnread'] as bool,
      updatedAt: _ago(4),
    ),
];

class _FakeFeedback implements FeedbackRepository {
  @override
  Stream<List<FeedbackEntity>> watchMine(String uid) =>
      Stream.value(_conversations());

  @override
  Stream<FeedbackEntity?> watchOne(String feedbackId) => Stream.value(
    _conversations().where((c) => c.id == feedbackId).firstOrNull,
  );

  @override
  Future<void> markSeenByUser(String feedbackId) async {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeShareCodes implements ShareCodesRepository {
  @override
  noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #activeCodesFor) {
      return Future.value(const <Never>[]);
    }
    return super.noSuchMethod(invocation);
  }
}

class _FakeAuth implements AuthRepository {
  @override
  Stream<AppUserEntity?> authStateChanges() => const Stream.empty();

  @override
  AppUserEntity? get currentUser => _user();

  @override
  noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #setLanguage) return null;
    return super.noSuchMethod(invocation);
  }
}

class _FakeIngestion implements RecipeIngestionRepository {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AppUserEntity _user() {
  final u = _map(_sample['user']);
  return AppUserEntity(
    uid: u['uid'] as String,
    email: u['email'] as String,
    phoneNumber: u['phoneNumber'] as String,
    displayName: u['fullName'] as String,
    providerIds: const ['phone', 'password'],
  );
}

UserProfileEntity _profile() {
  final u = _map(_sample['user']);
  return UserProfileEntity(
    uid: u['uid'] as String,
    fullName: u['fullName'] as String,
    email: u['email'] as String,
    phoneNumber: u['phoneNumber'] as String,
    createdAt: _ago(40),
  );
}

// ── Setup ──────────────────────────────────────────────────────────────────

Future<void> _loadFonts() async {
  final jakarta = FontLoader('Plus Jakarta Sans')
    ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
  await jakarta.load();
  // Plus Jakarta Sans has no Hebrew: a phone fills it in from the system
  // through AppTextStyles.fontFamilyFallback. An iPhone's is SF Hebrew —
  // also what Safari draws the web app's Hebrew with — so that one first.
  for (final (family, path) in const [
    ('SF Hebrew', '/System/Library/Fonts/SFHebrew.ttf'),
    ('Arial Hebrew', '/System/Library/Fonts/Supplemental/Arial Hebrew.ttc'),
    // The language picker names Arabic and Russian in their own scripts.
    ('Geeza Pro', '/System/Library/Fonts/GeezaPro.ttc'),
    ('Roboto', '/System/Library/Fonts/Supplemental/Arial.ttf'),
  ]) {
    final file = File(path);
    if (!file.existsSync()) continue;
    final hebrew = FontLoader(family)
      ..addFont(file.readAsBytes().then((b) => ByteData.sublistView(b)));
    await hebrew.load();
  }
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final icons = File(
      '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (icons.existsSync()) {
      final loader = FontLoader('MaterialIcons')
        ..addFont(icons.readAsBytes().then((b) => ByteData.sublistView(b)));
      await loader.load();
    }
  }
}

/// The sample's records, into this account's real Hive boxes; its photos,
/// into the directory the app reads local pictures from.
Future<void> _fillDevice() async {
  final tmp = await Directory.systemTemp.createTemp('easyplate-parity-');
  Hive.init('${tmp.path}/hive');
  Hive.registerAdapters();
  await UserScope().switchTo(_uid);

  final scope = UserScope();
  final recipes = await scope.open<RecipeModel>(RecipeModel.hiveKey);
  for (final j in _list('recipes')) {
    final m = RecipeModel.fromJson(j);
    await recipes.put(m.id, m);
  }
  final books = await scope.open<RecipeBookModel>(RecipeBookModel.hiveKey);
  for (final j in _list('books')) {
    final m = RecipeBookModel.fromJson(j);
    await books.put(m.id, m);
  }
  final plans = await scope.open<MealPlanModel>(MealPlanModel.hiveKey);
  for (final j in _list('meal_plans')) {
    final m = MealPlanModel.fromJson(j);
    await plans.put(m.id, m);
  }
  final lists = await scope.open<GroceryListModel>(GroceryListModel.hiveKey);
  for (final j in _list('grocery_lists')) {
    final m = GroceryListModel.fromJson(j);
    await lists.put(m.id, m);
  }
  final receipts = await scope.open<ReceiptModel>(ReceiptModel.hiveKey);
  for (final j in _list('receipts')) {
    final m = ReceiptModel.fromJson(j);
    await receipts.put(m.id, m);
  }
  final prices = await scope.open<PriceRecordModel>(PriceRecordModel.hiveKey);
  for (final j in _list('price_records')) {
    final m = PriceRecordModel.fromJson(j);
    await prices.put(m.id, m);
  }
  final pricing = await scope.open<ProductPricingModel>(
    ProductPricingModel.hiveKey,
  );
  for (final j in _list('product_pricing')) {
    final m = ProductPricingModel.fromJson(j);
    await pricing.put(m.key, m);
  }
  final prefs = await scope.open<UserPreferencesModel>(
    UserPreferencesModel.hiveKey,
  );
  await prefs.put(
    UserPreferencesModel.storageKey,
    UserPreferencesModel.fromJson(_map(_sample['preferences'])),
  );
  final usage = await scope.open<DailyUsageModel>(DailyUsageModel.hiveKey);
  await usage.put(
    DailyUsageModel.storageKey,
    DailyUsageModel.fromJson(_map(_sample['usage'])),
  );

  final images = Directory('${tmp.path}/images')..createSync();
  for (final entry in _map(_sample['images']).entries) {
    File(
      '$_preview/${entry.value}',
    ).copySync('${images.path}/${entry.key}.jpg');
  }
  ImageStorageService().useDirectoryForTest(images);
}

List<SingleChildWidget> _repositories() => [
  RepositoryProvider<AuthRepository>.value(value: _FakeAuth()),
  RepositoryProvider<UserProfileRepository>.value(value: _FakeProfiles()),
  RepositoryProvider<UserPreferencesRepository>(
    create: (_) => UserPreferencesRepositoryImpl(
      localDataSource: UserPreferencesLocalDataSourceImpl(),
    ),
  ),
  RepositoryProvider<RecipesRepository>(
    create: (_) =>
        RecipesRepositoryImpl(localDataSource: RecipesLocalDataSourceImpl()),
  ),
  RepositoryProvider<RecipeBooksRepository>(
    create: (_) => RecipeBooksRepositoryImpl(
      localDataSource: RecipeBooksLocalDataSourceImpl(),
    ),
  ),
  RepositoryProvider<MealPlansRepository>(
    create: (_) => MealPlansRepositoryImpl(
      localDataSource: MealPlansLocalDataSourceImpl(),
    ),
  ),
  RepositoryProvider<GroceryListsRepository>(
    create: (_) => GroceryListsRepositoryImpl(
      localDataSource: GroceryListsLocalDataSourceImpl(),
    ),
  ),
  RepositoryProvider<PriceBookRepository>(
    create: (_) => PriceBookRepositoryImpl(
      localDataSource: PriceRecordsLocalDataSource(),
      remoteDataSource: CommunityPricesRemoteDataSource.withReader(
        (_) async => null,
      ),
    ),
  ),
  RepositoryProvider<SharedRecipesRepository>.value(
    value: _FakeSharedRecipes(),
  ),
  RepositoryProvider<ForumRepository>.value(value: _FakeForum()),
  RepositoryProvider<NotificationsRepository>.value(
    value: _FakeNotifications(),
  ),
  RepositoryProvider<RecipeSharingRepository>.value(value: _FakeSharing()),
  RepositoryProvider<CollabContainersRepository>.value(
    value: _FakeContainers(),
  ),
  RepositoryProvider<FeedbackRepository>.value(value: _FakeFeedback()),
  RepositoryProvider<RecipeIngestionRepository>.value(
    value: _FakeIngestion(),
  ),
  RepositoryProvider<ContainerSharingService>(
    create: (context) => ContainerSharingService(
      containers: context.read(),
      sharing: context.read(),
      recipes: context.read(),
      profiles: context.read(),
      booksRepository: context.read(),
      plansRepository: context.read(),
      listsRepository: context.read(),
    ),
  ),
  RepositoryProvider<ShareCodesRepository>.value(value: _FakeShareCodes()),
  RepositoryProvider<ShareCodeService>(
    create: (context) => ShareCodeService(
      codes: context.read(),
      containers: context.read(),
      sharing: context.read(),
      recipes: context.read(),
      profiles: context.read(),
    ),
  ),
];

// ── Rendering ──────────────────────────────────────────────────────────────

/// Lets the frames, the box streams and the picture decoding (real I/O,
/// outside the test's fake clock) all land.
Future<void> _settle(WidgetTester tester, {int rounds = 8}) async {
  for (var i = 0; i < rounds; i++) {
    await tester.pump(const Duration(milliseconds: 120));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 60)),
    );
  }
  await tester.pump(const Duration(milliseconds: 600));
}

/// Opens the app on [MainTabs] [tab], then runs [navigate] on its router.
Future<void> _render(
  WidgetTester tester,
  String name, {
  int tab = MainTabs.recipes,
  FutureOr<void> Function(GoRouter router)? navigate,
  FutureOr<void> Function(WidgetTester tester)? interact,
  Widget? page,
}) async {
  // Every framework error is noted next to the picture instead of failing
  // the render: a 1-px overflow from the test's Hebrew font (Arial Hebrew,
  // not the phone's) must not cost the screen. Exceptions thrown by the
  // test itself still fail it.
  final errors = <String>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) =>
      errors.add(details.exceptionAsString().split('\n').first);
  addTearDown(() => FlutterError.onError = previous);
  final errorLog = File('$_outDir/$name.errors.txt');
  if (errorLog.existsSync()) errorLog.deleteSync();

  tester.view.physicalSize = _logical * _dpr;
  tester.view.devicePixelRatio = _dpr;
  addTearDown(tester.view.reset);
  MainTabs.index.value = tab;
  addTearDown(() => MainTabs.index.value = MainTabs.recipes);

  final key = GlobalKey();
  final router = buildRouter();
  await tester.pumpWidget(
    TranslationProvider(
      child: MultiRepositoryProvider(
        providers: _repositories(),
        child: RepaintBoundary(
          key: key,
          child: page != null
              ? MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.current,
                  locale: AppLocale.he.flutterLocale,
                  supportedLocales: AppLocaleUtils.supportedLocales,
                  localizationsDelegates: GlobalMaterialLocalizations.delegates,
                  home: page,
                )
              : MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.current,
                  routerConfig: router,
                  locale: AppLocale.he.flutterLocale,
                  supportedLocales: AppLocaleUtils.supportedLocales,
                  localizationsDelegates: GlobalMaterialLocalizations.delegates,
                ),
        ),
      ),
    ),
  );
  await _settle(tester);
  if (page == null) {
    router.go(Routing.home);
    await _settle(tester);
    if (navigate != null) {
      // A push answers when its route is popped: started, never awaited.
      final pushed = navigate(router);
      if (pushed is Future) unawaited(pushed.then((_) {}, onError: (_) {}));
      await _settle(tester, rounds: 10);
    }
  }
  if (interact != null) {
    await interact(tester);
    await _settle(tester);
  }

  Future<void> capture(String file) async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: _dpr);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final out = File('$_outDir/$file');
      out.parent.createSync(recursive: true);
      out.writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  }

  // The first screenful, as a phone opens it.
  await capture('$name.png');
  // Then the whole page: the screen made as tall as the page's longest
  // vertical scroll, so everything below the fold is drawn too (bars pinned
  // to the bottom move to the bottom of the picture, as on the web shot).
  var extent = 0.0;
  for (final state in tester.stateList<ScrollableState>(
    find.byType(Scrollable),
  )) {
    final position = state.position;
    if (state.axisDirection == AxisDirection.down &&
        position.hasContentDimensions) {
      extent = extent < position.maxScrollExtent
          ? position.maxScrollExtent
          : extent;
    }
  }
  if (extent > 0) {
    final height = (_logical.height + extent).clamp(_logical.height, 8000.0);
    tester.view.physicalSize = Size(_logical.width, height) * _dpr;
    await _settle(tester);
    await capture('$name.full.png');
  } else {
    File('$_outDir/$name.png').copySync('$_outDir/$name.full.png');
  }
  // Leave nothing running into the next screen.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
  FlutterError.onError = previous;
  if (errors.isNotEmpty) {
    errorLog.writeAsStringSync('${errors.toSet().join('\n')}\n');
  }
}

String _route(String name) => '${Routing.home}/$name';

void main() {
  setUpAll(() async {
    if (!_enabled) return;
    _sample =
        jsonDecode(File('$_preview/sample-data.json').readAsStringSync())
            as Map<String, dynamic>;
    _uid = _map(_sample['user'])['uid'] as String;
    setupFirebaseCoreMocks();
    PackageInfo.setMockInitialValues(
      appName: 'Easy Plate',
      packageName: 'com.KHEasyDev.easy_plate',
      version: '1.0.1',
      buildNumber: '1',
      buildSignature: '',
    );
    await Firebase.initializeApp();
    await _loadFonts();
    await LocaleSettings.setLocale(AppLocale.he);
    await _fillDevice();
    FeaturesFlags.overrides = {
      for (final f in FeaturesFlags.values) f: FeatureFlagValue.enabled,
    };
    EntitlementService().setForTest(true);
    // As a phone that has seen this account before: the routes' feature
    // gates let it through at once instead of waiting for the server.
    EntitlementService().rememberForTest(true);
    // The plan's product names the tier: Pro Family, so the household
    // screen offers to open one, as on the web.
    EntitlementService().documentForTest({
      'premium': true,
      'productId': _map(_sample['user'])['productId'],
      'source': 'revenuecat',
    });
    AuthSessionService().resetForTest();
    AuthSessionService().signInForTest(
      _user(),
      profile: _profile(),
      preferences: UserPreferencesModel.fromJson(
        _map(_sample['preferences']),
      ).toEntity(),
    );
    // The inbox and the bell's badge read the live list through the service.
    NotificationsService().bind(_uid, _FakeNotifications());
  });

  void screen(
    String name, {
    int tab = MainTabs.recipes,
    FutureOr<void> Function(GoRouter router)? navigate,
    FutureOr<void> Function(WidgetTester tester)? interact,
    Widget Function()? page,
  }) {
    testWidgets(
      name,
      (tester) => _render(
        tester,
        name,
        tab: tab,
        navigate: navigate,
        interact: interact,
        page: page?.call(),
      ),
      skip: !_enabled,
    );
  }

  // The five tabs.
  screen('recipes_list');
  screen('library', tab: MainTabs.library);
  screen('meal_plan_board', tab: MainTabs.mealPlan);
  screen('grocery_list', tab: MainTabs.groceries);
  screen('community_feed', tab: MainTabs.community);
  screen(
    'forum',
    tab: MainTabs.community,
    interact: (tester) async {
      final tab = find.text(t.community.forum);
      if (tab.evaluate().isNotEmpty) await tester.tap(tab.first);
    },
  );

  // Pushed screens, through the app's own routes.
  screen(
    'recipe_details',
    navigate: (r) => r.pushNamed(
      Routing.recipeDetails,
      extra: RecipeDetailsArgs(recipe: _recipe(1)),
    ),
  );
  screen(
    'community_recipe',
    tab: MainTabs.community,
    navigate: (r) => r.pushNamed(
      Routing.recipeDetails,
      extra: RecipeDetailsArgs(recipe: _feed().first.recipe, readOnly: true),
    ),
  );
  screen('add_recipe', navigate: (r) => r.pushNamed(Routing.ingestion));
  screen(
    'book_viewer',
    tab: MainTabs.library,
    navigate: (r) => r.push(
      _route(Routing.bookDetails),
      extra: _list('books').first['id'] as String,
    ),
  );
  screen(
    'nutrition_dashboard',
    tab: MainTabs.mealPlan,
    navigate: (r) => r.pushNamed(
      Routing.nutritionDashboard,
      extra: NutritionDashboardArgs(
        plan: MealPlanModel.fromJson(_list('meal_plans').first).toEntity(),
        recipes: {for (final rec in _recipes()) rec.id: rec},
      ),
    ),
  );
  screen('price_book', navigate: (r) => r.pushNamed(Routing.priceBook));
  screen(
    'receipt_details',
    navigate: (r) => r.pushNamed(
      Routing.receiptDetails,
      extra: ReceiptModel.fromJson(_list('receipts').first).toEntity(),
    ),
  );
  screen(
    'forum_thread',
    tab: MainTabs.community,
    navigate: (r) => r.pushNamed(Routing.forumThread, extra: _posts().first),
  );
  screen('inbox', navigate: (r) => r.pushNamed(Routing.notifications));
  screen('settings', navigate: (r) => r.pushNamed(Routing.settings));
  screen('account_menu', navigate: (r) => r.pushNamed(Routing.accountMenu));
  screen('profile', navigate: (r) => r.pushNamed(Routing.profileEdit));
  screen('shefi_chat', navigate: (r) => r.pushNamed(Routing.assistant));
  screen(
    'cook_mode',
    navigate: (r) => r.pushNamed(Routing.cookMode, extra: _recipe(1)),
  );
  screen(
    'sharing_management',
    navigate: (r) => r.pushNamed(Routing.sharing),
  );
  screen('household', navigate: (r) => r.pushNamed(Routing.household));
  screen('support', navigate: (r) => r.pushNamed(Routing.support));
  screen(
    'support_chat',
    navigate: (r) => r.pushNamed(
      Routing.supportChat,
      extra: _list('feedback').first['id'] as String,
    ),
  );
  // The paywall's offers come from the store SDK at runtime: the view with
  // sample offers, as the store-listing render does.
  screen(
    'paywall',
    page: () => PaywallView(
      offers: const [
        PaywallOffer(
          id: 'monthly',
          priceString: '₪24.90',
          period: PaywallPeriod.monthly,
        ),
        PaywallOffer(
          id: 'yearly',
          priceString: '₪199.00',
          period: PaywallPeriod.annual,
        ),
      ],
      selectedId: 'yearly',
      aiPerDay: 10,
      isPremium: false,
      loading: false,
      busy: false,
      onSelect: (_) {},
      onPurchase: () {},
      onRestore: () {},
      onManage: () {},
      onRedeem: () {},
      onBack: () {},
    ),
  );
}
