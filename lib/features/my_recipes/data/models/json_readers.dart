import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_enums.dart';

// Readers for the fields of a mirrored record that another writer — the
// website, an admin edit in the console, a newer build — may shape a little
// differently from this build. A record that fails to parse is skipped by
// the cloud merge, and the stale local copy is then pushed back over the
// newer one, so a date sent as a timestamp or an enum name this build does
// not know must cost one field, not the whole record.

/// A date as an ISO string (what the app and the website write), a
/// Firestore timestamp, epoch milliseconds or a [DateTime].
DateTime readJsonDate(Object? value) => switch (value) {
  final String s => DateTime.parse(s),
  final Timestamp ts => ts.toDate(),
  final num ms => DateTime.fromMillisecondsSinceEpoch(ms.toInt()),
  final DateTime d => d,
  _ => throw FormatException('Not a date: $value'),
};

/// The dietary tags this build knows; an unknown name is dropped.
List<DietaryPreference> readDietaryTags(Object? value) => [
  if (value is List)
    for (final name in value)
      ?DietaryPreference.values.where((p) => p.name == name).firstOrNull,
];

/// A unit this build knows, else [MeasurementUnit.unspecified].
MeasurementUnit readMeasurementUnit(Object? value) =>
    MeasurementUnit.values.where((u) => u.name == value).firstOrNull ??
    MeasurementUnit.unspecified;
