import 'package:dio/dio.dart';

import '../errors/app_exception.dart';

class HttpCalls {
  final Dio _dio;

  /// Resolved before every request, for headers that cannot be fixed at
  /// construction. A Firebase ID token expires after an hour, so a header built
  /// once would start failing mid-session.
  final Future<Map<String, String>> Function()? headerProvider;

  HttpCalls({
    String? baseUrl,
    Map<String, String>? headers,
    this.headerProvider,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: baseUrl ?? '',
           connectTimeout: const Duration(seconds: 15),
           receiveTimeout: const Duration(seconds: 120),
           headers: {'Content-Type': 'application/json', ...?headers},
         ),
       );

  Future<Response?> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _request('GET', path, null, queryParameters, null);

  /// [headers] are for this one call, on top of the fixed and provided ones.
  /// [receiveTimeout] replaces the two-minute default for this one call, for
  /// a request the server is known to take longer over (an account deletion
  /// walks every collection the account owns).
  Future<Response?> post(
    String path, {
    dynamic data,
    Map<String, String>? headers,
    Duration? receiveTimeout,
  }) => _request('POST', path, data, null, headers, receiveTimeout);

  Future<Response?> _request(
    String method,
    String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers, [
    Duration? receiveTimeout,
  ]) async {
    for (var attempt = 0; ; attempt++) {
      try {
        // Per-request headers win over the ones fixed at construction.
        final dynamicHeaders = await headerProvider?.call();
        return await _dio.request(
          path,
          data: data,
          queryParameters: queryParameters,
          options: Options(
            method: method,
            headers: {...?dynamicHeaders, ...?headers},
            receiveTimeout: receiveTimeout,
          ),
        );
      } on DioException catch (e) {
        // A phone linked a moment ago (or on the website) is in the account
        // but not yet in the cached ID token, and the paid endpoints read it
        // from the token. One refresh and one retry, never more: a token that
        // still carries no phone is a real refusal.
        final refresh = refreshIdentity;
        if (attempt == 0 &&
            headerProvider != null &&
            refresh != null &&
            !isAccountDisabled(e.response?.statusCode, e.response?.data) &&
            isPhoneRequired(e.response?.statusCode, e.response?.data) &&
            await refresh()) {
          continue;
        }
        final mapped = _mapped(e);
        // Switched off from the console while signed in: the gate is told
        // at once, instead of at the next sign-in.
        if (mapped.type == AppErrorType.accountDisabled) {
          onAccountDisabled?.call();
        }
        throw mapped;
      }
    }
  }

  static AppException _mapped(DioException e) {
    return switch (e.type) {
      DioExceptionType.cancel => const AppException(AppErrorType.cancelled),
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout => const AppException(
        AppErrorType.networkError,
      ),
      _ => AppException(
        errorTypeFor(e.response?.statusCode, e.response?.data),
        message: e.response?.data?.toString() ?? e.message ?? '',
        data: e.response?.data,
      ),
    };
  }

  /// Called when a paid endpoint answers 403 `phone_required`: refreshes the
  /// caller's ID token when the account does hold a verified phone, and says
  /// whether a retry can now succeed. Set once at startup (main.dart); null
  /// in tests and before Firebase is up, which means no retry.
  static Future<bool> Function()? refreshIdentity;

  /// Called when any endpoint answers 403 `account_disabled`: the
  /// administrator switched the account off mid-session. The one-shot
  /// `account_status` read happens at sign-in only, so without this the
  /// account would keep its screens (every paid call refused) until it
  /// next signed in. Set once at startup (main.dart); null in tests.
  static void Function()? onAccountDisabled;

  /// `{error: {code: 'account_disabled'}}` (aiProxy, speak, translate,
  /// image search, priceStats, shareCodes) or `{error: {status:
  /// 'ACCOUNT_DISABLED'}}` (socialRecipe). Checked before the phone shape,
  /// so a disabled account is never sent to phone verification.
  static bool isAccountDisabled(int? statusCode, dynamic body) {
    if (statusCode != 403) return false;
    final error = body is Map ? body['error'] : null;
    if (error is! Map) return false;
    return error['code'] == 'account_disabled' ||
        error['status'] == 'ACCOUNT_DISABLED';
  }

  /// The paid endpoints' refusal for an account without a verified phone:
  /// `{error: {code: 'phone_required'}}` (aiProxy, speak, translate, image
  /// search) or `{error: {status: 'PHONE_REQUIRED'}}` (socialRecipe).
  static bool isPhoneRequired(int? statusCode, dynamic body) {
    if (statusCode != 403) return false;
    final error = body is Map ? body['error'] : null;
    if (error is! Map) return false;
    return error['code'] == 'phone_required' ||
        error['status'] == 'PHONE_REQUIRED';
  }

  /// The status-to-error mapping, as a pure function so both 429 branches can
  /// be pinned by a test.
  ///
  /// A spent daily allowance and upstream capacity both arrive as 429, and
  /// callers retry capacity errors — so telling them apart is what keeps the
  /// app from sitting through a backoff for a refusal that will stand until the
  /// quota resets. Our AI proxy is the only thing that sends the `quota`
  /// object, which is what makes them distinguishable at all.
  static AppErrorType errorTypeFor(int? statusCode, dynamic body) {
    return switch (statusCode) {
      403 when isAccountDisabled(statusCode, body) =>
        AppErrorType.accountDisabled,
      403 when isPhoneRequired(statusCode, body) => AppErrorType.phoneRequired,
      401 || 403 => AppErrorType.unauthorized,
      429 when _carriesQuota(body) => AppErrorType.quotaExceeded,
      429 || 500 || 502 || 503 || 504 || 529 => AppErrorType.overloaded,
      _ => AppErrorType.unknown,
    };
  }

  static bool _carriesQuota(dynamic body) {
    final error = body is Map ? body['error'] : null;
    return error is Map && error['quota'] != null;
  }

  /// The `quota` object of a daily-allowance refusal: what was used, the
  /// day's limit, and — when the request alone was larger than what is left
  /// (functions/dailyBudget.js) — how much it asked for. Null for any other
  /// body. A smaller request may still fit when [requested] is set.
  static ({int used, int limit, int? requested})? quotaOf(Object? body) {
    final error = body is Map ? body['error'] : null;
    final quota = error is Map ? error['quota'] : null;
    if (quota is! Map) return null;
    final used = quota['used'];
    final limit = quota['limit'];
    final requested = quota['requested'];
    if (used is! num || limit is! num) return null;
    return (
      used: used.toInt(),
      limit: limit.toInt(),
      requested: requested is num ? requested.toInt() : null,
    );
  }
}
