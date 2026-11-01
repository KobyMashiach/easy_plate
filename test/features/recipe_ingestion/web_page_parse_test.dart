import 'package:easy_plate/core/utils/json_ld_recipe.dart';
import 'package:easy_plate/core/utils/readable_text.dart';
import 'package:easy_plate/features/recipe_ingestion/data/datasources/web_page_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

String _page({required int paragraphs}) {
  final b = StringBuffer('<html><head><title>Best Shakshuka</title>')
    ..write(
      '<script type="application/ld+json">{"@context":"https://schema.org",'
      '"@type":"Recipe","name":"Shakshuka",'
      '"recipeIngredient":["4 eggs","2 cups tomatoes"],'
      '"recipeInstructions":[{"@type":"HowToStep","text":"Cook 10 minutes"}]}'
      '</script></head><body>',
    );
  for (var i = 0; i < paragraphs; i++) {
    b.write(
      '<div><p>Paragraph $i &amp; more <a href="/x">link</a></p></div>\n',
    );
  }
  b.write('</body></html>');
  return b.toString();
}

void main() {
  for (final (label, paragraphs) in [
    ('a small page', 5),
    ('a big page', 4000),
  ]) {
    test('$label reads the same as the inline parse', () async {
      final html = _page(paragraphs: paragraphs);
      final (readable, structured) =
          await WebPageDataSourceImpl.parseOriginalPage(html, 'https://x.test');

      final inline = readableTextFromHtml(html);
      expect(readable.title, inline.title);
      expect(readable.body, inline.body);
      expect(structured?.title, parseJsonLdRecipe(html)?.title);
      expect(structured?.ingredients.map((i) => i.name), ['eggs', 'tomatoes']);
      expect(structured?.sourceUrl, 'https://x.test');
    });
  }
}
