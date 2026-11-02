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

/// A country the phone field's dial-code menu offers.
///
/// [trunkZero]: the national number is written with a leading 0 that is
/// dropped after the country code (Israel `050…` → `+97250…`).
/// [maxDigits]: the longest national number as typed, 0 included.
class PhoneCountry {
  final String iso;
  final String dial;
  final bool trunkZero;
  final int maxDigits;

  /// A national number as people write it, shown as the field's hint.
  final String example;

  /// Searched besides the name in the app's language (`countries.*`).
  final String englishName;

  const PhoneCountry(
    this.iso,
    this.dial,
    this.englishName, {
    this.trunkZero = true,
    this.maxDigits = 10,
    required this.example,
  });

  /// The flag emoji, from the two regional-indicator letters of [iso].
  String get flag => String.fromCharCodes(
    iso.toUpperCase().codeUnits.map((c) => 0x1F1E6 + c - 0x41),
  );

  static const israel = PhoneCountry(
    'IL',
    '972',
    'Israel',
    example: '0501234567',
  );

  /// Israel first; the rest are where the app's other languages are
  /// spoken, and the countries most of its users come from.
  static const all = [
    israel,
    PhoneCountry(
      'US',
      '1',
      'United States',
      trunkZero: false,
      example: '2015550123',
    ),
    PhoneCountry('CA', '1', 'Canada', trunkZero: false, example: '5065550123'),
    PhoneCountry(
      'GB',
      '44',
      'United Kingdom',
      maxDigits: 11,
      example: '07400123456',
    ),
    PhoneCountry('FR', '33', 'France', example: '0612345678'),
    PhoneCountry('RU', '7', 'Russia', trunkZero: false, example: '9123456789'),
    PhoneCountry('UA', '380', 'Ukraine', example: '0501234567'),
    PhoneCountry('DE', '49', 'Germany', maxDigits: 12, example: '015123456789'),
    PhoneCountry(
      'ES',
      '34',
      'Spain',
      trunkZero: false,
      maxDigits: 9,
      example: '612345678',
    ),
    PhoneCountry('IT', '39', 'Italy', trunkZero: false, example: '3123456789'),
    PhoneCountry('NL', '31', 'Netherlands', example: '0612345678'),
    PhoneCountry('BE', '32', 'Belgium', example: '0470123456'),
    PhoneCountry('CH', '41', 'Switzerland', example: '0781234567'),
    PhoneCountry('AE', '971', 'United Arab Emirates', example: '0501234567'),
    PhoneCountry('PS', '970', 'Palestine', example: '0599123456'),
    PhoneCountry('JO', '962', 'Jordan', example: '0790123456'),
    PhoneCountry('EG', '20', 'Egypt', maxDigits: 11, example: '01001234567'),
    PhoneCountry('MA', '212', 'Morocco', example: '0650123456'),
    PhoneCountry('ET', '251', 'Ethiopia', example: '0911234567'),
    PhoneCountry('AU', '61', 'Australia', example: '0412345678'),
    PhoneCountry(
      'BR',
      '55',
      'Brazil',
      trunkZero: false,
      maxDigits: 11,
      example: '11961234567',
    ),
  ];

  static PhoneCountry? byIso(String? iso) {
    for (final c in all) {
      if (c.iso == iso?.toUpperCase()) return c;
    }
    return null;
  }

  /// The country whose code [digits] (an international number without its
  /// `+`) starts with; the longest code wins, the first listed on a tie
  /// (`1` is the US, not Canada).
  static PhoneCountry? byDialPrefix(String digits) {
    PhoneCountry? best;
    for (final c in all) {
      if (digits.startsWith(c.dial) &&
          (best == null || c.dial.length > best.dial.length)) {
        best = c;
      }
    }
    return best;
  }
}

/// What the phone field keeps of [raw]: digits only (a dash, a space, a
/// bracket or a letter is dropped as it comes in), the country code taken
/// off a pasted or autofilled international number, at most
/// [PhoneCountry.maxDigits].
///
/// [country] is the one chosen in the menu; when [raw] is international
/// (`+…` or `00…`) the country it names is returned too, so the menu can
/// follow it.
({String digits, PhoneCountry country}) phoneFieldDigits(
  String raw,
  PhoneCountry country,
) {
  var digits = raw.replaceAll(RegExp(r'\D'), '');
  var chosen = country;
  final trimmed = raw.trimLeft();
  final international = trimmed.startsWith('+') || digits.startsWith('00');
  if (international) {
    final rest = digits.startsWith('00') ? digits.substring(2) : digits;
    final named = rest.startsWith(country.dial)
        ? country
        : PhoneCountry.byDialPrefix(rest);
    if (named != null) {
      chosen = named;
      digits = rest.substring(named.dial.length);
    }
  } else if (digits.length > country.maxDigits &&
      digits.startsWith(country.dial)) {
    // "972508247743" pasted without its +.
    digits = digits.substring(country.dial.length);
  }
  if (digits.length > chosen.maxDigits) {
    digits = digits.substring(0, chosen.maxDigits);
  }
  return (digits: digits, country: chosen);
}

/// [national] (as the field holds it) in [country], as E.164 for Firebase:
/// `0508247743`, `508247743` and `050-824-7743` in Israel are all
/// `+972508247743`.
PhoneInput composePhone(String national, PhoneCountry country) {
  var digits = national.replaceAll(RegExp(r'\D'), '');
  if (country.trunkZero && digits.startsWith('0')) digits = digits.substring(1);
  if (digits.isEmpty) return (e164: null, rejection: PhoneRejection.invalid);
  // Israel: 9 digits for a mobile, 8 for a landline, after the 0.
  final minDigits = country == PhoneCountry.israel ? 8 : 6;
  final maxDigits = country == PhoneCountry.israel ? 9 : 14;
  final candidate = '+${country.dial}$digits';
  final ok =
      digits.length >= minDigits &&
      digits.length <= maxDigits &&
      RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(candidate);
  return ok
      ? (e164: candidate, rejection: null)
      : (e164: null, rejection: PhoneRejection.invalid);
}
