/// Why a typed number was not accepted.
enum PhoneRejection {
  /// Not a phone number at all.
  invalid,

  /// A local number (no `+`) where we cannot know the country.
  needsCountryCode,
}

/// A typed phone number in E.164 (`+972501234567`), or why it is not one.
typedef PhoneInput = ({String? e164, PhoneRejection? rejection});

/// Firebase requires E.164. A local Israeli `05…` is the common paste in
/// Hebrew, so there it is upgraded to `+972…`. In any other language a
/// leading 0 means nothing we can resolve — a French `06…` sent as `+9726…`
/// texted the code to a stranger's number, or nowhere — so the country code
/// is asked for instead.
PhoneInput normalisePhone(String raw, {required bool israeliLocal}) {
  final trimmed = raw.replaceAll(RegExp(r'[\s\-().]'), '');
  final String candidate;
  if (trimmed.startsWith('+')) {
    candidate = trimmed;
  } else if (trimmed.startsWith('0') && israeliLocal) {
    candidate = '+972${trimmed.substring(1)}';
  } else if (trimmed.startsWith('972') && israeliLocal) {
    candidate = '+$trimmed';
  } else if (RegExp(r'^\d+$').hasMatch(trimmed) && trimmed.isNotEmpty) {
    return (e164: null, rejection: PhoneRejection.needsCountryCode);
  } else {
    return (e164: null, rejection: PhoneRejection.invalid);
  }
  return RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(candidate)
      ? (e164: candidate, rejection: null)
      : (e164: null, rejection: PhoneRejection.invalid);
}
