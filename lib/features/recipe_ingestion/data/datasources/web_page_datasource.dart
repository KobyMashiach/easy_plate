import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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

  /// Where [url] really leads, when it leads anywhere: the address after
  /// redirects, or null for a page that is gone (404/410), a server that
  /// fails, or a host that does not answer at all. A link a model wrote may
  /// be one it made up; this is the check before it is offered.
  Future<String?> liveUrl(String url);
}

/// Whether a status says the page is there: an answer, or a bot wall
/// (401/403/429) in front of a real page. Anything else — 404, a 400 for a
/// made-up path, a broken server — counts as dead.
@visibleForTesting
bool isLiveStatus(int status) =>
    (status >= 200 && status < 400) ||
    status == 401 ||
    status == 403 ||
    status == 429;

class WebPageDataSourceImpl implements WebPageDataSource {
  static const _uuid = Uuid();
  final HttpCalls httpCalls;

  WebPageDataSourceImpl({HttpCalls? httpCalls})
    : httpCalls =
          httpCalls ??
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

  /// A separate client: a probe follows redirects, reads only the headers,
  /// and takes any status as an answer.
  static final _probe = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 6),
      followRedirects: true,
      maxRedirects: 5,
      responseType: ResponseType.stream,
      validateStatus: (_) => true,
      headers: const {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/124.0 Mobile Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml',
      },
    ),
  );

  @override
  Future<String?> liveUrl(String url) async {
    try {
      final response = await _probe.get<ResponseBody>(url);
      // Only the status was wanted: the body is not read.
      unawaited(response.data?.stream.listen(null).cancel());
      final status = response.statusCode ?? 0;
      if (!isLiveStatus(status)) return null;
      return response.realUri.toString();
    } on DioException catch (e) {
      // Slow is not dead: a page that did not answer in time is kept.
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return url;
      }
      return null;
    }
  }

  @override
  Future<OriginalRecipePageEntity> fetch(String url) async {
    final response = await httpCalls.get(url);
    final data = response?.data;
    final html = data is String ? data : data?.toString() ?? '';

    final (readable, structured) = await parseOriginalPage(html, url);

    // A page can legitimately have JSON-LD and near-empty visible text (a
    // JavaScript-rendered site). Only give up when there is neither.
    if (readable.isEmpty && structured == null) {
      throw const AppException(
        AppErrorType.parsingFailed,
        message: 'Page had no readable text',
      );
    }

    return OriginalRecipePageEntity(
      url: url,
      title: readable.title ?? structured?.title,
      text: readable.body,
      structured: structured,
    );
  }

  /// The page's readable text and its JSON-LD recipe, worked out off the
  /// UI isolate: a recipe page is often most of a megabyte of HTML, and the
  /// regular-expression passes over it (~12–50 ms for 730 KB on a desktop,
  /// several times that on a phone) froze the spinner the user was
  /// watching. Small pages are not worth an isolate.
  @visibleForTesting
  static Future<(ReadableText, RecipeEntity?)> parseOriginalPage(
    String html,
    String url,
  ) => html.length < _isolateFrom
      ? Future.value(_parse((html, url)))
      : compute(_parse, (html, url));

  static const _isolateFrom = 64 * 1024;

  static (ReadableText, RecipeEntity?) _parse((String, String) page) {
    final (html, url) = page;
    return (readableTextFromHtml(html), _structuredFrom(html, url));
  }

  static RecipeEntity? _structuredFrom(String html, String url) {
    final recipe = parseJsonLdRecipe(html);
    if (recipe == null) return null;

    return RecipeEntity(
      id: _uuid.v4(),
      title: recipe.title,
      prepTimeMinutes: recipe.prepMinutes,
      cookTimeMinutes: recipe.cookMinutes,
      // Sites write "For the sauce:" as a line of its own; it becomes the
      // heading of the lines under it rather than an ingredient.
      ingredients: sectionHeadingsLifted([
        for (final line in recipe.ingredientLines)
          if (parseIngredientLine(line) case final parsed)
            RecipeIngredientEntity(
              name: parsed.name,
              amount: parsed.amount,
              unit: parsed.unit,
            ),
      ]),
      steps: recipe.steps,
      dietaryTags: recipe.diets,
      sourceChannel: RecipeIngestionChannel.urlScrape,
      sourceUrl: url,
      createdAt: DateTime.now(),
    );
  }
}
