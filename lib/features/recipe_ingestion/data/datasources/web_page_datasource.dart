import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_enums.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/http_calls.dart';
import '../../../../core/utils/json_ld_recipe.dart';
import '../../../../core/utils/readable_text.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/domain/entities/recipe_ingredient_entity.dart';
import '../../domain/entities/original_recipe_page_entity.dart';

/// Fetches a recipe page directly — no model — for the "show me the original"
/// path, and lifts the site's JSON-LD recipe out of it when there is one.
abstract class WebPageDataSource {
  Future<OriginalRecipePageEntity> fetch(String url);
}

class WebPageDataSourceImpl implements WebPageDataSource {
  static const _uuid = Uuid();
  final HttpCalls httpCalls;

  WebPageDataSourceImpl({HttpCalls? httpCalls})
      : httpCalls = httpCalls ??
            HttpCalls(
              // Plenty of recipe sites answer a bare client with a bot wall;
              // a browser user agent gets the same page a person sees.
              headers: const {
                'User-Agent':
                    'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) '
                        'Chrome/124.0 Mobile Safari/537.36',
                'Accept': 'text/html,application/xhtml+xml',
              },
            );

  @override
  Future<OriginalRecipePageEntity> fetch(String url) async {
    final response = await httpCalls.get(url);
    final data = response?.data;
    final html = data is String ? data : data?.toString() ?? '';

    final readable = readableTextFromHtml(html);
    final structured = _structuredFrom(html, url);

    // A page can legitimately have JSON-LD and near-empty visible text (a
    // JavaScript-rendered site). Only give up when there is neither.
    if (readable.isEmpty && structured == null) {
      throw const AppException(AppErrorType.parsingFailed, message: 'Page had no readable text');
    }

    return OriginalRecipePageEntity(
      url: url,
      title: readable.title ?? structured?.title,
      text: readable.body,
      structured: structured,
    );
  }

  RecipeEntity? _structuredFrom(String html, String url) {
    final recipe = parseJsonLdRecipe(html);
    if (recipe == null) return null;

    return RecipeEntity(
      id: _uuid.v4(),
      title: recipe.title,
      prepTimeMinutes: recipe.prepMinutes,
      cookTimeMinutes: recipe.cookMinutes,
      ingredients: [
        for (final line in recipe.ingredientLines)
          if (parseIngredientLine(line) case final parsed)
            RecipeIngredientEntity(
              name: parsed.name,
              amount: parsed.amount,
              unit: parsed.unit,
            ),
      ],
      steps: recipe.steps,
      dietaryTags: recipe.diets,
      sourceChannel: RecipeIngestionChannel.urlScrape,
      sourceUrl: url,
      createdAt: DateTime.now(),
    );
  }
}
