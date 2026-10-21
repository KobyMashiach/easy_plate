// Firestore types are mocked here, as in the other Firestore tests.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_plate/features/user_profile/data/datasources/user_profile_remote_datasource.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Firestore extends Mock implements FirebaseFirestore {}

class _Storage extends Mock implements FirebaseStorage {}

class _Collection extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class _Query extends Mock implements Query<Map<String, dynamic>> {}

class _Snapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}

void main() {
  test('each id chunk is a bounded query of at most 30', () async {
    final firestore = _Firestore();
    final collection = _Collection();
    final filtered = _Query();
    final limited = _Query();
    final snapshot = _Snapshot();
    final chunks = <List<Object?>>[];
    when(() => firestore.collection('public_profiles')).thenReturn(collection);
    when(
      () => collection.where(
        FieldPath.documentId,
        whereIn: any(named: 'whereIn'),
      ),
    ).thenAnswer((invocation) {
      chunks.add(
        (invocation.namedArguments[#whereIn] as Iterable<Object?>).toList(),
      );
      return filtered;
    });
    when(() => filtered.limit(any())).thenReturn(limited);
    when(() => limited.get()).thenAnswer((_) async => snapshot);
    when(() => snapshot.docs).thenReturn(const []);

    await UserProfileFirestoreDataSource(
      firestore: firestore,
      storage: _Storage(),
    ).getPublicProfiles({for (var i = 0; i < 45; i++) 'u$i'});

    expect(chunks.map((c) => c.length), [30, 15]);
    verify(() => filtered.limit(30)).called(2);
    verifyNever(() => filtered.get());
  });
}
