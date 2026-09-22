import 'dart:async';

import 'package:easy_plate/core/services/admin_inbox_service.dart';
import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/features/admin_billing/domain/entities/billing_entities.dart';
import 'package:easy_plate/features/admin_billing/domain/repositories/admin_billing_repository.dart';
import 'package:easy_plate/features/admin_dashboard/domain/entities/dashboard_entities.dart';
import 'package:easy_plate/features/admin_dashboard/domain/repositories/admin_dashboard_repository.dart';
import 'package:easy_plate/features/admin_dashboard/presentation/widgets/dashboard_format.dart';
import 'package:easy_plate/features/admin_dashboard/presentation/widgets/dashboard_tab.dart';
import 'package:easy_plate/features/admin_dashboard/presentation/widgets/subscriptions_tab.dart';
import 'package:easy_plate/features/admin_dashboard/presentation/widgets/tickets_tab.dart';
import 'package:easy_plate/features/feedback/domain/entities/feedback_entity.dart';
import 'package:easy_plate/features/feedback/domain/repositories/feedback_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

const _flash = 'gemini-3_8-flash';

DailyAiUsage _day(String day, int calls) => DailyAiUsage(
  day: day,
  date: DateTime.parse('${day}T00:00:00Z'),
  total: TokenTally(
    calls: calls,
    input: calls * 1000,
    output: calls * 100,
    total: calls * 1100,
  ),
  byModel: {
    _flash: TokenTally(
      calls: calls,
      input: calls * 1000,
      output: calls * 100,
      total: calls * 1100,
    ),
  },
  byKind: {'url': TokenTally(calls: calls)},
  byUser: {
    'ann': {
      _flash: TokenTally(
        calls: calls,
        input: calls * 1000,
        output: calls * 100,
        total: calls * 1100,
      ),
    },
  },
);

DashboardOverview _overview() {
  final days = [for (var i = 1; i <= 7; i++) _day('2026-09-1$i', i)];
  return DashboardOverview(
    period: DashboardPeriod.month,
    loadedAt: DateTime(2026, 9, 17, 12),
    usersTotal: 12,
    newUsers: 3,
    premiumCount: 2,
    disabledCount: 1,
    withPushToken: 9,
    usersByPlatform: const {'ios': 7, 'android': 4, '': 1},
    usersByVersion: const {'0.1.05': 10, '0.1.04': 2},
    signupsByDay: [for (final d in days) MapEntry(d.date, 1)],
    paymentsByCurrency: const {'ILS': 40.0},
    paymentsCount: 2,
    sandboxPayments: 1,
    days: days,
    aiTotal: const TokenTally(
      calls: 28,
      cacheHits: 3,
      input: 28000,
      output: 2800,
      total: 30800,
    ),
    aiByModel: const {
      _flash: TokenTally(calls: 28, input: 28000, output: 2800, total: 30800),
    },
    aiByKind: const {
      'url': TokenTally(calls: 20),
      'text': TokenTally(calls: 8),
    },
    aiUsers: const [
      UserAiUsage(
        uid: 'ann',
        name: 'Ann',
        email: 'ann@example.com',
        premium: true,
        platform: 'ios',
        total: TokenTally(calls: 28, input: 28000, output: 2800, total: 30800),
        byModel: {
          _flash: TokenTally(
            calls: 28,
            input: 28000,
            output: 2800,
            total: 30800,
          ),
        },
      ),
    ],
    sharedRecipes: 5,
    forumPosts: 4,
    feedbackTotal: 2,
    cacheEntries: 6,
    cacheHits: 3,
    pricing: AiPricing.defaults,
  );
}

class _FakeDashboard implements AdminDashboardRepository {
  DashboardPeriod? loadedPeriod;

  @override
  Future<DashboardOverview> load(DashboardPeriod period) async {
    loadedPeriod = period;
    return _overview();
  }

  @override
  Future<AiPricing> loadPricing() async => AiPricing.defaults;

  @override
  Future<void> savePricing(AiPricing pricing) async {}

  @override
  Future<PricingSyncResult> syncPricingFromGoogle() async =>
      const PricingSyncResult(matched: 0, models: [], service: '');

  @override
  Future<UserAiUsage?> userUsage(String uid) async => null;

  @override
  Future<List<AiCallEntity>> recentCalls(String uid, {int limit = 40}) async =>
      const [];
}

class _FakeBilling implements AdminBillingRepository {
  final actions = <String>[];

  @override
  Future<AdminBillingSnapshot> load() async => AdminBillingSnapshot(
    accounts: [
      BillingAccountEntity(
        uid: 'ann',
        name: 'Ann',
        email: 'ann@example.com',
        phone: null,
        premium: true,
        premiumUntil: null,
        source: 'revenuecat',
        adminLock: false,
        lastEventType: 'RENEWAL',
        lastEventAt: DateTime(2026, 9, 1),
        productId: 'easy_plate_ai_pro:pro',
        store: 'PLAY_STORE',
        events: const [],
        platform: 'android',
        appVersion: '0.1.05',
        lastSeenAt: DateTime(2026, 9, 16),
      ),
      const BillingAccountEntity(
        uid: 'bob',
        name: 'Bob',
        email: null,
        phone: null,
        premium: false,
        premiumUntil: null,
        source: '',
        adminLock: false,
        lastEventType: '',
        lastEventAt: null,
        productId: '',
        store: '',
        events: [],
        disabled: true,
        blockMessage: 'spam',
      ),
    ],
    orphanEvents: const [],
  );

