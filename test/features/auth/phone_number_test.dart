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

  group('phone field', () {
    const il = PhoneCountry.israel;

    test('every way of writing an Israeli mobile reaches the same number', () {
      for (final typed in [
        '0508247743',
        '050-824-7743',
        '050-8247743',
        '508247743',
        '050 824 7743',
        '+972 50-824-7743',
        '972508247743',
        '00972508247743',
      ]) {
        final (:digits, :country) = phoneFieldDigits(typed, il);
        expect(country, il, reason: typed);
        expect(composePhone(digits, il).e164, '+972508247743', reason: typed);
      }
    });

    test('the field keeps digits only, at most ten', () {
      expect(phoneFieldDigits('050-82a4.7(7)43', il).digits, '0508247743');
      expect(phoneFieldDigits('050824774399', il).digits, '0508247743');
      expect(phoneFieldDigits('-', il).digits, '');
    });

    test('a pasted international number moves the menu to its country', () {
      final pasted = phoneFieldDigits('+33 6 12 34 56 78', il);
      expect(pasted.country.iso, 'FR');
      expect(pasted.digits, '612345678');
      expect(composePhone(pasted.digits, pasted.country).e164, '+33612345678');
      expect(phoneFieldDigits('+1 201 555 0123', il).country.iso, 'US');
    });

    test('too short or empty is refused', () {
      expect(composePhone('', il).rejection, PhoneRejection.invalid);
      expect(composePhone('05082', il).rejection, PhoneRejection.invalid);
      // An 8-digit landline after the 0 is fine.
      expect(composePhone('036123456', il).e164, '+97236123456');
    });

    test('every listed country has a flag and an example that composes', () {
      for (final c in PhoneCountry.all) {
        expect(c.flag.runes.length, 2, reason: c.iso);
        expect(c.example.length, lessThanOrEqualTo(c.maxDigits));
        expect(composePhone(c.example, c).e164, isNotNull, reason: c.iso);
      }
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
