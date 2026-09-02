enum AppErrorType { cancelled, networkError, notFound, unauthorized, parsingFailed, unknown }

class AppException implements Exception {
  final AppErrorType type;
  final String message;

  const AppException(this.type, {this.message = ''});

  @override
  String toString() => 'AppException($type): $message';
}
