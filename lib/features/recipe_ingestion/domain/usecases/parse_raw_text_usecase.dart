import '../../../../core/constants/app_enums.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../repositories/recipe_ingestion_repository.dart';

class ParseRawTextUseCase {
  final RecipeIngestionRepository repository;
  ParseRawTextUseCase(this.repository);

  Future<RecipeEntity> call(String text, {List<DietaryPreference> preferences = const []}) =>
      repository.parseRawText(text, preferences);
}
