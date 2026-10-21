import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/user_detail_entities.dart';

/// Gathers one account's whole picture for the administrator: profile,
/// plan, device, household, the data it keeps (recipes, books, plans,
/// lists, receipts…), what it published (threads, replies, shared recipes),
/// tickets, inbox, purchases, sharing and AI calls, and folds all of it into
/// one timeline.
///
/// Every read is one the rules open to the administrator (see
/// firestore.rules: `users/{uid}/**`, the collection-group replies rule,
/// `notifications`, `feedback`, `ai_calls`, `purchase_events`, …). Each
/// section is read on its own and a failure only empties that section, so a
/// missing index never blanks the whole screen; the failed names are
/// reported.
class AdminUserDetailDataSource {
  final FirebaseFirestore _db;

  AdminUserDetailDataSource({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  /// The account's own collections, as the cloud mirror names them.
  static const personal = [
    'recipes',
    'books',
    'meal_plans',
    'grocery_lists',
    'receipts',
    'price_records',
  ];

  /// The collections a household keeps for all its members.
  static const shared = {
    'recipes',
    'books',
    'meal_plans',
    'grocery_lists',
    'receipts',
    'price_records',
  };

  static const _limit = 300;

  Future<AdminUserDetail> load(String uid) async {
    final failures = <String>[];

    Future<T?> guard<T>(String name, Future<T> Function() read) async {
      try {
        return await read();
      } catch (e) {
        debugPrint('Admin user detail: $name failed: $e');
        failures.add(name);
        return null;
      }
    }

    Future<Map<String, dynamic>?> doc(String name, String path) =>
        guard<Map<String, dynamic>?>(
          name,
          () async => (await _db.doc(path).get()).data(),
        );

    Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> query(
      String name,
      Query<Map<String, dynamic>> q,
    ) async =>
        (await guard(name, () async => (await q.limit(_limit).get()).docs)) ??
        const [];

    final household = await guard('household', () async {
      final snap = await _db
          .collection('households')
          .where('memberUids', arrayContains: uid)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return {'id': snap.docs.first.id, ...snap.docs.first.data()};
    });
    final householdId = household?['id'] as String?;

    final results = await Future.wait<Object?>([
      doc('profile', 'users/$uid'), // 0
      doc('entitlement', 'entitlements/$uid'), // 1
      doc('status', 'account_status/$uid'), // 2
      doc('session', 'sessions/$uid'), // 3
      doc('aiUsage', 'ai_usage/$uid'), // 4
      doc('usage', 'users/$uid/usage/current'), // 5
      doc('preferences', 'users/$uid/preferences/current'), // 6
      query(
        'forum_posts',
        _db.collection('forum_posts').where('authorUid', isEqualTo: uid),
      ), // 7
      query(
        'replies',
        _db.collectionGroup('replies').where('authorUid', isEqualTo: uid),
      ), // 8
      query(
        'shared_recipes',
        _db.collection('shared_recipes').where('authorUid', isEqualTo: uid),
      ), // 9
      query(
        'feedback',
        _db.collection('feedback').where('authorUid', isEqualTo: uid),
      ), // 10
      query(
        'notifications',
        _db
            .collection('notifications')
            .doc(uid)
            .collection('items')
            .orderBy('createdAt', descending: true),
      ), // 11
      query(
        'purchase_events',
        _db.collection('purchase_events').where('uid', isEqualTo: uid),
      ), // 12
      query(
        'share_codes',
        _db.collection('share_codes').where('ownerUid', isEqualTo: uid),
      ), // 13
      query(
        'invites_sent',
        _db.collection('share_invites').where('ownerUid', isEqualTo: uid),
      ), // 14
      query(
        'invites_received',
        _db.collection('share_invites').where('targetUid', isEqualTo: uid),
      ), // 15
      query(
        'collab_recipes',
        _db
            .collection('collab_recipes')
            .where('memberUids', arrayContains: uid),
      ), // 16
      query(
        'collab_containers',
        _db
            .collection('collab_containers')
            .where('memberUids', arrayContains: uid),
      ), // 17
      query(
        'collab_recipes_owned',
        _db.collection('collab_recipes').where('ownerUid', isEqualTo: uid),
      ), // 18
      query(
        'collab_containers_owned',
        _db.collection('collab_containers').where('ownerUid', isEqualTo: uid),
      ), // 19
      query(
        'ai_calls',
        _db
            .collection('ai_calls')
            .where('uid', isEqualTo: uid)
            .orderBy('at', descending: true),
      ), // 20
    ]);

    // The account's own data: shared collections from the household when it
    // is in one, the rest from its own root.
    final content = <String, List<ContentItem>>{};
    await Future.wait([
      for (final name in personal)
        () async {
          final root = householdId != null && shared.contains(name)
              ? _db.collection('households').doc(householdId)
              : _db.collection('users').doc(uid);
          final docs = await query(name, root.collection(name));
          content[name] = [for (final d in docs) _item(d.id, d.data())]
            ..sort(_newestFirst);
        }(),
    ]);

    List<ContentItem> items(Object? docs) => [
      for (final d
          in (docs as List<QueryDocumentSnapshot<Map<String, dynamic>>>))
        _item(d.id, {...d.data(), '_path': d.reference.path}),
    ]..sort(_newestFirst);

    final profile = (results[0] as Map<String, dynamic>?) ?? const {};
    final detail = AdminUserDetail(
      uid: uid,
      profile: profile,
      entitlement: results[1] as Map<String, dynamic>?,
      status: results[2] as Map<String, dynamic>?,
      session: results[3] as Map<String, dynamic>?,
      household: household,
      aiUsage: results[4] as Map<String, dynamic>?,
      usageToday: results[5] as Map<String, dynamic>?,
      preferences: results[6] as Map<String, dynamic>?,
      content: content,
      forumPosts: items(results[7]),
      forumReplies: items(results[8]),
      sharedRecipes: items(results[9]),
      feedback: items(results[10]),
      notifications: items(results[11]),
      purchases: items(results[12]),
      shareCodes: items(results[13]),
      invitesSent: items(results[14]),
      invitesReceived: items(results[15]),
      sharedWithMe: [...items(results[16]), ...items(results[17])]
        ..sort(_newestFirst),
      sharedByMe: [...items(results[18]), ...items(results[19])]
        ..sort(_newestFirst),
      aiCalls: items(results[20]),
      failures: failures,
    );
    return AdminUserDetail(
      uid: detail.uid,
      profile: detail.profile,
      entitlement: detail.entitlement,
      status: detail.status,
      session: detail.session,
      household: detail.household,
      aiUsage: detail.aiUsage,
      usageToday: detail.usageToday,
      preferences: detail.preferences,
      content: detail.content,
      forumPosts: detail.forumPosts,
      forumReplies: detail.forumReplies,
      sharedRecipes: detail.sharedRecipes,
      feedback: detail.feedback,
      notifications: detail.notifications,
      purchases: detail.purchases,
      shareCodes: detail.shareCodes,
      invitesSent: detail.invitesSent,
      invitesReceived: detail.invitesReceived,
      sharedByMe: detail.sharedByMe,
      sharedWithMe: detail.sharedWithMe,
      names: await _namesOf(uid, detail, failures),
      aiCalls: detail.aiCalls,
      timeline: timelineOf(detail),
      failures: detail.failures,
    );
  }

  /// Names for every other account in the shares and invites, read from
  /// their profiles in batches of 30 (Firestore's `whereIn` limit).
  Future<Map<String, String>> _namesOf(
    String uid,
    AdminUserDetail d,
    List<String> failures,
  ) async {
    final uids = <String>{
      for (final i in [...d.sharedByMe, ...d.sharedWithMe]) ...[
        if (i.data['ownerUid'] is String) i.data['ownerUid'] as String,
        ...((i.data['members'] as Map?)?.keys.whereType<String>() ?? []),
        ...((i.data['memberUids'] as List?)?.whereType<String>() ?? []),
      ],
      for (final i in [...d.invitesSent, ...d.invitesReceived]) ...[
        if (i.data['ownerUid'] is String) i.data['ownerUid'] as String,
        if (i.data['targetUid'] is String) i.data['targetUid'] as String,
      ],
    }..remove(uid);
    final names = <String, String>{};
    final list = uids.toList();
    try {
      for (var i = 0; i < list.length; i += 30) {
        final chunk = list.sublist(
          i,
          i + 30 > list.length ? list.length : i + 30,
        );
        final snap = await _db
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final doc in snap.docs) {
          final raw = doc.data()['fullName'];
          final name = raw is String ? raw.trim() : null;
          if (name != null && name.isNotEmpty) names[doc.id] = name;
        }
      }
    } catch (e) {
      debugPrint('Admin user detail: names failed: $e');
      failures.add('names');
    }
    return names;
  }

  static int _newestFirst(ContentItem a, ContentItem b) =>
      (b.at ?? DateTime(0)).compareTo(a.at ?? DateTime(0));

  static ContentItem _item(String id, Map<String, dynamic> data) =>
      ContentItem(id: id, title: titleOf(data), at: timeOf(data), data: data);

  /// The best human title a document carries.
  @visibleForTesting
  static String titleOf(Map<String, dynamic> d) {
    for (final key in [
      'title',
      'name',
      'recipeTitle',
      'store',
      'body',
      'message',
      'text',
      'productId',
      'type',
      'kind',
      'model',
    ]) {
      final value = d[key];
      if (value is String && value.trim().isNotEmpty) {
        final line = value.trim().split('\n').first;
        return line.length > 120 ? '${line.substring(0, 120)}…' : line;
      }
    }
    return '';
  }

  /// When a document happened: the first date field it has, in any of the
  /// forms the app and the functions write (Timestamp, ISO string, millis).
  @visibleForTesting
  static DateTime? timeOf(Map<String, dynamic> d) {
    for (final key in [
      'createdAt',
      'at',
      'eventAt',
      'purchasedAt',
      'startedAt',
      'updatedAt',
    ]) {
      final t = asTime(d[key]);
      if (t != null) return t;
    }
    return null;
  }

  static DateTime? asTime(Object? v) => switch (v) {
    Timestamp() => v.toDate(),
    DateTime() => v,
    int() => DateTime.fromMillisecondsSinceEpoch(v),
    String() => DateTime.tryParse(v)?.toLocal(),
    _ => null,
  };

  /// All sections as one timeline, newest first. Pure, for tests.
  @visibleForTesting
  static List<ActivityEvent> timelineOf(AdminUserDetail d) {
    final events = <ActivityEvent>[];
    void add(
      ActivityKind kind,
      List<ContentItem> list, {
      String? Function(ContentItem item)? detail,
    }) {
      for (final item in list) {
        final at = item.at;
        if (at == null) continue;
        events.add(
          ActivityEvent(
            kind: kind,
            at: at,
            title: item.title,
            detail: detail?.call(item),
            data: item.data,
          ),
        );
      }
    }

    final joined = asTime(d.profile['createdAt']);
    if (joined != null) {
      events.add(
        ActivityEvent(
          kind: ActivityKind.joined,
          at: joined,
          title: d.profile['fullName'] is String
              ? d.profile['fullName'] as String
              : d.uid,
          data: d.profile,
        ),
      );
    }
    final seen = asTime(d.profile['lastSeenAt']);
    if (seen != null) {
      events.add(
        ActivityEvent(
          kind: ActivityKind.seen,
          at: seen,
          title: [
            d.profile['platform'],
            d.profile['appVersion'],
          ].whereType<String>().join(' · '),
          data: d.profile,
        ),
      );
    }
    const kinds = {
      'recipes': ActivityKind.recipe,
      'books': ActivityKind.book,
      'meal_plans': ActivityKind.mealPlan,
      'grocery_lists': ActivityKind.groceryList,
      'receipts': ActivityKind.receipt,
    };
    for (final entry in kinds.entries) {
      add(entry.value, d.content[entry.key] ?? const []);
    }
    add(ActivityKind.forumPost, d.forumPosts);
    add(ActivityKind.forumReply, d.forumReplies);
    add(ActivityKind.sharedRecipe, d.sharedRecipes);
    add(
      ActivityKind.feedback,
      d.feedback,
      detail: (i) => i.data['type'] as String?,
    );
    add(
      ActivityKind.aiCall,
      d.aiCalls,
      // aiUsage.js writes the HTTP status as a number (200, 429).
      detail: (i) => [
        i.data['kind'],
        i.data['status'],
      ].where((v) => (v is String && v.isNotEmpty) || v is num).join(' · '),
    );
    add(
      ActivityKind.purchase,
      d.purchases,
      detail: (i) => i.data['productId'] as String?,
    );
    add(ActivityKind.shareCode, d.shareCodes);
    add(ActivityKind.sharedByMe, d.sharedByMe);
    add(ActivityKind.inviteSent, d.invitesSent);
    add(ActivityKind.inviteReceived, d.invitesReceived);
    add(ActivityKind.notification, d.notifications);
    events.sort((a, b) => b.at.compareTo(a.at));
    return events;
  }
}
