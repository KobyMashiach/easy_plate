import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_ce/hive.dart';

part 'daily_usage_model.freezed.dart';
part 'daily_usage_model.g.dart';

/// What the account has spent of its daily allowances, and on which day.
///
/// Stored per account (the box is scoped by uid) and mirrored to
/// `users/{uid}/usage/current`, so a second device or a reinstall carries the
/// same count rather than a fresh one.
@freezed
@HiveType(typeId: 12)
sealed class DailyUsageModel with _$DailyUsageModel {
  static const hiveKey = 'dailyUsageBox';
  static const storageKey = 'current';

  const factory DailyUsageModel({
    /// `yyyy-MM-dd` in the device's timezone, from [TrustedClock].
    @HiveField(0) required String day,

    /// Shared recipes opened today, by feed id. A set rather than a count so
    /// re-opening a recipe already paid for costs nothing.
    @HiveField(1) @Default([]) List<String> viewedSharedIds,

    /// AI extractions from a link started today.
    @HiveField(2) @Default(0) int aiExtractions,
  }) = _DailyUsageModel;

  const DailyUsageModel._();

  factory DailyUsageModel.fromJson(Map<String, dynamic> json) =>
      _$DailyUsageModelFromJson(json);

  factory DailyUsageModel.empty(String day) => DailyUsageModel(day: day);

  /// The record that applies on [today].
  ///
  /// Only a *later* day resets the counts. An earlier one means the device
  /// clock was moved back (or a stale server read), and the safe answer is to
  /// keep what is stored rather than hand out a second allowance.
  DailyUsageModel forDay(String today) =>
      today.compareTo(day) > 0 ? DailyUsageModel.empty(today) : this;
}
