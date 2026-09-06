import '../constants/app_constants.dart';
import 'i18n/strings.g.dart';

/// Formats a recipe duration, rolling over into hours past 59 minutes.
///
/// A prep time of 160 reads as "2 hr 40 min" rather than "160 min" — past an
/// hour, minutes stop being something anyone can picture. A whole number of
/// hours drops the minutes entirely instead of showing a bare zero.
String durationLabel(int minutes) {
  if (minutes < 60) return t.recipe.minutes(count: minutes);

  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  return remainder == 0
      ? t.recipe.hours(count: hours)
      : t.recipe.hoursAndMinutes(hours: hours, minutes: remainder);
}

/// Null means the source never stated a time, which is not the same as zero.
String optionalDurationLabel(int? minutes) =>
    minutes == null ? kMissingInfoPlaceholder : durationLabel(minutes);
