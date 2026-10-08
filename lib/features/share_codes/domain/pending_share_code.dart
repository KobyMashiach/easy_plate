import 'share_code_entity.dart';

/// A share link that arrived before the account was ready for it.
///
/// A cold start on `/s/CODE` is bounced by the auth gate to whichever
/// screen the session needs first, and the requested location is lost in
/// the bounce. The code is held here instead, and the main screen collects
/// it once it mounts.
abstract class PendingShareCode {
  static String? _code;

  /// Remembers the code when [uri] is a share link, as the router sees it:
  /// `/s/CODE` for the web link and the app scheme alike.
  static void capture(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.length != 2 || segments.first != 's') return;
    final code = ShareCodeEntity.parse(segments.last);
    if (code != null) _code = code;
  }

  static String? take() {
    final code = _code;
    _code = null;
    return code;
  }
}
