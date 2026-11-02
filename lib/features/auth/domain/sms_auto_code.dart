import 'dart:async';

/// The SMS code Android read by itself (the SMS Retriever behind
/// `verifyPhoneNumber`, which the hash at the end of the message is for),
/// after the code screen was already open. The screens that ask for a code
/// fill it in and confirm it, so the user types nothing.
abstract final class SmsAutoCode {
  static final _codes = StreamController<String>.broadcast();

  static Stream<String> get codes => _codes.stream;

  static void publish(String? code) {
    if (code != null && code.isNotEmpty) _codes.add(code);
  }
}
