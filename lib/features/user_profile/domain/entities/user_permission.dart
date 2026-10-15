/// What an account may do, stored as `users/{uid}.permission`.
///
/// Only the Firebase console (or a server) sets it: the Firestore rules let
/// the app create it as [user] and never change it. A missing or unknown
/// value is [user].
enum UserPermission {
  /// The console, the support inbox, every account's data, and no limit on
  /// devices.
  admin,

  /// Everyone else.
  user;

  static UserPermission fromName(Object? name) =>
      name == admin.name ? admin : user;
}
