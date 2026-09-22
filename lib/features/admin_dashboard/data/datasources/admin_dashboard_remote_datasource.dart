import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/dashboard_entities.dart';
import '../../domain/usecases/aggregate_usage_usecase.dart';

abstract class AdminDashboardRemoteDataSource {
  Future<DashboardOverview> load(DashboardPeriod period);
  Future<AiPricing> loadPricing();
  Future<void> savePricing(AiPricing pricing);
  Future<UserAiUsage?> userUsage(String uid);
  Future<List<AiCallEntity>> recentCalls(String uid, {int limit = 40});
}

/// Reads what the functions write (`ai_daily`, `ai_usage`, `ai_calls`) and
/// the collections the rules open to the administrator, and folds them into
/// one overview. Every read here is refused to any other account.
class AdminDashboardFirestoreDataSource
    implements AdminDashboardRemoteDataSource {
  static const usersCollection = 'users';
  static const entitlementsCollection = 'entitlements';
  static const statusCollection = 'account_status';
  static const eventsCollection = 'purchase_events';
  static const dailyCollection = 'ai_daily';
  static const usageCollection = 'ai_usage';
  static const callsCollection = 'ai_calls';
  static const cacheCollection = 'ai_url_cache';
  static const configCollection = 'admin_config';
  static const pricingDoc = 'pricing';

  final FirebaseFirestore _firestore;
  final AggregateUsageUseCase _aggregate;

  AdminDashboardFirestoreDataSource({
    FirebaseFirestore? firestore,
    AggregateUsageUseCase aggregate = const AggregateUsageUseCase(),
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _aggregate = aggregate;

  @override
  Future<DashboardOverview> load(DashboardPeriod period) async {
    final now = DateTime.now();
    final range = period.range;
    final sinceDay = AggregateUsageUseCase.sinceDay(period, now);
    final untilDay = AggregateUsageUseCase.untilDay(period, now);
    final chartSince = AggregateUsageUseCase.chartSinceDay(period, now);
    final since = sinceDay == null
        ? null
        : DateTime.parse('${sinceDay}T00:00:00Z');
    // Exclusive: the first instant after the period's last day.
    final untilExclusive = untilDay == null
        ? null
        : DateTime.parse(
            '${untilDay}T00:00:00Z',
          ).add(const Duration(days: 1));
    bool inPeriod(DateTime at) =>
        (since == null || !at.isBefore(since)) &&
        (untilExclusive == null || at.isBefore(untilExclusive));
    bool dayInPeriod(String day) =>
        (sinceDay == null || day.compareTo(sinceDay) >= 0) &&
        (untilDay == null || day.compareTo(untilDay) <= 0);

    Query<Map<String, dynamic>> events = _firestore.collection(
      eventsCollection,
    );
    events = since == null
        ? events.orderBy('eventAt', descending: true).limit(2000)
        : events.where(
            'eventAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(since),
          );
    if (untilExclusive != null) {
      events = events.where(
        'eventAt',
        isLessThan: Timestamp.fromDate(untilExclusive),
      );
    }

    // The chart window for a bounded range; the last 400 days for all-time,
    // where the range's own totals come from ai_usage. Both are a range on
    // the document id, which needs no index — ordering by id descending did.
    Query<Map<String, dynamic>> daily = _firestore
        .collection(dailyCollection)
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: chartSince);
    if (untilDay != null) {
      daily = daily.where(
        FieldPath.documentId,
        isLessThanOrEqualTo: untilDay,
      );
    }

    final results = await Future.wait<dynamic>([
      _firestore.collection(usersCollection).limit(5000).get(),
      _firestore.collection(entitlementsCollection).limit(5000).get(),
      _firestore.collection(statusCollection).limit(5000).get(),
      events.get(),
      daily.get(),
      range == DashboardRange.all
          ? _firestore.collection(usageCollection).limit(5000).get()
          : Future.value(null),
      _firestore
          .collection(dailyCollection)
          .orderBy(FieldPath.documentId)
          .limit(1)
          .get(),
      _firestore.collection('shared_recipes').count().get(),
      _firestore.collection('forum_posts').count().get(),
      _firestore.collection('feedback').count().get(),
      _firestore
          .collection(cacheCollection)
          .aggregate(count(), sum('hits'))
          .get(),
      loadPricing(),
    ]);

    final users = (results[0] as QuerySnapshot<Map<String, dynamic>>).docs;
    final entitlements = {
      for (final d in (results[1] as QuerySnapshot<Map<String, dynamic>>).docs)
        d.id: d.data(),
    };
    final statuses = {
      for (final d in (results[2] as QuerySnapshot<Map<String, dynamic>>).docs)
        d.id: d.data(),
    };
    final eventDocs = (results[3] as QuerySnapshot<Map<String, dynamic>>).docs;
    final dayDocs = (results[4] as QuerySnapshot<Map<String, dynamic>>).docs;
    final usageDocs =
        (results[5] as QuerySnapshot<Map<String, dynamic>>?)?.docs;
    final firstDataDay = (results[6] as QuerySnapshot<Map<String, dynamic>>)
        .docs
        .firstOrNull
        ?.id;
    final sharedRecipes = (results[7] as AggregateQuerySnapshot).count ?? 0;
    final forumPosts = (results[8] as AggregateQuerySnapshot).count ?? 0;
    final feedbackTotal = (results[9] as AggregateQuerySnapshot).count ?? 0;
    final cache = results[10] as AggregateQuerySnapshot;
    final pricing = results[11] as AiPricing;

    // --- accounts -------------------------------------------------------
    final profiles = {for (final d in users) d.id: d.data()};
    bool premiumOf(String uid) {
      final e = entitlements[uid];
      if (e == null || e['premium'] != true) return false;
      final from = (e['premiumFrom'] as Timestamp?)?.toDate();
      if (from != null && from.isAfter(now)) return false;
      final until = (e['premiumUntil'] as Timestamp?)?.toDate();
      return until == null || until.isAfter(now);
    }

    var premiumCount = 0;
    var disabledCount = 0;
    var withPush = 0;
    var newUsers = 0;
    final byPlatform = <String, int>{};
    final byVersion = <String, int>{};
    final signups = <String, int>{};
    for (final d in users) {
      final p = d.data();
      if (premiumOf(d.id)) premiumCount++;
      if (statuses[d.id]?['disabled'] == true) disabledCount++;
      if ((p['pushToken'] as String?)?.isNotEmpty == true) withPush++;
      final platform = (p['platform'] as String?)?.trim() ?? '';
      byPlatform[platform] = (byPlatform[platform] ?? 0) + 1;
      final version = (p['appVersion'] as String?)?.trim() ?? '';
      if (version.isNotEmpty) {
        byVersion[version] = (byVersion[version] ?? 0) + 1;
      }
      final created = (p['createdAt'] as Timestamp?)?.toDate();
      if (created != null) {
        final day = AggregateUsageUseCase.dayOf(created);
        if (inPeriod(created)) newUsers++;
        if (day.compareTo(chartSince) >= 0) {
          signups[day] = (signups[day] ?? 0) + 1;
        }
      }
    }
    // Also count the entitlement documents whose profile is gone, so the
    // premium figure matches the subscriptions tab.
    for (final uid in entitlements.keys) {
      if (!profiles.containsKey(uid) && premiumOf(uid)) premiumCount++;
    }

    // --- payments -------------------------------------------------------
    const paymentTypes = {
      'INITIAL_PURCHASE',
      'RENEWAL',
      'NON_RENEWING_PURCHASE',
      'UNCANCELLATION',
      'PRODUCT_CHANGE',
    };
    final paymentsByCurrency = <String, double>{};
    var paymentsCount = 0;
    var sandboxPayments = 0;
    for (final d in eventDocs) {
      final e = d.data();
      if (!paymentTypes.contains(e['type'])) continue;
      final price = (e['price'] as num?)?.toDouble();
      if (price == null || price <= 0) continue;
      if ((e['environment'] as String? ?? '').toUpperCase() == 'SANDBOX') {
        sandboxPayments++;
        continue;
      }
      paymentsCount++;
      final currency = ((e['currency'] as String?) ?? '').toUpperCase();
      paymentsByCurrency[currency] =
          (paymentsByCurrency[currency] ?? 0) + price;
    }

    // --- AI -------------------------------------------------------------
    final allDays = dayDocs.map(_toDay).toList()
      ..sort((a, b) => a.day.compareTo(b.day));
    final rangeDays = allDays.where((d) => dayInPeriod(d.day)).toList();
    final chartDays = _padDays(allDays, chartSince, untilDay, now, range);

    final aiTotal = _aggregate.total(rangeDays);
    final aiByModel = _aggregate.byModel(rangeDays);
    final aiByKind = _aggregate.byKind(rangeDays);

    UserAiUsage userRow(
      String uid,
      Map<String, TokenTally> byModel, {
      Map<String, TokenTally> byKind = const {},
      DateTime? lastCallAt,
    }) {
      final p = profiles[uid];
      final name = (p?['fullName'] as String?)?.trim();
      return UserAiUsage(
        uid: uid,
        name: name?.isNotEmpty == true ? name! : uid,
        email: p?['email'] as String?,
        premium: premiumOf(uid),
        platform: (p?['platform'] as String?) ?? '',
        total: AggregateUsageUseCase.sumOf(byModel),
        byModel: byModel,
        byKind: byKind,
        lastCallAt: lastCallAt,
      );
    }

    final aiUsers = <UserAiUsage>[];
    if (usageDocs != null) {
      for (final d in usageDocs) {
        final data = d.data();
        final byModel = _tallies(data['models']);
        if (byModel.isEmpty) continue;
        aiUsers.add(
          userRow(
            d.id,
            byModel,
            byKind: _tallies(data['kinds']),
            lastCallAt: (data['lastCallAt'] as Timestamp?)?.toDate(),
          ),
        );
      }
    } else {
      _aggregate.byUser(rangeDays).forEach((uid, byModel) {
        aiUsers.add(userRow(uid, byModel));
      });
    }
    aiUsers.sort((a, b) => b.cost(pricing).compareTo(a.cost(pricing)));

    final signupsByDay = [
      for (final day in chartDays) MapEntry(day.date, signups[day.day] ?? 0),
    ];

    return DashboardOverview(
      period: period,
      firstDataDay: firstDataDay,
      loadedAt: now,
      usersTotal: users.length,
      newUsers: newUsers,
      premiumCount: premiumCount,
      disabledCount: disabledCount,
      withPushToken: withPush,
      usersByPlatform: byPlatform,
      usersByVersion: byVersion,
      signupsByDay: signupsByDay,
      paymentsByCurrency: paymentsByCurrency,
      paymentsCount: paymentsCount,
      sandboxPayments: sandboxPayments,
      days: chartDays,
      aiTotal: aiTotal,
      aiByModel: aiByModel,
      aiByKind: aiByKind,
      aiUsers: aiUsers,
      sharedRecipes: sharedRecipes,
      forumPosts: forumPosts,
      feedbackTotal: feedbackTotal,
      cacheEntries: cache.count ?? 0,
      cacheHits: (cache.getSum('hits') ?? 0).toInt(),
      pricing: pricing,
    );
  }

  /// One entry per calendar day of the window, so a quiet day is a gap in
  /// the bars rather than a missing bar. All-time keeps only the days that
  /// exist — a year of empty bars says nothing.
  List<DailyAiUsage> _padDays(
    List<DailyAiUsage> days,
    String since,
    String? until,
    DateTime now,
    DashboardRange range,
  ) {
    if (range == DashboardRange.all) return days;
    final byDay = {for (final d in days) d.day: d};
    final out = <DailyAiUsage>[];
    var cursor = DateTime.parse('${since}T00:00:00Z');
    final end = DateTime.parse(
      '${until ?? AggregateUsageUseCase.dayOf(now)}T00:00:00Z',
    );
    while (!cursor.isAfter(end)) {
      final key = AggregateUsageUseCase.dayOf(cursor);
      out.add(
        byDay[key] ??
            DailyAiUsage(
              day: key,
              date: cursor,
              total: TokenTally.zero,
              byModel: const {},
              byKind: const {},
              byUser: const {},
            ),
      );
      cursor = cursor.add(const Duration(days: 1));
    }
    return out;
  }

  Map<String, TokenTally> _tallies(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final entry in raw.entries)
        if (entry.value is Map)
          entry.key.toString(): TokenTally.fromMap(
            Map<String, dynamic>.from(entry.value as Map),
          ),
    };
  }

  DailyAiUsage _toDay(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final users = <String, Map<String, TokenTally>>{};
    final rawUsers = data['users'];
    if (rawUsers is Map) {
      for (final entry in rawUsers.entries) {
        if (entry.value is Map) {
          final models = _tallies((entry.value as Map)['models']);
          if (models.isNotEmpty) users[entry.key.toString()] = models;
        }
      }
    }
    return DailyAiUsage(
      day: doc.id,
      date: DateTime.tryParse('${doc.id}T00:00:00Z') ?? DateTime(0),
      total: TokenTally.fromMap(data),
      byModel: _tallies(data['models']),
      byKind: _tallies(data['kinds']),
      byUser: users,
    );
  }

  @override
  Future<AiPricing> loadPricing() async {
    try {
      final doc = await _firestore
          .collection(configCollection)
          .doc(pricingDoc)
          .get();
      final data = doc.data();
      if (data == null) return AiPricing.defaults;
      final models = <String, ModelPrice>{};
      final raw = data['models'];
      if (raw is Map) {
        for (final entry in raw.entries) {
          if (entry.value is! Map) continue;
          final m = entry.value as Map;
          models[entry.key.toString()] = ModelPrice(
            inputPerMillion: (m['input'] as num?)?.toDouble() ?? 0,
            outputPerMillion: (m['output'] as num?)?.toDouble() ?? 0,
            cachedPerMillion: (m['cached'] as num?)?.toDouble() ?? 0,
            imageOutputPerMillion: (m['imageOutput'] as num?)?.toDouble(),
          );
        }
      }
      return AiPricing(
        models: models.isEmpty ? AiPricing.defaults.models : models,
        fallback: models['gemini-3_8-flash'] ?? AiPricing.defaults.fallback,
        usdToIls:
            (data['usdToIls'] as num?)?.toDouble() ??
            AiPricing.defaults.usdToIls,
        source:
            PricingSource.values
                .where((v) => v.name == data['source'])
                .firstOrNull ??
            (models.isEmpty ? PricingSource.defaults : PricingSource.manual),
        rateUpdatedAt: (data['rateUpdatedAt'] as Timestamp?)?.toDate(),
        searchPerThousand:
            (data['searchPerThousand'] as num?)?.toDouble() ??
            AiPricing.defaults.searchPerThousand,
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
        catalogNotes: [
          for (final n in (data['catalogNotes'] as List?) ?? const [])
            n.toString(),
        ],
      );
    } catch (_) {
      return AiPricing.defaults;
    }
  }

  @override
  Future<void> savePricing(AiPricing pricing) {
    return _firestore.collection(configCollection).doc(pricingDoc).set({
      'models': {
        for (final entry in pricing.models.entries)
          entry.key: {
            'input': entry.value.inputPerMillion,
            'output': entry.value.outputPerMillion,
            'cached': entry.value.cachedPerMillion,
            'imageOutput': ?entry.value.imageOutputPerMillion,
          },
      },
      // The rate is the functions' to write, weekly; a save leaves it.
      'searchPerThousand': pricing.searchPerThousand,
      'source': PricingSource.manual.name,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<UserAiUsage?> userUsage(String uid) async {
    final doc = await _firestore.collection(usageCollection).doc(uid).get();
    final data = doc.data();
    if (data == null) return null;
    final byModel = _tallies(data['models']);
    return UserAiUsage(
      uid: uid,
      name: uid,
      email: null,
      premium: false,
      platform: '',
      total: AggregateUsageUseCase.sumOf(byModel),
      byModel: byModel,
      byKind: _tallies(data['kinds']),
      lastCallAt: (data['lastCallAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  Future<List<AiCallEntity>> recentCalls(String uid, {int limit = 40}) async {
    final snapshot = await _firestore
        .collection(callsCollection)
        .where('uid', isEqualTo: uid)
        .orderBy('at', descending: true)
        .limit(limit)
        .get();
    return [
      for (final doc in snapshot.docs)
        AiCallEntity(
          id: doc.id,
          uid: uid,
          fn: (doc.data()['fn'] as String?) ?? '',
          model: (doc.data()['model'] as String?) ?? '',
          kind: (doc.data()['kind'] as String?) ?? '',
          status: (doc.data()['status'] as num?)?.toInt() ?? 0,
          ms: (doc.data()['ms'] as num?)?.toInt() ?? 0,
          cacheHit: doc.data()['cacheHit'] == true,
          tokens: TokenTally(
            calls: 1,
            input: (doc.data()['inputTokens'] as num?)?.toInt() ?? 0,
            output: (doc.data()['outputTokens'] as num?)?.toInt() ?? 0,
            thoughts: (doc.data()['thoughtTokens'] as num?)?.toInt() ?? 0,
            cached: (doc.data()['cachedTokens'] as num?)?.toInt() ?? 0,
            total: (doc.data()['totalTokens'] as num?)?.toInt() ?? 0,
          ),
          at: (doc.data()['at'] as Timestamp?)?.toDate() ?? DateTime(0),
        ),
    ];
  }
}
