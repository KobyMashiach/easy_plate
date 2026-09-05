/// The signed-in identity, independent of the profile document the app stores
/// alongside it in Firestore.
class AppUserEntity {
  final String uid;
  final String? email;
  final String? phoneNumber;
  final String? displayName;
  final String? photoUrl;

  const AppUserEntity({
    required this.uid,
    this.email,
    this.phoneNumber,
    this.displayName,
    this.photoUrl,
  });
}
