import 'package:easy_plate/features/user_profile/data/datasources/user_profile_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('createdAt is written once', () {
    test('a document that carries a date keeps it on every later save', () {
      expect(
        UserProfileFirestoreDataSource.keepsCreatedAt({
          'fullName': 'Dana',
          'createdAt': DateTime(2025, 3, 1),
        }),
        isTrue,
      );
    });

    test('a new account, or one from before the field, gets the entity\'s', () {
      expect(UserProfileFirestoreDataSource.keepsCreatedAt(null), isFalse);
      expect(
        UserProfileFirestoreDataSource.keepsCreatedAt({'fullName': 'Dana'}),
        isFalse,
      );
      expect(
        UserProfileFirestoreDataSource.keepsCreatedAt({'createdAt': null}),
        isFalse,
      );
    });
  });
}
