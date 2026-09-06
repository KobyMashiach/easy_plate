import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Whether to offer Sign in with Apple at all.
///
/// Apple's guideline 4.8 only binds iOS: an app that offers a third-party
/// sign-in there must also offer a privacy-focused equivalent. On Android the
/// button would be a browser round trip to solve a problem that does not exist,
/// so it is simply absent.
///
/// [defaultTargetPlatform] rather than `Platform.isIOS` so a widget test can
/// exercise both sides without a real device — but [Platform] is consulted too,
/// because a desktop build reporting iOS would still have no ASAuthorization.
bool get appleSignInAvailable {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.iOS && Platform.isIOS;
}
