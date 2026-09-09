/// Where the paywall sends people for the legal text Apple and Google require
/// next to a subscription (App Store guideline 3.1.2, Play's subscription
/// policy): a terms-of-use link and a privacy-policy link, both reachable
/// from the purchase screen itself.
abstract class LegalLinks {
  /// Apple's standard EULA, which is what App Store Connect uses when no
  /// custom one is uploaded. Google accepts it as a terms link too.
  static final terms = Uri.parse(
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
  );

  /// There is no privacy policy page yet (see the release audit): this is the
  /// address it has to end up at, on the same domain as the support mailbox.
  static final privacy = Uri.parse('https://easyplate.app/privacy');
}
