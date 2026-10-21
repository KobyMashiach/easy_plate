import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'i18n/strings.g.dart';

/// How one user finds another without anyone's contact details being readable.
///
/// The directory is keyed by a hash of the contact, never the contact itself:
/// a signed-in user who knows an email or phone can look up the uid behind it,
/// but nobody can list emails or phones out of the collection.
typedef NormalizedContact = ({String value, bool isEmail});

/// Emails lower-cased and trimmed; phones to E.164. Null when it is neither.
///
/// Follows the sign-in form's rule (`normalisePhone`): a number with its
/// `+` is taken as written, whatever the language — so every number already
/// in the directory (published from the token's E.164) hashes as before. A
/// local `05…` (or a bare `972…`) is upgraded to `+972…` only when
/// [israeliLocal] — by default, when the app is in Hebrew. In any other
/// language a leading 0 names no country we can know, and guessing Israel
/// looked up (and invited) a stranger's number, so a bare number is refused
/// and the share sheet asks for the country code.
NormalizedContact? normalizeContact(String raw, {bool? israeliLocal}) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  if (trimmed.contains('@')) {
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed)) return null;
    return (value: trimmed.toLowerCase(), isEmail: true);
  }

  final digits = trimmed.replaceAll(RegExp(r'[\s\-().]'), '');
  if (!RegExp(r'^\+?\d{7,15}$').hasMatch(digits)) return null;
  if (digits.startsWith('+')) return (value: digits, isEmail: false);
  final local =
      israeliLocal ?? LocaleSettings.currentLocale.languageCode == 'he';
  if (!local) return null;
  if (digits.startsWith('0')) {
    return (value: '+972${digits.substring(1)}', isEmail: false);
  }
  if (digits.startsWith('972')) return (value: '+$digits', isEmail: false);
  return null;
}

/// The directory key for a normalised contact.
String contactHash(String normalized) =>
    sha256.convert(utf8.encode(normalized)).toString();
