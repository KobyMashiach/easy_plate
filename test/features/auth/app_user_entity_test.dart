import 'package:easy_plate/features/auth/domain/entities/app_user_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a password account must confirm its address', () {
    const user = AppUserEntity(
      uid: 'u1',
      email: 'a@b.co.il',
      providerIds: ['password'],
    );
    expect(user.needsEmailVerification, isTrue);
  });

  test('a confirmed password account is done', () {
    const user = AppUserEntity(
      uid: 'u1',
      email: 'a@b.co.il',
      emailVerified: true,
      providerIds: ['password'],
    );
    expect(user.needsEmailVerification, isFalse);
  });

  test('Google arrives verified, so it is never held', () {
    // Firebase reports emailVerified for Google accounts, but the gate must not
    // depend on that — there is no password the user chose to prove.
    const user = AppUserEntity(
      uid: 'u1',
      email: 'a@gmail.com',
      providerIds: ['google.com'],
    );
    expect(user.needsEmailVerification, isFalse);
  });

  test('a phone-only account has no address to confirm', () {
    const user = AppUserEntity(uid: 'u1', phoneNumber: '+972508247743', providerIds: ['phone']);
    expect(user.needsEmailVerification, isFalse);
    expect(user.hasPhone, isTrue);
    expect(user.hasPassword, isFalse);
  });

  test('a linked account carries both identities', () {
    // The point of linking: signing in by phone reaches the account that was
    // created with an email.
    const user = AppUserEntity(
      uid: 'u1',
      email: 'a@b.co.il',
      phoneNumber: '+972508247743',
      emailVerified: true,
      providerIds: ['password', 'phone'],
    );
    expect(user.hasPassword, isTrue);
    expect(user.hasPhone, isTrue);
    expect(user.needsEmailVerification, isFalse);
  });

  group('needsPhoneVerification', () {
    test('a Google account without a number is held', () {
      const user = AppUserEntity(uid: 'u', providerIds: ['google.com']);
      expect(user.needsPhoneVerification, isTrue);
    });

    test('a password account without a number is held', () {
      const user = AppUserEntity(uid: 'u', providerIds: ['password']);
      expect(user.needsPhoneVerification, isTrue);
    });

    test('a phone account is through', () {
      const user = AppUserEntity(uid: 'u', providerIds: ['phone']);
      expect(user.needsPhoneVerification, isFalse);
    });

    test('a linked account keeps the number it proved', () {
      const user = AppUserEntity(uid: 'u', providerIds: ['google.com', 'phone']);
      expect(user.needsPhoneVerification, isFalse);
    });

    test('a phone number with no phone provider does not count', () {
      // Firebase only adds the provider once the SMS code was accepted, so the
      // provider list is the truth and a stray field is not.
      const user = AppUserEntity(
        uid: 'u',
        phoneNumber: '+972500000000',
        providerIds: ['google.com'],
      );
      expect(user.needsPhoneVerification, isTrue);
    });
  });

  group('hasApple', () {
    test('reads the apple.com provider', () {
      const user = AppUserEntity(uid: 'u', providerIds: ['phone', 'apple.com']);
      expect(user.hasApple, isTrue);
      expect(user.hasGoogle, isFalse);
    });

    test('an Apple account still has to prove a phone', () {
      const user = AppUserEntity(uid: 'u', providerIds: ['apple.com']);
      expect(user.hasApple, isTrue);
      expect(user.needsPhoneVerification, isTrue);
    });
  });
}
