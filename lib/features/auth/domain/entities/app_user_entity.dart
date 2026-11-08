/// The signed-in identity, independent of the profile document the app stores
/// alongside it in Firestore.
class AppUserEntity {
  final String uid;
  final String? email;
  final String? phoneNumber;
  final String? displayName;
  final String? photoUrl;
  final bool emailVerified;

  /// Firebase provider ids linked to this account (`password`, `phone`,
  /// `google.com`, `apple.com`). One account can carry several, which is how signing in by
  /// phone later reaches the account that was created with an email.
  final List<String> providerIds;

  const AppUserEntity({
    required this.uid,
    this.email,
    this.phoneNumber,
    this.displayName,
    this.photoUrl,
    this.emailVerified = false,
    this.providerIds = const [],
  });

  bool get hasPassword => providerIds.contains('password');
  bool get hasPhone => providerIds.contains('phone');
  bool get hasGoogle => providerIds.contains('google.com');
  bool get hasApple => providerIds.contains('apple.com');

  /// Only a password account has an email the user chose and must prove. A
  /// Google account arrives already verified, and a phone account has no email
  /// to verify at all.
  bool get needsEmailVerification => hasPassword && !emailVerified;

  /// A Google or Apple identity: an account a person had to create with the
  /// provider (which asks for a phone of its own), unlike a bare email.
  bool get hasSocialIdentity => hasGoogle || hasApple;

  /// Whether the account still has to prove a phone before the gate opens.
  /// By default a verified phone is the root identity every account carries,
  /// and Google and email are additions to it — an account that arrived by
  /// either is held until it proves a number. With [phoneOptional] (the
  /// `ff_phone_optional` flag) a Google or Apple identity is enough on its
  /// own; an email/password account is held either way.
  ///
  /// There is no unverified state to check: Firebase only adds the `phone`
  /// provider once the SMS code has been accepted.
  bool needsPhoneVerificationWith({required bool phoneOptional}) =>
      !hasPhone && !(phoneOptional && hasSocialIdentity);

  /// [needsPhoneVerificationWith] with the phone required of everyone.
  bool get needsPhoneVerification =>
      needsPhoneVerificationWith(phoneOptional: false);
}
