// Firestore marks its types @sealed; mocking them is the only way to count
// reads without the emulator.
// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_plate/features/shared_recipes/data/datasources/shared_recipes_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

typedef _Json = Map<String, dynamic>;

class _Firestore extends Mock implements FirebaseFirestore {}

class _Collection extends Mock implements CollectionReference<_Json> {}

class _Query extends Mock implements Query<_Json> {}

class _QuerySnapshot extends Mock implements QuerySnapshot<_Json> {}

class _Post extends Mock implements QueryDocumentSnapshot<_Json> {}

class _PostRef extends Mock implements DocumentReference<_Json> {}

class _LikeRef extends Mock implements DocumentReference<_Json> {}

class _LikeSnapshot extends Mock implements DocumentSnapshot<_Json> {}

void main() {
  late _Firestore firestore;
  late _Collection root;
  late _Query query;
  late List<_Post> posts;

  /// Like-document reads, per post id.
  late Map<String, int> likeReads;

  _Post post(String id, {required bool liked}) {
    final doc = _Post();
    final ref = _PostRef();
    final likes = _Collection();
    final like = _LikeRef();
    final likeSnap = _LikeSnapshot();
    when(() => doc.id).thenReturn(id);
    when(() => doc.reference).thenReturn(ref);
    when(() => doc.data()).thenReturn({'authorUid': 'a', 'title': id});
    when(() => ref.collection('likes')).thenReturn(likes);
    when(() => likes.doc('me')).thenReturn(like);
    when(() => likeSnap.exists).thenReturn(liked);
    when(() => like.get()).thenAnswer((_) async {
      likeReads[id] = (likeReads[id] ?? 0) + 1;
      return likeSnap;
    });
    return doc;
  }

  setUp(() {
    firestore = _Firestore();
    root = _Collection();
    query = _Query();
    likeReads = {};
    posts = [post('p1', liked: true), post('p2', liked: false)];
    when(() => firestore.collection('shared_recipes')).thenReturn(root);
    when(
      () => root.orderBy('createdAt', descending: true),
    ).thenReturn(query);
    when(() => query.limit(any())).thenReturn(query);
    when(() => query.get()).thenAnswer((_) async {
      final snapshot = _QuerySnapshot();
      when(() => snapshot.docs).thenReturn(posts);
      return snapshot;
    });
  });

  test('a reload reads likes only for posts not seen before', () async {
    final source = SharedRecipesFirestoreDataSource(firestore: firestore);

    final first = await source.getFeed(viewerUid: 'me');
    expect(first.map((r) => r.likedByMe), [true, false]);
    expect(likeReads, {'p1': 1, 'p2': 1});

    posts = [post('p3', liked: true), ...posts];
    final second = await source.getFeed(viewerUid: 'me');

    expect(second.map((r) => r.likedByMe), [true, true, false]);
    expect(likeReads, {'p1': 1, 'p2': 1, 'p3': 1});
  });

  test('another viewer on the same device reads their own likes', () async {
    final source = SharedRecipesFirestoreDataSource(firestore: firestore);
    await source.getFeed(viewerUid: 'me');

    // A different uid is a different key: nothing carried over.
    for (final doc in posts) {
      final likes = doc.reference.collection('likes');
      final like = _LikeRef();
      final snap = _LikeSnapshot();
      when(() => likes.doc('other')).thenReturn(like);
      when(() => snap.exists).thenReturn(false);
      when(() => like.get()).thenAnswer((_) async => snap);
    }
    final asOther = await source.getFeed(viewerUid: 'other');
    expect(asOther.map((r) => r.likedByMe), [false, false]);
  });
}
