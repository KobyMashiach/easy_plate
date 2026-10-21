import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../community/data/doc_fields.dart';
import '../../domain/entities/forum_post_entity.dart';
import '../../domain/entities/forum_reply_entity.dart';

abstract class ForumRemoteDataSource {
  Future<List<ForumPostEntity>> getPosts({
    required String viewerUid,
    int limit = 50,
  });
  Stream<List<ForumPostEntity>> watchPosts({
    required String viewerUid,
    int limit = 50,
  });
  Future<ForumPostEntity?> getPost(String postId, {required String viewerUid});
  Future<void> createPost({
    required String title,
    required String body,
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
  });
  Future<List<ForumReplyEntity>> getReplies(
    String postId, {
    required String viewerUid,
  });
  Stream<List<ForumReplyEntity>> watchReplies(
    String postId, {
    required String viewerUid,
  });
  Future<ForumReplyEntity?> getReply(
    String postId,
    String replyId, {
    required String viewerUid,
  });
  Future<String> addReply({
    required String postId,
    required String body,
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
    String? sharedRecipeId,
    String? sharedRecipeTitle,
  });
  Future<bool> togglePostLike(String postId, {required String viewerUid});
  Future<bool> toggleReplyLike(
    String postId,
    String replyId, {
    required String viewerUid,
  });
  Future<void> deletePost(String postId);
}

class ForumFirestoreDataSource implements ForumRemoteDataSource {
  static const collection = 'forum_posts';
  static const _replies = 'replies';
  static const _likes = 'likes';
  static const _uuid = Uuid();

  /// A batch takes 500 writes; a little under, per commit.
  static const _batchLimit = 450;

  final FirebaseFirestore _firestore;

  /// Whether the viewer has liked a given thread or reply, keyed by the like
  /// document's path (which includes the viewer's uid, so two accounts on
  /// one device never read each other's hearts).
  ///
  /// The live streams re-emit the whole window on every change, and a like
  /// lookup per row on every emission would cost fifty reads each time
  /// someone, anywhere, replied. Only rows not yet seen are looked up; a
  /// like the viewer gives through [_toggleLike] updates the entry directly,
  /// and a one-shot read ([getPosts], [getReplies]) refreshes it.
  final _viewerLikes = <String, bool>{};

  ForumFirestoreDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _root =>
      _firestore.collection(collection);

  Query<Map<String, dynamic>> _postsQuery(int limit) =>
      _root.orderBy('createdAt', descending: true).limit(limit);

  /// A thread shows its newest [_repliesLimit] replies, oldest first. The
  /// query runs newest-first so the limit cuts the old end, not the new
  /// one; [_repliesOf] turns the page back round.
  static const _repliesLimit = 200;

  Query<Map<String, dynamic>> _repliesQuery(String postId) => _root
      .doc(postId)
      .collection(_replies)
      .orderBy('createdAt', descending: true)
      .limit(_repliesLimit);

  String _likeKey(DocumentReference<Map<String, dynamic>> target, String uid) =>
      '${target.path}/$_likes/$uid';

  /// One like lookup per row the cache has not seen, rather than a read of
  /// every like: the list only needs to know about this viewer.
  Future<List<bool>> _likedByViewer(
    List<DocumentSnapshot<Map<String, dynamic>>> docs,
    String viewerUid, {
    required bool refresh,
  }) async {
    final results = List<bool>.filled(docs.length, false);
    final lookups = <Future<void>>[];
    for (var i = 0; i < docs.length; i++) {
      final key = _likeKey(docs[i].reference, viewerUid);
      final cached = _viewerLikes[key];
      if (cached != null && !refresh) {
        results[i] = cached;
        continue;
      }
      // A document the local SDK holds ahead of the server is the viewer's
      // own fresh write; nobody can have liked it yet, and looking it up
      // offline would throw.
      if (docs[i].metadata.hasPendingWrites) {
        results[i] = false;
        continue;
      }
      lookups.add(
        docs[i].reference
            .collection(_likes)
            .doc(viewerUid)
            .get()
            .then((like) {
              _viewerLikes[key] = like.exists;
              results[i] = like.exists;
            })
            // Offline with no cached like: shown as not liked, and not
            // cached, so the next emission with a connection re-reads it.
            .catchError((Object _) {}),
      );
    }
    await Future.wait(lookups);
    return results;
  }

