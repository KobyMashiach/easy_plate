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
      await _calls.post(ApiConfig.deleteAccountUrl, data: {'confirm': true});
    } on AppException catch (e) {
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
}