  @override
  Future<void> setPremium(
    String uid,
    bool premium, {
    DateTime? from,
    DateTime? until,
  }) async => actions.add('premium:$uid:$premium');
  @override
  Future<void> releaseLock(String uid) async => actions.add('release:$uid');
  @override
  Future<void> disableAccount(String uid, String message) async =>
      actions.add('disable:$uid');
  @override
  Future<void> enableAccount(String uid) async => actions.add('enable:$uid');
  @override
  Future<void> deleteAccount(String uid) async => actions.add('delete:$uid');
  @override
  Future<void> notifyAccount(
    String uid, {
    required String title,
    required String body,
  }) async => actions.add('notify:$uid');
  @override
  Future<BroadcastResult> notifyAll({
    required String title,
    required String body,
  }) async => const BroadcastResult(items: 2, sent: 1, failed: 0);
}

class _FakeFeedback implements FeedbackRepository {
  final controller = StreamController<List<FeedbackEntity>>.broadcast();
  final read = <String, bool>{};
  List<String>? markedAll;

  @override
  Stream<List<FeedbackEntity>> watchAll({int limit = 500}) => controller.stream;
  @override
  Future<List<FeedbackEntity>> getAll({int limit = 200}) async => const [];
  @override
  Future<void> send(FeedbackEntity feedback) async {}
  @override
  Future<void> setRead(String feedbackId, bool value) async =>
      read[feedbackId] = value;
  @override
  Future<void> markAllRead(Iterable<String> feedbackIds) async =>
      markedAll = feedbackIds.toList();
  @override
  Future<void> delete(String feedbackId) async {}
  @override
  Future<void> reply({
    required FeedbackEntity feedback,
    required String text,
    required String fromUid,
  }) async {}
}

FeedbackEntity _ticket(String id, {bool read = false}) => FeedbackEntity(
  id: id,
  type: FeedbackType.bug,
  message: 'message $id',
  authorUid: 'u-$id',
  authorName: 'Dana',
  createdAt: DateTime(2026, 9, 1),
  read: read,
);

Widget _app(
  Widget child, {
  required _FakeDashboard dashboard,
  required _FakeBilling billing,
  required _FakeFeedback feedback,
}) => MultiRepositoryProvider(
  providers: [
    RepositoryProvider<AdminDashboardRepository>.value(value: dashboard),
    RepositoryProvider<AdminBillingRepository>.value(value: billing),
    RepositoryProvider<FeedbackRepository>.value(value: feedback),
  ],
  child: TranslationProvider(
    child: MaterialApp(
      locale: const Locale('he'),
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(body: child),
    ),
  ),
);

void main() {
  late _FakeDashboard dashboard;
  late _FakeBilling billing;
  late _FakeFeedback feedback;

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.he);
    dashboard = _FakeDashboard();
    billing = _FakeBilling();
    feedback = _FakeFeedback();
    AdminInboxService().unbind();
  });

  tearDown(() => AdminInboxService().unbind());

  testWidgets('the dashboard tab renders every section and prices the range', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 14000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        DashboardTab(onOpenTickets: () {}),
        dashboard: dashboard,
        billing: billing,
        feedback: feedback,
      ),
    );
    await tester.pumpAndSettle();

    expect(dashboard.loadedPeriod, DashboardPeriod.month);
    final s = t.adminDashboard;
    expect(find.text(s.aiCost), findsOneWidget);
    expect(find.text(s.chartCost), findsOneWidget);
    expect(find.text(s.chartPlatform), findsOneWidget);
    expect(find.text(s.chartPlan), findsOneWidget);
    expect(find.text(s.usersCost), findsOneWidget);
    expect(find.text('Ann'), findsOneWidget);
    // 28k input at $0.75/M + 2.8k output at $3.75/M = $0.0315, shown in
    // shekels at the table's rate, with the dollars beside it.
    final cost = AiPricing.defaults.costOf(_flash, _overview().aiTotal);
    expect(
      find.text(DashboardFormat.ils(cost * AiPricing.defaults.usdToIls)),
      findsWidgets,
    );
    expect(find.textContaining(DashboardFormat.usd(cost)), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text(s.rangeToday));
    await tester.pumpAndSettle();
    expect(dashboard.loadedPeriod, DashboardPeriod.today);
  });

  testWidgets('the subscriptions tab lists accounts with their block state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        const SubscriptionsTab(),
        dashboard: dashboard,
        billing: billing,
        feedback: feedback,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ann'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(
      find.text(t.adminDashboard.disabledSince(message: 'spam')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    // The blocked filter keeps only Bob.
    await tester.tap(find.text(t.adminDashboard.blocked).first);
    await tester.pumpAndSettle();
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Ann'), findsNothing);
  });

  testWidgets('the tickets tab counts unread, toggles read and reads all', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        const TicketsTab(),
        dashboard: dashboard,
        billing: billing,
        feedback: feedback,
      ),
    );
    await tester.pump();
    feedback.controller.add([
      _ticket('a'),
      _ticket('b', read: true),
      _ticket('c'),
    ]);
    await tester.pumpAndSettle();

    expect(AdminInboxService().unreadCount.value, 2);
    // The unread filter is the default: b is hidden.
    expect(find.text('message a'), findsOneWidget);
    expect(find.text('message b'), findsNothing);
    expect(find.text('2'), findsOneWidget); // the badge on the unread segment

    await tester.tap(find.byTooltip(t.adminDashboard.markRead).first);
    await tester.pumpAndSettle();
    expect(feedback.read['a'], isTrue);

    await tester.tap(find.text(t.adminDashboard.markAllRead));
    await tester.pumpAndSettle();
    expect(feedback.markedAll, ['a', 'c']);
    expect(tester.takeException(), isNull);
  });
}
