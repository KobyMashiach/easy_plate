import '../../../../core/constants/app_enums.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../entities/ingestion_file.dart';
import '../repositories/recipe_ingestion_repository.dart';

class ParseRecipeFromFileUseCase {
  final RecipeIngestionRepository repository;
  ParseRecipeFromFileUseCase(this.repository);

  Future<RecipeEntity> call(
    List<IngestionFile> files, {
    List<DietaryPreference> preferences = const [],
  }) => repository.parseFromFiles(files, preferences);
}