  Future<List<ForumPostEntity>> _posts(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    String viewerUid, {
    required bool refresh,
  }) async {
    final liked = await _likedByViewer(
      snapshot.docs,
      viewerUid,
      refresh: refresh,
    );
    return parseEach(
      [for (var i = 0; i < snapshot.docs.length; i++) i],
      (i) => _toPost(snapshot.docs[i], likedByMe: liked[i]),
      label: 'Forum posts',
    );
  }

  @override
  Future<List<ForumPostEntity>> getPosts({
    required String viewerUid,
    int limit = 50,
  }) async {
    final snapshot = await _postsQuery(limit).get();
    return _posts(snapshot, viewerUid, refresh: true);
  }

  @override
  Stream<List<ForumPostEntity>> watchPosts({
    required String viewerUid,
    int limit = 50,
  }) {
    return _postsQuery(
      limit,
    ).snapshots().asyncMap((s) => _posts(s, viewerUid, refresh: false));
  }

  @override
  Future<ForumPostEntity?> getPost(
    String postId, {
    required String viewerUid,
  }) async {
    final doc = await _root.doc(postId).get();
    if (!doc.exists) return null;
    final liked = await _likedByViewer([doc], viewerUid, refresh: true);
    return _toPost(doc, likedByMe: liked.first);
  }

