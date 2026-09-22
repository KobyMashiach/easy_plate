import '../entities/dashboard_entities.dart';

/// The pure arithmetic behind the dashboard: folding per-day documents into
/// the range's totals and per-user rows. Kept out of the data source so it
/// can be pinned by tests without Firestore.
class AggregateUsageUseCase {
  const AggregateUsageUseCase();

  /// The day string the functions use: `YYYY-MM-DD` in UTC.
  static String dayOf(DateTime at) =>
      at.toUtc().toIso8601String().substring(0, 10);

  /// A calendar date as the same `YYYY-MM-DD` string, without moving it
  /// through UTC — the dates the administrator picks are days, not
  /// instants.
  static String calendarDay(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// The first day the period covers, or null for everything.
  static String? sinceDay(DashboardPeriod period, DateTime now) {
    if (period.isCustom) return calendarDay(period.from!);
    final days = period.range.days;
    if (days == null) return null;
    return dayOf(now.toUtc().subtract(Duration(days: days - 1)));
  }

  /// The last day the period covers, or null for "through today".
  static String? untilDay(DashboardPeriod period, DateTime now) =>
      period.isCustom ? calendarDay(period.to!) : null;

  /// The first day the charts show — at least a week, so a single-day range
  /// still has bars to compare against.
  static String chartSinceDay(DashboardPeriod period, DateTime now) {
    if (period.isCustom) {
      final span = period.to!.difference(period.from!).inDays + 1;
      final from = span >= 7
          ? period.from!
          : period.to!.subtract(const Duration(days: 6));
      return calendarDay(from);
    }
    final days = period.range.days ?? 400;
    return dayOf(
      now.toUtc().subtract(Duration(days: (days < 7 ? 7 : days) - 1)),
    );
  }

  static Map<String, TokenTally> mergeTallies(
    Map<String, TokenTally> into,
    Map<String, TokenTally> from,
  ) {
    final out = Map<String, TokenTally>.of(into);
    from.forEach(
      (key, tally) => out[key] = (out[key] ?? TokenTally.zero) + tally,
    );
    return out;
  }

  TokenTally total(Iterable<DailyAiUsage> days) =>
      days.fold(TokenTally.zero, (sum, d) => sum + d.total);

  Map<String, TokenTally> byModel(Iterable<DailyAiUsage> days) =>
      days.fold({}, (sum, d) => mergeTallies(sum, d.byModel));

  Map<String, TokenTally> byKind(Iterable<DailyAiUsage> days) =>
      days.fold({}, (sum, d) => mergeTallies(sum, d.byKind));

  /// uid → model → tally over [days].
  Map<String, Map<String, TokenTally>> byUser(Iterable<DailyAiUsage> days) {
    final out = <String, Map<String, TokenTally>>{};
    for (final day in days) {
      day.byUser.forEach((uid, models) {
        out[uid] = mergeTallies(out[uid] ?? const {}, models);
      });
    }
    return out;
  }

  /// A per-user total from its model split.
  static TokenTally sumOf(Map<String, TokenTally> byModel) =>
      byModel.values.fold(TokenTally.zero, (a, b) => a + b);
}
