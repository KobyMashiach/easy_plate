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
      _request('GET', path, null, queryParameters);

  Future<Response?> post(String path, {dynamic data}) => _request('POST', path, data, null);

  Future<Response?> _request(
    String method,
    String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
  ) async {
    try {
      // Per-request headers win over the ones fixed at construction.
      final dynamicHeaders = await headerProvider?.call();
      return await _dio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method, headers: dynamicHeaders),
      );
    } on DioException catch (e) {
      throw switch (e.type) {
        DioExceptionType.cancel => const AppException(AppErrorType.cancelled),
        DioExceptionType.connectionError ||
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout =>
          const AppException(AppErrorType.networkError),
        _ => AppException(
            switch (e.response?.statusCode) {
              401 || 403 => AppErrorType.unauthorized,
              429 || 500 || 502 || 503 || 504 || 529 => AppErrorType.overloaded,
              _ => AppErrorType.unknown,
            },
            message: e.response?.data?.toString() ?? e.message ?? '',
          ),
      };
    }
  }
}
