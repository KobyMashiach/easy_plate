/// When a code or a mail last went out, kept for the process so a screen
/// opened (or reopened) right after cannot send another at once. Firebase
/// throttles an address or a number hit repeatedly, and each extra send is
/// a duplicate in the user's inbox or an SMS we pay for.
class SendLog {
  SendLog._();

  static final _verificationMail = <String, DateTime>{};
  static final _sms = <String, DateTime>{};

  /// Test seam for the clock.
  static DateTime Function() now = DateTime.now;

  static void verificationMailSent(String uid) =>
      _verificationMail[uid] = now();

  static void smsSent(String phoneNumber) => _sms[phoneNumber] = now();

  /// Seconds left of [wait] since the last verification mail to [uid];
  /// zero when none is recent.
  static int mailWaitLeft(String? uid, int wait) =>
      _left(uid == null ? null : _verificationMail[uid], wait);

  /// Seconds left of [wait] since the last code texted to [phoneNumber].
  static int smsWaitLeft(String phoneNumber, int wait) =>
      _left(_sms[phoneNumber], wait);

  static int _left(DateTime? at, int wait) {
    if (at == null) return 0;
    final left = wait - now().difference(at).inSeconds;
    return left.clamp(0, wait);
  }

  static void resetForTest() {
    _verificationMail.clear();
    _sms.clear();
    now = DateTime.now;
  }
}

/// Seconds between two codes to the same number, on every screen that sends
/// one.
const smsResendWaitSeconds = 30;
