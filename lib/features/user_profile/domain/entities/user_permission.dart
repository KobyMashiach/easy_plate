/// What an account may do, stored as `users/{uid}.permission`.
///
/// Only a server sets it: the Firestore rules let the app create it as
/// [user] and never change it. An administrator grants and removes
/// [superuser] and [admin] from the admin screens (through the adminUsers /
/// adminPanel functions), never on their own account. A missing or unknown
/// value is [user].
enum UserPermission {
  /// The console, the support inbox, every account's data, and no limit on
  /// devices.
  admin,

  /// Every feature switched on — Premium ones included, whatever the flags
  /// say — and no device limit; none of the administrator's powers.
  superuser,

  /// Everyone else.
  user
  ;

  static UserPermission fromName(Object? name) => switch (name) {
    'admin' => admin,
    'superuser' => superuser,
    _ => user,
  };
}
