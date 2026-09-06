import 'package:easy_plate/features/auth/data/datasources/firebase_auth_datasource.dart';
import 'package:easy_plate/features/auth/domain/entities/app_user_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an empty identity string reads as absent', () {
    // Seen on a phone-only account: Firebase reported email as "" rather than
    // null, so the profile screen showed neither an address nor the button
    // to add one — every `== null` check saw an email that was not there.
    expect(FirebaseAuthDataSource.blankToNull(''), isNull);
    expect(FirebaseAuthDataSource.blankToNull('   '), isNull);
    expect(FirebaseAuthDataSource.blankToNull(null), isNull);
  });

  test('a real value passes through untouched', () {
    expect(FirebaseAuthDataSource.blankToNull('a@b.co.il'), 'a@b.co.il');
    expect(FirebaseAuthDataSource.blankToNull('+972508247743'), '+972508247743');
  });

  test('a Google-linked account reports it', () {
    const linked = AppUserEntity(uid: 'u1', providerIds: ['phone', 'google.com']);
    const notLinked = AppUserEntity(uid: 'u1', providerIds: ['phone']);
    expect(linked.hasGoogle, isTrue);
    expect(notLinked.hasGoogle, isFalse);
  });
}
