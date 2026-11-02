import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../domain/sms_auto_code.dart';

/// For a screen with an SMS code field: a code Android read on its own is
/// written into the field and confirmed, once the screen is waiting for one.
mixin SmsAutoFill<T extends StatefulWidget> on State<T> {
  StreamSubscription<String>? _smsCodes;

  /// [ready] says whether the screen is at its code step right now (a
  /// screen that asks for the number first is not).
  void listenForSmsCode(
    TextEditingController field,
    VoidCallback confirm, {
    bool Function()? ready,
  }) {
    _smsCodes?.cancel();
    _smsCodes = SmsAutoCode.codes.listen((code) {
      if (!mounted || !(ready?.call() ?? true)) return;
      if (field.text == code) return;
      field.text = code;
      confirm();
    });
  }

  @override
  void dispose() {
    _smsCodes?.cancel();
    super.dispose();
  }
}
