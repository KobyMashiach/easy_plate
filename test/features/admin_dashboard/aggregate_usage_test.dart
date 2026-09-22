import 'package:easy_plate/features/admin_dashboard/domain/entities/dashboard_entities.dart';
import 'package:easy_plate/features/admin_dashboard/domain/usecases/aggregate_usage_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

DailyAiUsage day(
  String day, {
  Map<String, TokenTally> models = const {},
  Map<String, TokenTally> kinds = const {},
  Map<String, Map<String, TokenTally>> users = const {},
}) {
  return DailyAiUsage(
    day: day,
    date: DateTime.parse('${day}T00:00:00Z'),
    total: AggregateUsageUseCase.sumOf(models),
    byModel: models,
    byKind: kinds,
    byUser: users,
  );
}

void main() {
  const flash = 'gemini-3_8-flash';
  const lite = 'gemini-3_5-flash-lite';
  const aggregate = AggregateUsageUseCase();

  group('pricing', () {
    test(
      'bills cached prompt tokens at the cached rate and thoughts as output',
      () {
        const price = ModelPrice(
          inputPerMillion: 1,
          outputPerMillion: 10,
          cachedPerMillion: 0.1,
        );
        const tally = TokenTally(
          input: 1000000,
          cached: 500000,
          output: 100000,
          thoughts: 100000,
        );
        // 0.5M input at $1 + 0.5M cached at $0.1 + 0.2M output at $10.
        expect(price.costOf(tally), closeTo(0.5 + 0.05 + 2.0, 1e-9));
      },
    );

    test('grounding searches are billed per query on top of the tokens', () {
      final pricing = AiPricing.defaults.copyWith(searchPerThousand: 35);
      const tally = TokenTally(input: 1000000, output: 0, searches: 2);
      // 1M input at \$0.75 plus two queries at \$35/1000.
      expect(
        pricing.costOf('gemini-3_8-flash', tally),
        closeTo(0.75 + 0.07, 1e-9),
      );
    });

    test('image output tokens are billed at the image rate', () {
      const price = ModelPrice(
        inputPerMillion: 0.5,
        outputPerMillion: 3,
        cachedPerMillion: 0.05,
        imageOutputPerMillion: 60,
      );
      const tally = TokenTally(input: 133, output: 1567, imageOutput: 1120);
      // 133 in at $0.5 + 447 text out at $3 + 1120 image out at $60.
      expect(
        price.costOf(tally),
        closeTo((133 * 0.5 + 447 * 3 + 1120 * 60) / 1e6, 1e-12),
      );
    });

    test('an unknown model takes the fallback price, and says so', () {
      final pricing = AiPricing.defaults;
      expect(pricing.knows('gemini-9-ultra'), isFalse);
      expect(pricing.priceFor('gemini-9-ultra'), same(pricing.fallback));
    });

    test('model keys match what the functions write', () {
      expect(AiPricing.keyFor('gemini-3.8-flash'), flash);
      expect(AiPricing.keyFor(''), 'unknown');
      expect(AiPricing.displayName(flash), 'gemini-3.8-flash');
    });
  });

  group('tallies', () {
    test('add field by field and read a Firestore map', () {
      const a = TokenTally(calls: 1, input: 10, output: 5, total: 15);
      final b = TokenTally.fromMap({
        'calls': 2,
        'cacheHits': 1,
        'input': 20,
        'total': 20,
      });
      final sum = a + b;
      expect(sum.calls, 3);
      expect(sum.cacheHits, 1);
      expect(sum.input, 30);
      expect(sum.output, 5);
      expect(sum.total, 35);
      expect(sum.modelCalls, 2);
    });

    test('billable input never goes negative', () {
      expect(const TokenTally(input: 5, cached: 9).billableInput, 0);
    });
  });

  group('ranges', () {
    final now = DateTime.utc(2026, 9, 17, 10);

    test('today is one UTC day; a month reaches back 29', () {
      expect(
        AggregateUsageUseCase.sinceDay(DashboardPeriod.today, now),
        '2026-09-17',
      );
      expect(
        AggregateUsageUseCase.sinceDay(DashboardPeriod.month, now),
        '2026-08-19',
      );
      expect(AggregateUsageUseCase.sinceDay(DashboardPeriod.all, now), isNull);
      expect(
        AggregateUsageUseCase.untilDay(DashboardPeriod.month, now),
        isNull,
      );
    });

    test('a custom period is the two calendar dates, inclusive', () {
      final period = DashboardPeriod(
        DashboardRange.custom,
        from: DateTime(2026, 9, 1),
        to: DateTime(2026, 9, 3),
      );
      expect(AggregateUsageUseCase.sinceDay(period, now), '2026-09-01');
      expect(AggregateUsageUseCase.untilDay(period, now), '2026-09-03');
      // Too short for a chart: the window reaches back to a week.
      expect(AggregateUsageUseCase.chartSinceDay(period, now), '2026-08-28');
    });

    test('the chart shows at least a week even for a single-day range', () {
      expect(
        AggregateUsageUseCase.chartSinceDay(DashboardPeriod.today, now),
        '2026-09-11',
      );
      expect(
        AggregateUsageUseCase.chartSinceDay(DashboardPeriod.month, now),
        '2026-08-19',
      );
    });

    test('a local time after UTC midnight still lands on the UTC day', () {
      // 01:30 in Israel on the 18th is 22:30 UTC on the 17th.
      final local = DateTime(2026, 9, 18, 1, 30);
      final utc = local.toUtc();
      expect(
        AggregateUsageUseCase.dayOf(local),
        AggregateUsageUseCase.dayOf(utc),
      );
    });
  });

  group('folding days', () {
    final days = [
      day(
        '2026-09-15',
        models: {
          flash: const TokenTally(calls: 2, input: 100, output: 20, total: 120),
        },
        kinds: {'url': const TokenTally(calls: 2)},
        users: {
          'ann': {
            flash: const TokenTally(
              calls: 2,
              input: 100,
              output: 20,
              total: 120,
            ),
          },
        },
      ),
      day(
        '2026-09-16',
        models: {
          flash: const TokenTally(calls: 1, input: 50, output: 10, total: 60),
          lite: const TokenTally(calls: 3, input: 30, output: 3, total: 33),
        },
        kinds: {
          'url': const TokenTally(calls: 1),
          'search': const TokenTally(calls: 3),
        },
        users: {
          'ann': {
            lite: const TokenTally(calls: 3, input: 30, output: 3, total: 33),
          },
          'bob': {
            flash: const TokenTally(calls: 1, input: 50, output: 10, total: 60),
          },
        },
      ),
    ];

    test('totals, models and kinds add across days', () {
      expect(aggregate.total(days).calls, 6);
      expect(aggregate.total(days).total, 213);
      expect(aggregate.byModel(days)[flash]!.calls, 3);
      expect(aggregate.byModel(days)[lite]!.total, 33);
      expect(aggregate.byKind(days)['url']!.calls, 3);
      expect(aggregate.byKind(days)['search']!.calls, 3);
    });

    test('per-user rows keep the model split so each is priced right', () {
      final users = aggregate.byUser(days);
      expect(users['ann']![flash]!.calls, 2);
      expect(users['ann']![lite]!.calls, 3);
      expect(users['bob']!.keys, [flash]);
      final ann = UserAiUsage(
        uid: 'ann',
        name: 'Ann',
        email: null,
        premium: false,
        platform: 'ios',
        total: AggregateUsageUseCase.sumOf(users['ann']!),
        byModel: users['ann']!,
      );
      final pricing = AiPricing.defaults;
      expect(
        ann.cost(pricing),
        closeTo(
          pricing.costOf(flash, users['ann']![flash]!) +
              pricing.costOf(lite, users['ann']![lite]!),
          1e-12,
        ),
      );
    });
  });
}