  ForumPostEntity _toPost(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required bool likedByMe,
  }) {
    final data = doc.data() ?? const <String, dynamic>{};
    return ForumPostEntity(
      id: doc.id,
      title: docString(data['title']),
      body: docString(data['body']),
      authorUid: docString(data['authorUid']),
      authorName: docString(data['authorName']),
      authorPhotoUrl: docNonEmpty(data['authorPhotoUrl']),
      replyCount: docInt(data['replyCount']) ?? 0,
      // Threads written before likes existed have no counter; they read as
      // zero, and the first like's increment creates the field.
      likeCount: docInt(data['likeCount']) ?? 0,
      likedByMe: likedByMe,
      createdAt: docDate(data['createdAt']) ?? DateTime.now(),
    );
  }

  @override
  Future<void> createPost({
    required String title,
    required String body,
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
  }) {
    return _root.doc(_uuid.v4()).set({
      'title': title,
      'body': body,
      'authorUid': authorUid,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'replyCount': 0,
      'likeCount': 0,
      'createdAt': Timestamp.now(),
    });
  }

  Future<List<ForumReplyEntity>> _repliesOf(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    String viewerUid, {
    required bool refresh,
  }) async {
    final docs = snapshot.docs.reversed.toList();
    final liked = await _likedByViewer(docs, viewerUid, refresh: refresh);
    return parseEach(
      [for (var i = 0; i < docs.length; i++) i],
      (i) => _toReply(docs[i], likedByMe: liked[i]),
      label: 'Forum replies',
    );
  }

  @override
  Future<List<ForumReplyEntity>> getReplies(
    String postId, {
    required String viewerUid,
  }) async {
    final snapshot = await _repliesQuery(postId).get();
    return _repliesOf(snapshot, viewerUid, refresh: true);
  }

  @override
  Stream<List<ForumReplyEntity>> watchReplies(
    String postId, {
    required String viewerUid,
  }) {
    return _repliesQuery(
      postId,
    ).snapshots().asyncMap((s) => _repliesOf(s, viewerUid, refresh: false));
  }

  /// One reply by id, for a deep link to a reply older than the window.
  @override
  Future<ForumReplyEntity?> getReply(
    String postId,
    String replyId, {
    required String viewerUid,
  }) async {
    final doc = await _root.doc(postId).collection(_replies).doc(replyId).get();
    if (!doc.exists) return null;
    final liked = await _likedByViewer([doc], viewerUid, refresh: true);
    return _toReply(doc, likedByMe: liked.first);
  }

  ForumReplyEntity _toReply(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required bool likedByMe,
  }) {
    final data = doc.data() ?? const <String, dynamic>{};
    return ForumReplyEntity(
      id: doc.id,
      body: docString(data['body']),
      authorUid: docString(data['authorUid']),
      authorName: docString(data['authorName']),
      authorPhotoUrl: docNonEmpty(data['authorPhotoUrl']),
      sharedRecipeId: docNonEmpty(data['sharedRecipeId']),
      sharedRecipeTitle: docStringOrNull(data['sharedRecipeTitle']),
      likeCount: docInt(data['likeCount']) ?? 0,
      likedByMe: likedByMe,
      // A reply the local SDK has accepted but the server has not yet: the
      // stream reports it straight away, with this flag, and again without
      // it once the write is acknowledged.
      pending: doc.metadata.hasPendingWrites,
      createdAt: docDate(data['createdAt']) ?? DateTime.now(),
    );
  }

  /// The reply and the thread's counter are written together, so a list built
  /// from the counter cannot drift from the replies that actually exist.
  @override
  Future<String> addReply({
    required String postId,
    required String body,
    required String authorUid,
    required String authorName,
    String? authorPhotoUrl,
    String? sharedRecipeId,
    String? sharedRecipeTitle,
  }) async {
    final post = _root.doc(postId);
    final id = _uuid.v4();
    final reply = post.collection(_replies).doc(id);

    final batch = _firestore.batch();
    batch.set(reply, {
      'body': body,
      'authorUid': authorUid,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'sharedRecipeId': sharedRecipeId,
      'sharedRecipeTitle': sharedRecipeTitle,
      'likeCount': 0,
      'createdAt': Timestamp.now(),
    });
    batch.update(post, {'replyCount': FieldValue.increment(1)});
    await batch.commit();
    return id;
  }

  @override
  Future<bool> togglePostLike(String postId, {required String viewerUid}) =>
      _toggleLike(_root.doc(postId), viewerUid: viewerUid);

  @override
  Future<bool> toggleReplyLike(
    String postId,
    String replyId, {
    required String viewerUid,
  }) => _toggleLike(
    _root.doc(postId).collection(_replies).doc(replyId),
    viewerUid: viewerUid,
  );

  /// The per-user like document and the denormalised counter have to move
  /// together, or a double tap inflates the count. Threads and replies keep
  /// their likes the same way, so one transaction serves both.
  Future<bool> _toggleLike(
    DocumentReference<Map<String, dynamic>> target, {
    required String viewerUid,
  }) async {
    final like = target.collection(_likes).doc(viewerUid);
    final key = _likeKey(target, viewerUid);

    // The cache flips before the write: the counter the transaction moves
    // reaches the live stream before the transaction itself resolves, and a
    // snapshot read against the old flag made the bloc count the like once
    // more on top of the server's. Put back if the write fails.
    final before = _viewerLikes[key];
    _viewerLikes[key] = !(before ?? false);
    final bool liked;
    try {
      liked = await _firestore.runTransaction<bool>((transaction) async {
        final existing = await transaction.get(like);
        if (existing.exists) {
          transaction.delete(like);
          transaction.update(target, {'likeCount': FieldValue.increment(-1)});
          return false;
        }
        transaction.set(like, {'createdAt': Timestamp.now()});
        transaction.update(target, {'likeCount': FieldValue.increment(1)});
        return true;
      });
    } catch (_) {
      if (before == null) {
        _viewerLikes.remove(key);
      } else {
        _viewerLikes[key] = before;
      }
      rethrow;
    }
    _viewerLikes[key] = liked;
    return liked;
  }

  /// Firestore does not cascade, so the replies — and the like documents under
  /// the thread and under each reply — have to go explicitly or they linger
  /// as unreachable, and still billed, documents.
  @override
  Future<void> deletePost(String postId) async {
    final post = _root.doc(postId);
    final replies = await post.collection(_replies).get();
    final postLikes = await post.collection(_likes).get();
    final replyLikes = await Future.wait(
      replies.docs.map((reply) => reply.reference.collection(_likes).get()),
    );

    // A busy thread has more documents than one batch holds. The thread
    // itself goes in the last batch, so a failure part-way leaves it
    // standing (with fewer replies) rather than orphaning what remains.
    final refs = [
      for (final like in postLikes.docs) like.reference,
      for (final likes in replyLikes)
        for (final like in likes.docs) like.reference,
      for (final reply in replies.docs) reply.reference,
      post,
    ];
    for (var i = 0; i < refs.length; i += _batchLimit) {
      final batch = _firestore.batch();
      for (final ref in refs.skip(i).take(_batchLimit)) {
        batch.delete(ref);
      }
      await batch.commit();
    }
  }
}
