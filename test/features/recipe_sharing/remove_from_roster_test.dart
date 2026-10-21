// Firestore types are mocked here, as in the other Firestore tests.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_plate/features/recipe_sharing/data/datasources/recipe_sharing_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Firestore extends Mock implements FirebaseFirestore {}

class _Doc extends Mock implements DocumentReference<Map<String, dynamic>> {}

class _Snap extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}

class _Batch extends Mock implements WriteBatch {}

void main() {
  late _Firestore firestore;
  late _Doc doc;
  late _Doc invite;
  late _Batch batch;

  setUp(() {
    firestore = _Firestore();
    doc = _Doc();
    invite = _Doc();
    batch = _Batch();
    when(() => firestore.batch()).thenReturn(batch);
    when(() => batch.commit()).thenAnswer((_) async {});
    when(() => doc.update(any())).thenAnswer((_) async {});
    when(() => invite.delete()).thenAnswer((_) async {});
  });

  void inviteExists(bool exists) {
    final snap = _Snap();
    when(() => snap.exists).thenReturn(exists);
    when(() => invite.get()).thenAnswer((_) async => snap);
  }

  test('a member leaving only changes the roster', () async {
    await removeFromRoster(firestore, doc, invite, 'm', revokeInvite: false);
    verify(() => doc.update(any())).called(1);
    verifyNever(() => invite.get());
    verifyNever(() => firestore.batch());
  });

  test(
    'the owner removing someone deletes the invite in the same batch',
    () async {
      inviteExists(true);
      await removeFromRoster(firestore, doc, invite, 'm', revokeInvite: true);
      verify(() => batch.update<Map<String, dynamic>>(doc, any())).called(1);
      verify(() => batch.delete(invite)).called(1);
      verify(() => batch.commit()).called(1);
      verifyNever(() => doc.update(any()));
    },
  );

  test('no invite stored: the roster change goes alone, not refused', () async {
    inviteExists(false);
    await removeFromRoster(firestore, doc, invite, 'm', revokeInvite: true);
    verify(() => doc.update(any())).called(1);
    verifyNever(() => firestore.batch());
  });

  test(
    'an unreadable invite (offline): roster first, then the delete',
    () async {
      when(() => invite.get()).thenThrow(StateError('unavailable'));
      await removeFromRoster(firestore, doc, invite, 'm', revokeInvite: true);
      verify(() => doc.update(any())).called(1);
      verify(() => invite.delete()).called(1);
    },
  );
}
