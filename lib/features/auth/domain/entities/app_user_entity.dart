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

  /// A verified phone is the root identity every account must carry. Google and
  /// email are additions to it, never a substitute — an account that arrived by
  /// either is held at the gate until it proves a number.
  ///
  /// There is no unverified state to check: Firebase only adds the `phone`
  /// provider once the SMS code has been accepted.
  bool get needsPhoneVerification => !hasPhone;
}
