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
}
