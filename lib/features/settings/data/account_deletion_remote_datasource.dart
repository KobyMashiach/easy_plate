import '../../../core/constants/api_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/ai_auth_header.dart';
import '../../../core/network/http_calls.dart';

/// Why the server would not delete the account: the one case it refuses.
class AccountDeletionRefused implements Exception {
  /// `household_owner`: the account owns a shared household that has to be
  /// closed first, from the household screen.
  final String code;
  const AccountDeletionRefused(this.code);
}

/// The server wants a recent sign-in before it deletes the account
/// (`recent_login_required`, on while Remote Config's
/// `delete_account_recent_auth_minutes` is above 0): the phone is verified
/// again by SMS and the call retried once.
class AccountDeletionNeedsRecentLogin implements Exception {
  const AccountDeletionNeedsRecentLogin();
}

/// The account deleting itself through the `deleteAccount` function, which
/// holds the Admin SDK: the Auth user, the profile and its mirrored boxes,
/// photos, shared documents, codes, invites and community posts all go.
class AccountDeletionRemoteDataSource {
  final HttpCalls _calls;

  AccountDeletionRemoteDataSource({HttpCalls? calls})
    : _calls = calls ?? HttpCalls(headerProvider: aiProxyAuthHeader);

  Future<void> deleteMyAccount() async {
    if (!ApiConfig.usesProxy) {
      throw const AppException(
        AppErrorType.unauthorized,
        message: 'Account deletion needs the Cloud Functions deploy',
      );
    }
    try {
      // The function may run for up to 300 s (it walks every mirrored box,
      // photo and post); with the two-minute default a long deletion read
      // here as a network error although it finished on the server.
      await _calls.post(
        ApiConfig.deleteAccountUrl,
        data: {'confirm': true},
        receiveTimeout: const Duration(seconds: 300),
      );
    } on AppException catch (e) {
      if (needsRecentLogin(e.message)) {
        throw const AccountDeletionNeedsRecentLogin();
      }
      final code = refusalIn(e.message);
      if (code != null) throw AccountDeletionRefused(code);
      rethrow;
    }
  }

  /// The server's refusal code inside an error body, as ShareCodes reads it.
  static String? refusalIn(String message) {
    final match = RegExp(r'code[":\s]+([a-z_]+)').firstMatch(message);
    final code = match?.group(1);
    return code == 'household_owner' ? code : null;
  }

  /// Whether an error body is the server asking for a recent sign-in.
  static bool needsRecentLogin(String message) =>
      RegExp(r'code[":\s]+recent_login_required').hasMatch(message);
}
