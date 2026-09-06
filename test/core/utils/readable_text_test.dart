import 'package:easy_plate/core/utils/readable_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('strips tags but keeps paragraph and list breaks', () {
    const html = '''
      <html><head><title>שקשוקה &amp; סלט</title></head><body>
      <h1>שקשוקה</h1>
      <p>מתכון קל.</p>
      <ul><li>4 ביצים</li><li>עגבניות</li></ul>
      </body></html>''';

    final result = readableTextFromHtml(html);
    expect(result.title, 'שקשוקה & סלט');
    expect(result.body, contains('שקשוקה\n'));
    expect(result.body, contains('• 4 ביצים\n• עגבניות'));
    expect(result.body, isNot(contains('<')));
  });

  test('scripts, styles and chrome never leak into the text', () {
    const html = '''
      <html><body>
      <nav>תפריט ראשי</nav>
      <script>window.x = "לא לזה";</script>
      <style>.a { color: red }</style>
      <p>המתכון</p>
      <footer>כל הזכויות שמורות</footer>
      </body></html>''';

    final body = readableTextFromHtml(html).body;
    expect(body, 'המתכון');
  });

  test('prefers the main content region when the page marks one', () {
    final filler = 'סרגל צד ' * 60;
    final article = 'תוכן המתכון ' * 40;
    final html = '<body><div>$filler</div><article><p>$article</p></article></body>';

    final body = readableTextFromHtml(html).body;
    expect(body, contains('תוכן המתכון'));
    expect(body, isNot(contains('סרגל צד')));
  });

  test('a short article does not hide the rest of the page', () {
    // Some sites wrap only a teaser in <article>; trimming to that would throw
    // the actual recipe away.
    const html = '<body><article>קצר</article><p>המצרכים והשלבים המלאים כאן</p></body>';
    expect(readableTextFromHtml(html).body, contains('המצרכים והשלבים'));
  });

  test('decodes named and numeric entities', () {
    const html = '<p>&frac12; כוס &amp; 180&deg; &#1502;&#x5DC;&#x5D7;</p>';
    expect(readableTextFromHtml(html).body, '½ כוס & 180° מלח');
  });

  test('collapses runs of whitespace without losing paragraphs', () {
    const html = '<p>שורה   אחת</p>\n\n\n\n<p>שורה    שתיים</p>';
    expect(readableTextFromHtml(html).body, 'שורה אחת\n\nשורה שתיים');
  });

  test('an empty or scaffolding-only page reports as empty', () {
    expect(readableTextFromHtml('').isEmpty, isTrue);
    expect(readableTextFromHtml('<html><head><title>x</title></head></html>').isEmpty, isTrue);
  });
}
