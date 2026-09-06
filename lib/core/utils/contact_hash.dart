import 'dart:convert';

import 'package:crypto/crypto.dart';

/// How one user finds another without anyone's contact details being readable.
///
/// The directory is keyed by a hash of the contact, never the contact itself:
/// a signed-in user who knows an email or phone can look up the uid behind it,
/// but nobody can list emails or phones out of the collection.
typedef NormalizedContact = ({String value, bool isEmail});

/// Emails lower-cased and trimmed; phones to E.164, upgrading a local Israeli
/// `05…` the same way the sign-in form does. Null when it is neither.
NormalizedContact? normalizeContact(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  if (trimmed.contains('@')) {
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed)) return null;
    return (value: trimmed.toLowerCase(), isEmail: true);
  }

  final digits = trimmed.replaceAll(RegExp(r'[\s\-()]'), '');
  if (!RegExp(r'^\+?\d{7,15}$').hasMatch(digits)) return null;
  final e164 = digits.startsWith('+')
      ? digits
      : digits.startsWith('0')
          ? '+972${digits.substring(1)}'
          : '+$digits';
  return (value: e164, isEmail: false);
}

/// The directory key for a normalised contact.
String contactHash(String normalized) => sha256.convert(utf8.encode(normalized)).toString();
