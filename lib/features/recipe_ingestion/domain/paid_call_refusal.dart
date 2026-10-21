import '../../../core/errors/app_exception.dart';

/// Whether a paid endpoint (AI, speech, search, translation, prices) refused
/// the call because the console blocked the account: 403
/// `{error: {code: 'account_disabled'}}` (functions/aiProxy.js
/// paidCallerRefusal, pass 9), which HttpCalls files under
/// [AppErrorType.accountDisabled].
///
/// The body is still read as a fallback: an exception built elsewhere
/// (a datasource mapping its own Dio error) may carry the refusal under the
/// generic `unauthorized` type, the one a missing key gets.
bool isAccountDisabled(Object? error) {
  if (error is! AppException) return false;
  if (error.type == AppErrorType.accountDisabled) return true;
  if (error.type != AppErrorType.unauthorized) return false;
  final body = error.data;
  final detail = body is Map ? body['error'] : null;
  return detail is Map &&
      (detail['code'] == 'account_disabled' ||
          detail['status'] == 'ACCOUNT_DISABLED');
}

/// A refusal that stands until something outside the app changes — the
/// day's allowance, a verified phone, an unblocked account. Running the
/// same request again only hits the same wall, so a Retry is not offered.
bool isStandingRefusal(Object? error) =>
    isAccountDisabled(error) ||
    error is AppException &&
        (error.type == AppErrorType.quotaExceeded ||
            error.type == AppErrorType.phoneRequired);
