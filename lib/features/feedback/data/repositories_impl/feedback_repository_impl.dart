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
}
