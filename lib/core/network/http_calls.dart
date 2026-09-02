import 'package:dio/dio.dart';

import '../errors/app_exception.dart';

class HttpCalls {
  final Dio _dio;

  HttpCalls({String? baseUrl, Map<String, String>? headers})
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
      return await _dio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method),
      );
    } on DioException catch (e) {
      throw switch (e.type) {
        DioExceptionType.cancel => const AppException(AppErrorType.cancelled),
        DioExceptionType.connectionError ||
        DioExceptionType.connectionTimeout ||
        DioExceptionType.receiveTimeout =>
          const AppException(AppErrorType.networkError),
        _ => AppException(
            e.response?.statusCode == 401 ? AppErrorType.unauthorized : AppErrorType.unknown,
            message: e.response?.data?.toString() ?? e.message ?? '',
          ),
      };
    }
  }
}
