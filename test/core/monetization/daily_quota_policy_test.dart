import 'package:easy_plate/core/monetization/daily_quota_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const limits = QuotaLimits.defaults;

  group('shared recipes', () {
    GateVerdict verdict(int viewed, {bool seen = false, bool premium = false}) =>
        DailyQuotaPolicy.sharedRecipe(
          viewedToday: viewed,
          alreadyViewed: seen,
          premium: premium,
          limits: limits,
        );

    test('the first three of the day are free', () {
      expect(verdict(0), GateVerdict.free);
      expect(verdict(2), GateVerdict.free);
    });

    test('four to six cost a video', () {
      expect(verdict(3), GateVerdict.rewarded);
      expect(verdict(5), GateVerdict.rewarded);
    });

    test('the seventh is refused until tomorrow', () {
      expect(verdict(6), GateVerdict.blocked);
      expect(verdict(40), GateVerdict.blocked);
    });

    test('a recipe already opened today is free again, even past the limit', () {
      expect(verdict(6, seen: true), GateVerdict.free);
    });

    test('premium sees no gate at all', () {
      expect(verdict(99, premium: true), GateVerdict.free);
    });

    test('the counters the banner shows', () {
      expect(DailyQuotaPolicy.remainingFreeSharedViews(0, limits), 3);
      expect(DailyQuotaPolicy.remainingFreeSharedViews(3, limits), 0);
      expect(DailyQuotaPolicy.remainingRewardedSharedViews(0, limits), 3);
      expect(DailyQuotaPolicy.remainingRewardedSharedViews(3, limits), 3);
      expect(DailyQuotaPolicy.remainingRewardedSharedViews(5, limits), 1);
      expect(DailyQuotaPolicy.remainingRewardedSharedViews(6, limits), 0);
      expect(DailyQuotaPolicy.remainingRewardedSharedViews(20, limits), 0);
    });
  });

  group('AI extraction', () {
    GateVerdict verdict(int used, {bool premium = false}) =>
        DailyQuotaPolicy.aiExtraction(usedToday: used, premium: premium, limits: limits);

    test('every extraction costs a video, the first included', () {
      expect(verdict(0), GateVerdict.rewarded);
      expect(verdict(1), GateVerdict.rewarded);
    });

    test('the third of the day is refused', () {
      expect(verdict(2), GateVerdict.blocked);
    });

    test('premium extracts freely', () {
      expect(verdict(50, premium: true), GateVerdict.free);
    });

    test('remaining never goes negative', () {
      expect(DailyQuotaPolicy.remainingAiExtractions(0, limits), 2);
      expect(DailyQuotaPolicy.remainingAiExtractions(2, limits), 0);
      expect(DailyQuotaPolicy.remainingAiExtractions(7, limits), 0);
    });
  });

  test('a console-tuned limit is honoured', () {
    const generous = QuotaLimits(
      freeSharedViews: 10,
      rewardedSharedViews: 0,
      rewardedAiExtractions: 0,
    );
    expect(
      DailyQuotaPolicy.sharedRecipe(
        viewedToday: 9,
        alreadyViewed: false,
        premium: false,
        limits: generous,
      ),
      GateVerdict.free,
    );
    expect(
      DailyQuotaPolicy.sharedRecipe(
        viewedToday: 10,
        alreadyViewed: false,
        premium: false,
        limits: generous,
      ),
      GateVerdict.blocked,
      reason: 'no rewarded tier when the console sets it to zero',
    );
    expect(
      DailyQuotaPolicy.aiExtraction(usedToday: 0, premium: false, limits: generous),
      GateVerdict.blocked,
    );
  });
}
