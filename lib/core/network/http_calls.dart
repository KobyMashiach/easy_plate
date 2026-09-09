import 'package:dio/dio.dart';

import '../errors/app_exception.dart';

class HttpCalls {
  final Dio _dio;

  /// Resolved before every request, for headers that cannot be fixed at
  /// construction. A Firebase ID token expires after an hour, so a header built
  /// once would start failing mid-session.
  final Future<Map<String, String>> Function()? headerProvider;

  HttpCalls({String? baseUrl, Map<String, String>? headers, this.headerProvider})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? '',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 120),
          headers: {'Content-Type': 'application/json', ...?headers},
        ));

  Future<Response?> get(String path, {Map<String, dynamic>? queryParameters}) =>
      _request('GET', path, null, queryParameters, null);

  /// [headers] are for this one call, on top of the fixed and provided ones.
  Future<Response?> post(String path, {dynamic data, Map<String, String>? headers}) =>
      _request('POST', path, data, null, headers);

  Future<Response?> _request(
    String method,
    String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  ) async {
    try {
      // Per-request headers win over the ones fixed at construction.
      final dynamicHeaders = await headerProvider?.call();
      return await _dio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method, headers: {...?dynamicHeaders, ...?headers}),
      );
    } on DioException catch (e) {
      throw switch (e.type) {
        DioExceptionType.cancel => const AppException(AppErrorType.cancelled),
        DioExceptionType.connectionError ||
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout =>
          const AppException(AppErrorType.networkError),
        _ => AppException(
            errorTypeFor(e.response?.statusCode, e.response?.data),
            message: e.response?.data?.toString() ?? e.message ?? '',
          ),
      };
    }
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
}
