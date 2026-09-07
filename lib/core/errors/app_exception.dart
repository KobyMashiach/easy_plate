enum AppErrorType {
  cancelled,
  networkError,
  notFound,
  unauthorized,
  parsingFailed,
  /// Upstream is up but refused this call for now — rate limit or capacity.
  /// Retrying the identical request later is expected to succeed.
  overloaded,
  /// The account's allowance for the day is spent. Distinct from [overloaded]
  /// because retrying cannot help: the refusal stands until the quota resets,
  /// so a backoff only makes the user wait longer for the same answer.
  quotaExceeded,
  unknown,
}

class AppException implements Exception {
  final AppErrorType type;
  final String message;

  const AppException(this.type, {this.message = ''});

  @override
  String toString() => 'AppException($type): $message';
}
