import '../../../../core/utils/i18n/strings.g.dart';

/// The bloc carries the [AppErrorType] name across, so the screen can show a
/// translated message instead of a Firebase error code.
String authErrorMessage(String error) => switch (error) {
      'unauthorized' => t.auth.errorUnauthorized,
      'networkError' => t.auth.errorNetwork,
      _ => t.auth.errorUnknown,
    };
