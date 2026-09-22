import '../../domain/entities/feedback_entity.dart';
import '../../domain/repositories/feedback_repository.dart';
import '../datasources/feedback_remote_datasource.dart';

class FeedbackRepositoryImpl implements FeedbackRepository {
  final FeedbackRemoteDataSource remoteDataSource;

  FeedbackRepositoryImpl({required this.remoteDataSource});

  @override
  Future<void> send(FeedbackEntity feedback) => remoteDataSource.send(feedback);

  @override
  Future<List<FeedbackEntity>> getAll({int limit = 200}) =>
      remoteDataSource.getAll(limit: limit);

  @override
  Stream<List<FeedbackEntity>> watchAll({int limit = 500}) =>
      remoteDataSource.watchAll(limit: limit);

  @override
  Future<void> setRead(String feedbackId, bool read) =>
      remoteDataSource.setRead(feedbackId, read);

  @override
  Future<void> markAllRead(Iterable<String> feedbackIds) =>
      remoteDataSource.markAllRead(feedbackIds);

  @override
  Future<void> delete(String feedbackId) => remoteDataSource.delete(feedbackId);

  @override
  Future<void> reply({
    required FeedbackEntity feedback,
    required String text,
    required String fromUid,
  }) =>
      remoteDataSource.reply(feedback: feedback, text: text, fromUid: fromUid);
}
