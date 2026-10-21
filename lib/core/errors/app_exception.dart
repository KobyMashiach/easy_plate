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

  /// The source itself could not be read — a private account, a platform
  /// that blocked the fetch, a video with no recipe in it. Retrying will not
  /// help; a different link or pasted text will.
  unreadableSource,

  /// A paid endpoint (AI, speech, search, translation) refused the account
  /// because its ID token carries no verified phone (403 `phone_required`).
  /// Not retryable as is: the phone has to be verified first, and HttpCalls
  /// already tried once with a refreshed token.
  phoneRequired,

  /// A paid endpoint (or priceStats / shareCodes) refused the account
  /// because the administrator switched it off: 403 `account_disabled`,
  /// from the `disabled` custom claim. Not retryable; the gate holds the
  /// account on the blocked screen (see `HttpCalls.onAccountDisabled`).
  accountDisabled,
  unknown,
}

class AppException implements Exception {
  final AppErrorType type;
  final String message;

  /// The response body the server refused with, when there was one — for
  /// the callers that read more than the type out of it (the `quota`
  /// object's `requested` and what is left of the day).
  final Object? data;

  const AppException(this.type, {this.message = '', this.data});

  @override
  String toString() => 'AppException($type): $message';
}
