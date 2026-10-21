import 'package:easy_plate/features/user_profile/data/datasources/user_profile_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<String> contacts({
    String? authUid = 'u1',
    String? email = 'Dana@Example.com',
    bool verified = true,
    String? phone = '+972501234567',
  }) => UserProfileFirestoreDataSource.directoryContacts(
    'u1',
    authUid: authUid,
    authEmail: email,
    emailVerified: verified,
    authPhone: phone,
  );

  group('directoryContacts mirrors the user_directory rule', () {
    test('the token phone and the lower-cased verified email', () {
      expect(contacts(), ['dana@example.com', '+972501234567']);
    });

    test('an unverified email is left out, the phone still goes', () {
      expect(contacts(verified: false), ['+972501234567']);
    });

    test('nothing for a profile that is not the signed-in account', () {
      expect(contacts(authUid: 'someone-else'), isEmpty);
      expect(contacts(authUid: null), isEmpty);
    });

    test('a phone-only account claims just its number', () {
      expect(contacts(email: null), ['+972501234567']);
    });
  });
}
