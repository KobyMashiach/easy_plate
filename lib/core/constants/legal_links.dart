import '../utils/i18n/strings.g.dart';

/// Where the paywall and the help page send people for the legal text Apple
/// and Google require next to a subscription (App Store guideline 3.1.2,
/// Play's subscription policy): a terms-of-use link and a privacy-policy
/// link, both reachable from the purchase screen itself.
///
/// The site has every document in the app's five languages, prerendered at
/// `/privacy` (English) and `/he/privacy`, `/ar/…`, `/fr/…`, `/ru/…`, so the
/// link follows the language the app is in rather than always opening the
/// English page. Read on every access: the language can change mid-session.
abstract class LegalLinks {
  static const site = 'https://aieasyplate.app';

  /// Our own terms (replaced Apple's standard EULA once the page existed;
  /// the same text should be pasted into App Store Connect as a custom
  /// EULA so the store listing shows it too).
  static Uri get terms => _localized('terms');

  static Uri get privacy => _localized('privacy');

  /// The page in the app's current language; English has no prefix.
  static Uri _localized(String doc) => localizedFor(
    doc,
    LocaleSettings.currentLocale.languageCode,
  );

  /// The rule on its own, for tests: a known language gets its prefix,
  /// anything else the English page.
  static Uri localizedFor(String doc, String languageCode) {
    const prefixed = {'he', 'ar', 'fr', 'ru'};
    final prefix = prefixed.contains(languageCode) ? '/$languageCode' : '';
    return Uri.parse('$site$prefix/$doc');
  }
}
