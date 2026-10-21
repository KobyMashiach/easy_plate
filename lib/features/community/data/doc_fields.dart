import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Tolerant reads of Firestore fields.
///
/// The app is no longer the only writer of the shared documents (shared
/// recipes, the forum, invites, collab documents, notifications, feedback):
/// the website and the functions write them too. A plain `as String?` on a
/// field another client wrote as a number throws a [TypeError], and one bad
/// document then took the whole list — and the page or bloc reading it —
/// down with it. Every reader here degrades to the default instead.

/// [value] when it is a string, else [fallback].
String docString(Object? value, [String fallback = '']) =>
    value is String ? value : fallback;

/// [value] when it is a string, else null.
String? docStringOrNull(Object? value) => value is String ? value : null;

/// A whole number from an int, a finite double or a numeric string.
int? docInt(Object? value) => switch (value) {
  final int i => i,
  final num n when n.isFinite => n.toInt(),
  final String s => int.tryParse(s.trim()) ?? docInt(double.tryParse(s.trim())),
  _ => null,
};

/// A finite number from a num or a numeric string.
double? docDouble(Object? value) => switch (value) {
  final num n when n.isFinite => n.toDouble(),
  final String s => docDouble(double.tryParse(s.trim())),
  _ => null,
};

/// True only for a real `true`; [fallback] when the field is not a bool.
bool docBool(Object? value, {bool fallback = false}) =>
    value is bool ? value : fallback;

/// A point in time from a Firestore [Timestamp], a [DateTime], epoch
/// milliseconds or an ISO-8601 string.
DateTime? docDate(Object? value) => switch (value) {
  final Timestamp t => t.toDate(),
  final DateTime d => d,
  // Out of DateTime's range (±8.64e15 ms) would throw a RangeError.
  final num n when n.isFinite && n.abs() <= 8.64e15 =>
    DateTime.fromMillisecondsSinceEpoch(n.toInt()),
  // Local, like a Timestamp's toDate: a "Z" string would otherwise show
  // UTC hours.
  final String s => DateTime.tryParse(s.trim())?.toLocal(),
  _ => null,
};

/// The strings of a list; anything else in it, or a non-list, is dropped.
List<String> docStrings(Object? value) => [
  if (value is List)
    for (final item in value)
      if (item is String) item,
];

/// A map with string keys, or null when [value] is not a map.
Map<String, dynamic>? docMap(Object? value) => value is Map
    ? {
        for (final entry in value.entries)
          if (entry.key is String) entry.key as String: entry.value,
      }
    : null;

/// The maps of a list, each with string keys; anything else is dropped.
List<Map<String, dynamic>> docMaps(Object? value) => [
  if (value is List)
    for (final item in value) ?docMap(item),
];

/// The enum value named [value], or null for a missing or unknown name.
T? docEnum<T extends Enum>(List<T> values, Object? value) =>
    value is String ? values.where((v) => v.name == value).firstOrNull : null;

/// [parse] over every document, skipping (and logging) one that throws or
/// parses to null, so a single malformed document costs that row only.
List<T> parseEach<S, T>(
  Iterable<S> items,
  T? Function(S item) parse, {
  required String label,
}) {
  final out = <T>[];
  for (final item in items) {
    try {
      final parsed = parse(item);
      if (parsed != null) out.add(parsed);
    } catch (e) {
      debugPrint('$label: skipped a malformed document: $e');
    }
  }
  return out;
}

/// [value] when it is a list, else an empty one.
List<Object?> docList(Object? value) => value is List ? value : const [];

/// [read], with a throw — a parser outside this feature meeting a field of
/// the wrong type — read as null rather than failing the whole document.
T? docOrNull<T>(T? Function() read) {
  try {
    return read();
  } catch (e) {
    debugPrint('Malformed field read as empty: $e');
    return null;
  }
}

/// A non-blank string, else null — for links such as photo URLs, where an
/// empty string (as a web form may save) would be fetched and fail.
String? docNonEmpty(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;
