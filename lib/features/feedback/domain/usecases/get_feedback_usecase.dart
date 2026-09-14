import '../entities/feedback_entity.dart';
import '../repositories/feedback_repository.dart';

class GetFeedbackUseCase {
  final FeedbackRepository repository;
  GetFeedbackUseCase(this.repository);

  Future<List<FeedbackEntity>> call({int limit = 200}) => repository.getAll(limit: limit);
}
