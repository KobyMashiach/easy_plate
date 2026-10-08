import '../../../../core/constants/api_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/ai_auth_header.dart';
import '../../../../core/network/http_calls.dart';
import '../../domain/entities/billing_entities.dart';

/// The account actions the app cannot take on its own: they go through the
/// `adminUsers` Cloud Function, which holds the Admin SDK and checks that
/// the caller is the administrator.
abstract class AdminUsersRemoteDataSource {
  Future<void> disable(String uid, String message);

  /// Frees the account's device session and signs that device out.
  Future<void> releaseSession(String uid);
  Future<void> enable(String uid);
  Future<void> delete(String uid);
  Future<void> notify(
    String uid, {
    required String title,
    required String body,
  });
  Future<BroadcastResult> notifyAll({
    required String title,
    required String body,
  });
}

class AdminUsersHttpDataSource implements AdminUsersRemoteDataSource {
  final HttpCalls _calls;

  AdminUsersHttpDataSource({HttpCalls? calls})
    : _calls =
          calls ??
          HttpCalls(
            baseUrl: ApiConfig.adminUsersUrl,
            headerProvider: aiProxyAuthHeader,
          );

  Future<Map<String, dynamic>> _post(Map<String, dynamic> body) async {
    if (!ApiConfig.usesProxy) {
      throw const AppException(
        AppErrorType.unauthorized,
        message:
            'Account actions need the Cloud Functions deploy (AI_BASE_URL)',
      );
    }
    final response = await _calls.post('', data: body);
    final data = response?.data;
    return data is Map<String, dynamic> ? data : const {};
  }

  @override
  Future<void> disable(String uid, String message) =>
      _post({'action': 'disable', 'uid': uid, 'message': message});

  @override
  Future<void> releaseSession(String uid) =>
      _post({'action': 'releaseSession', 'uid': uid});

  @override
  Future<void> enable(String uid) => _post({'action': 'enable', 'uid': uid});

  @override
  Future<void> delete(String uid) => _post({'action': 'delete', 'uid': uid});

  @override
  Future<void> notify(
    String uid, {
    required String title,
    required String body,
  }) => _post({'action': 'notify', 'uid': uid, 'title': title, 'body': body});

  @override
  Future<BroadcastResult> notifyAll({
    required String title,
    required String body,
  }) async {
    final data = await _post({
      'action': 'notifyAll',
      'title': title,
      'body': body,
    });
    return BroadcastResult(
      items: (data['items'] as num?)?.toInt() ?? 0,
      sent: (data['sent'] as num?)?.toInt() ?? 0,
      failed: (data['failed'] as num?)?.toInt() ?? 0,
    );
  }
}
