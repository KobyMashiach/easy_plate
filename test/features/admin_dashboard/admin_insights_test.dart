import 'dart:typed_data';

import 'package:easy_plate/features/admin_billing/data/datasources/admin_billing_remote_datasource.dart';
import 'package:easy_plate/features/admin_billing/domain/entities/billing_entities.dart';
import 'package:easy_plate/features/admin_dashboard/domain/entities/dashboard_entities.dart';
import 'package:easy_plate/features/admin_dashboard/presentation/widgets/platform_plan_table.dart';
import 'package:easy_plate/features/recipe_ingestion/data/datasources/recipe_ai_datasource.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/entities/ingestion_file.dart';
import 'package:flutter_test/flutter_test.dart';

PurchaseEventEntity ev(
  String type,
  String day, {
  bool grants = false,
  double? price,
  String periodType = '',
  String? until,
  String env = 'PRODUCTION',
}) => PurchaseEventEntity(
  id: '$type$day',
  uid: 'u1',
  appUserId: 'u1',
  type: type,
  productId: 'p',
  store: 'APP_STORE',
  entitlementIds: const [],
  grantsPremium: grants,
  environment: env,
  eventAt: DateTime.parse(day),
  expiresAt: until == null ? null : DateTime.parse(until),
  price: price,
  currency: 'ILS',
  periodType: periodType,
);

void main() {
  group('SubscriptionHistory', () {
    test('tells joining, renewing, cancelling and ending in order', () {
      final h = SubscriptionHistory.of([
        ev('EXPIRATION', '2026-04-01'),
        ev('INITIAL_PURCHASE', '2026-01-01', grants: true, price: 20),
        ev('RENEWAL', '2026-02-01', grants: true, price: 20),
        ev('CANCELLATION', '2026-02-10', until: '2026-03-01'),
      ]);
      expect(h.entries.map((e) => e.step), [
        SubscriptionStep.joined,
        SubscriptionStep.renewed,
        SubscriptionStep.cancelled,
        SubscriptionStep.ended,
      ]);
      expect(h.joinedAt, DateTime.parse('2026-01-01'));
      expect(h.firstPaidAt, DateTime.parse('2026-01-01'));
      expect(h.lastPayment?.at, DateTime.parse('2026-02-01'));
      expect(h.lastCancelledAt, DateTime.parse('2026-02-10'));
      expect(h.lastEndedAt, DateTime.parse('2026-04-01'));
      expect(h.renewals, 1);
      expect(h.newestFirst.first.step, SubscriptionStep.ended);
    });

    test('a trial and a gift join without being a payment', () {
      final h = SubscriptionHistory.of([
        ev(
          'INITIAL_PURCHASE',
          '2026-01-01',
          grants: true,
          periodType: 'TRIAL',
          price: 0,
        ),
        ev('ADMIN_GRANT', '2026-01-05', grants: true),
        ev('ADMIN_REVOKE', '2026-01-09'),
      ]);
      expect(h.entries.first.step, SubscriptionStep.trial);
      expect(h.joinedAt, DateTime.parse('2026-01-01'));
      expect(h.firstPaidAt, isNull);
      expect(h.entries.last.step, SubscriptionStep.adminRevoke);
    });

    test('web providers are read by their words', () {
      final h = SubscriptionHistory.of([
        ev('payplus.charge', '2026-01-01', grants: true, price: 20),
        ev('payplus.charge', '2026-02-01', grants: true, price: 20),
        ev('payplus.charge.failed', '2026-03-01'),
        ev('subscription.canceled', '2026-03-02'),
        ev('payplus.refund', '2026-03-03'),
      ]);
      expect(h.entries.map((e) => e.step), [
        SubscriptionStep.joined,
        SubscriptionStep.renewed,
        SubscriptionStep.billingIssue,
        SubscriptionStep.cancelled,
        SubscriptionStep.refunded,
      ]);
    });

    test('a grant by hand is logged in the shape the rules accept', () {
      final row = AdminBillingFirestoreDataSource.adminEventRow(
        uid: 'u1',
        premium: true,
        by: 'a@b',
      );
      expect(row['type'], 'ADMIN_GRANT');
      expect(row['store'], 'admin');
      expect(row['price'], isNull);
      expect(row['uid'], 'u1');
      expect(
        AdminBillingFirestoreDataSource.adminEventRow(
          uid: 'u1',
          premium: false,
        )['type'],
        'ADMIN_REVOKE',
      );
    });
  });

  group('AiActions', () {
    test('the stored action wins, old rows follow fn then kind', () {
      expect(
        AiActions.of(action: 'image_book_cover', kind: 'image'),
        'image_book_cover',
      );
      expect(AiActions.of(action: 'nonsense'), 'other');
      expect(
        AiActions.of(fn: 'socialRecipe', kind: 'social_video'),
        'recipe_video',
      );
      expect(AiActions.of(kind: 'url'), 'recipe_url');
      expect(AiActions.of(kind: 'receipt'), 'receipt_scan');
    });

    test('areas group the actions', () {
      expect(AiActions.categoryOf('recipe_photo'), 'recipes');
      expect(AiActions.categoryOf('image_recipe'), 'recipes');
      expect(AiActions.categoryOf('image_book_cover'), 'books');
      expect(AiActions.categoryOf('receipt_scan'), 'shopping');
      expect(AiActions.categoryOf('assistant_chat'), 'assistant');
      expect(AiActions.categoryOf('image_other'), 'other');
      final by = AiActions.byCategory(const {
        'recipe_url': TokenTally(calls: 3),
        'recipe_text': TokenTally(calls: 15),
        'image_book_cover': TokenTally(calls: 2),
      });
      expect(by['recipes']!.calls, 18);
      expect(by['books']!.calls, 2);
    });

    test(
      'an aggregate that counted calls before actions falls back to kinds',
      () {
        const kinds = {
          'text': TokenTally(calls: 5),
          'image': TokenTally(calls: 2),
        };
        final partial = AiActions.split(const {
          'recipe_text': TokenTally(calls: 1),
        }, kinds);
        expect(partial['recipe_text']!.calls, 5);
        expect(partial['image_other']!.calls, 2);
        final full = AiActions.split(const {
          'recipe_text': TokenTally(calls: 5),
          'image_book_cover': TokenTally(calls: 2),
        }, kinds);
        expect(full['image_book_cover']!.calls, 2);
      },
    );

    test('attached files name their action', () {
      IngestionFile f(String mime) =>
          IngestionFile(bytes: Uint8List(0), mimeType: mime, name: 'x');
      expect(
        GeminiRecipeAiDataSource.filesAction([f('image/jpeg')]),
        'recipe_photo',
      );
      expect(
        GeminiRecipeAiDataSource.filesAction([f('application/pdf')]),
        'recipe_pdf',
      );
      expect(
        GeminiRecipeAiDataSource.filesAction([f('audio/mp4')]),
        'recipe_audio',
      );
    });
  });

  group('PlatformPlan', () {
    test('percentages and rows', () {
      const ios = PlatformPlan(users: 10, premium: 3);
      expect(ios.free, 7);
      expect(ios.premiumPercent, 30);
      expect(const PlatformPlan().premiumPercent, isNull);
      final rows = PlatformPlanTable.rowsOf(const {
        'android': PlatformPlan(users: 4, premium: 1),
        'web': PlatformPlan(users: 2),
        '': PlatformPlan(),
      });
      expect(rows.map((r) => r.$1), ['ios', 'android', 'web']);
      expect(PlatformPlan.totalOf(rows.map((r) => r.$2)).users, 6);
    });
  });
}
