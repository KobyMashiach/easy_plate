import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_plate/core/utils/i18n/strings.g.dart';
import 'package:easy_plate/features/admin_billing/data/datasources/admin_user_detail_datasource.dart';
import 'package:easy_plate/features/admin_billing/domain/entities/user_detail_entities.dart';
import 'package:easy_plate/features/admin_dashboard/presentation/pages/admin_user_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async => initializeDateFormatting('he'));

  group('reading documents', () {
    test('the best title and the first date, whatever their form', () {
      expect(AdminUserDetailDataSource.titleOf({'title': 'שקשוקה'}), 'שקשוקה');
      expect(
        AdminUserDetailDataSource.titleOf({'name': 'קניות שבוע'}),
        'קניות שבוע',
      );
      expect(
        AdminUserDetailDataSource.titleOf({'body': 'line one\nline two'}),
        'line one',
      );
      expect(AdminUserDetailDataSource.titleOf({}), '');
      final at = DateTime(2026, 10, 1, 12);
      expect(
        AdminUserDetailDataSource.timeOf({'createdAt': Timestamp.fromDate(at)}),
        at,
      );
      expect(
        AdminUserDetailDataSource.timeOf({'createdAt': at.toIso8601String()}),
        at,
      );
      expect(
        AdminUserDetailDataSource.timeOf({'at': at.millisecondsSinceEpoch}),
        at,
      );
      expect(
        AdminUserDetailDataSource.timeOf({'eventAt': Timestamp.fromDate(at)}),
        at,
      );
      expect(AdminUserDetailDataSource.timeOf({}), isNull);
    });

    test('every section folds into one timeline, newest first', () {
      ContentItem item(String title, int day) => ContentItem(
        id: title,
        title: title,
        at: DateTime(2026, 10, day),
      );
      final detail = AdminUserDetail(
        uid: 'u1',
        profile: {
          'fullName': 'קובי',
          'createdAt': Timestamp.fromDate(DateTime(2026, 9, 1)),
        },
        content: {
          'recipes': [item('recipe', 3)],
          'grocery_lists': [item('list', 5)],
        },
        forumPosts: [item('post', 4)],
        forumReplies: [item('reply', 6)],
        aiCalls: [
          const ContentItem(id: 'no date', title: 'skipped'),
          item('call', 2),
        ],
      );
      final events = AdminUserDetailDataSource.timelineOf(detail);
      expect(events.map((e) => e.title), [
        'reply',
        'list',
        'post',
        'recipe',
        'call',
        'קובי',
      ]);
      expect(events.first.kind, ActivityKind.forumReply);
      expect(events.last.kind, ActivityKind.joined);
    });

    test('an AI call keeps its numeric status in the timeline', () {
      final detail = AdminUserDetail(
        uid: 'u1',
        profile: const {},
        aiCalls: [
          ContentItem(
            id: 'c1',
            title: 'call',
            at: DateTime(2026, 10, 1),
            data: const {'kind': 'url', 'status': 429},
          ),
        ],
      );
      final call = AdminUserDetailDataSource.timelineOf(
        detail,
      ).firstWhere((e) => e.kind == ActivityKind.aiCall);
      expect(call.detail, 'url · 429');
    });
  });

  testWidgets(
    'the user page shows the overview, the timeline and the publications',
    (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.he);
      final at = DateTime(2026, 10, 10, 9);
      final detail = AdminUserDetail(
        uid: 'u1',
        profile: const {
          'fullName': 'קובי משיח',
          'email': 'k@example.com',
          'phoneNumber': '+972500000000',
        },
        content: {
          'recipes': [ContentItem(id: 'r1', title: 'שקשוקה', at: at)],
        },
        forumPosts: [
          ContentItem(
            id: 'p1',
            title: 'איך מכינים פיתות?',
            at: at,
            data: const {'likeCount': 3, 'replyCount': 2},
          ),
        ],
      );
      final full = AdminUserDetail(
        uid: detail.uid,
        profile: detail.profile,
        content: detail.content,
        forumPosts: detail.forumPosts,
        timeline: AdminUserDetailDataSource.timelineOf(detail),
      );
      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            home: AdminUserPage(
              uid: 'u1',
              name: 'קובי משיח',
              loader: (_) async => full,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('k@example.com'), findsOneWidget);
      expect(find.text('+972500000000'), findsOneWidget);

      await tester.tap(find.byTooltip(t.adminUser.tabActivity));
      await tester.pumpAndSettle();
      expect(find.text('שקשוקה'), findsOneWidget);
      expect(find.text('איך מכינים פיתות?'), findsOneWidget);

      await tester.tap(find.byTooltip(t.adminUser.tabPublished));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.adminUser.sections.forumPosts));
      await tester.pumpAndSettle();
      expect(find.text('איך מכינים פיתות?'), findsOneWidget);
    },
  );

  testWidgets(
    'a grant dated ahead reads as free until it starts, and the page reads '
    'the account again after an action',
    (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.he);
      final start = DateTime.now().add(const Duration(days: 3));
      var loads = 0;
      var actions = 0;
      await tester.pumpWidget(
        TranslationProvider(
          child: MaterialApp(
            home: AdminUserPage(
              uid: 'u1',
              name: 'Ann',
              onActions: () async => actions++,
              loader: (_) async {
                loads++;
                return AdminUserDetail(
                  uid: 'u1',
                  profile: const {'fullName': 'Ann'},
                  entitlement: {'premium': true, 'premiumFrom': start},
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(t.adminBilling.premium), findsNothing);
      expect(
        find.textContaining(t.adminBilling.free, findRichText: true),
        findsWidgets,
      );
      expect(loads, 1);

      await tester.tap(find.byIcon(Icons.more_horiz_rounded));
      await tester.pumpAndSettle();
      expect(actions, 1);
      expect(loads, 2);
    },
  );
}
