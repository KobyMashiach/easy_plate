enum AppErrorType {
  cancelled,
  networkError,
  notFound,
  unauthorized,
  parsingFailed,
  /// Upstream is up but refused this call for now — rate limit or capacity.
  /// Retrying the identical request later is expected to succeed.
  overloaded,
  unknown,
}

class AppException implements Exception {
  final AppErrorType type;
  final String message;

  const AppException(this.type, {this.message = ''});

  @override
  String toString() => 'AppException($type): $message';
}
