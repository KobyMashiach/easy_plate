import 'package:easy_plate/features/auth/domain/phone_number.dart';
import 'package:easy_plate/features/auth/domain/send_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalisePhone', () {
    test('E.164 passes in any language', () {
      for (final local in [true, false]) {
        expect(
          normalisePhone('+33 6 12-34-56-78', israeliLocal: local).e164,
          '+33612345678',
        );
      }
    });

    test('a local 0… becomes +972 only in Hebrew', () {
      expect(
        normalisePhone('050-123-4567', israeliLocal: true).e164,
        '+972501234567',
      );
      expect(
        normalisePhone('972501234567', israeliLocal: true).e164,
        '+972501234567',
      );
      final french = normalisePhone('06 12 34 56 78', israeliLocal: false);
      expect(french.e164, isNull);
      expect(french.rejection, PhoneRejection.needsCountryCode);
    });

    test('garbage and short numbers are invalid', () {
      expect(
        normalisePhone('call me', israeliLocal: true).rejection,
        PhoneRejection.invalid,
      );
      expect(
        normalisePhone('+12', israeliLocal: false).rejection,
        PhoneRejection.invalid,
      );
      expect(
        normalisePhone('', israeliLocal: true).rejection,
        PhoneRejection.invalid,
      );
    });
  });

  group('SendLog', () {
    tearDown(SendLog.resetForTest);

    test('counts down from the last send, per number and per account', () {
      var now = DateTime(2026, 10, 18, 12);
      SendLog.now = () => now;
      expect(SendLog.smsWaitLeft('+972501234567', 30), 0);
      SendLog.smsSent('+972501234567');
      now = now.add(const Duration(seconds: 10));
      expect(SendLog.smsWaitLeft('+972501234567', 30), 20);
      expect(SendLog.smsWaitLeft('+33612345678', 30), 0);
      now = now.add(const Duration(seconds: 25));
      expect(SendLog.smsWaitLeft('+972501234567', 30), 0);

      SendLog.verificationMailSent('u1');
      expect(SendLog.mailWaitLeft('u1', 30), 30);
      expect(SendLog.mailWaitLeft('u2', 30), 0);
      expect(SendLog.mailWaitLeft(null, 30), 0);
    });
  });
}
