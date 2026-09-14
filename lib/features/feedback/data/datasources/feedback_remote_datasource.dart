import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/feedback_entity.dart';

abstract class FeedbackRemoteDataSource {
  Future<void> send(FeedbackEntity feedback);
  Future<List<FeedbackEntity>> getAll({int limit = 200});
}

class FeedbackFirestoreDataSource implements FeedbackRemoteDataSource {
  static const collection = 'feedback';

  final FirebaseFirestore _firestore;

  FeedbackFirestoreDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _root => _firestore.collection(collection);

  @override
  Future<void> send(FeedbackEntity feedback) {
    return _root.doc(feedback.id).set({
      'type': feedback.type.name,
      'message': feedback.message,
      'authorUid': feedback.authorUid,
      'authorName': feedback.authorName,
      'authorEmail': feedback.authorEmail,
      'appVersion': feedback.appVersion,
      'createdAt': Timestamp.now(),
    });
  }

  @override
  Future<List<FeedbackEntity>> getAll({int limit = 200}) async {
    final snapshot = await _root.orderBy('createdAt', descending: true).limit(limit).get();
    return [for (final doc in snapshot.docs) ?_toEntity(doc)];
  }

  FeedbackEntity? _toEntity(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final type = FeedbackType.values.where((t) => t.name == data['type']).firstOrNull;
    if (type == null) return null;
    return FeedbackEntity(
      id: doc.id,
      type: type,
      message: (data['message'] as String?) ?? '',
      authorUid: (data['authorUid'] as String?) ?? '',
      authorName: (data['authorName'] as String?) ?? '',
      authorEmail: data['authorEmail'] as String?,
      appVersion: data['appVersion'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
