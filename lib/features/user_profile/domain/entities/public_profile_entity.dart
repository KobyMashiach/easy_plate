/// The part of a profile everyone is allowed to see.
///
/// Separate from [UserProfileEntity] because that document also holds an email,
/// a phone number and a push token, and Firestore rules grant or deny a whole
/// document — there is no way to hide individual fields on read. So the display
/// name and photo live in their own world-readable document instead.
class PublicProfileEntity {
  final String uid;
  final String fullName;
  final String? photoUrl;

  const PublicProfileEntity({
    required this.uid,
    required this.fullName,
    this.photoUrl,
  });
}
