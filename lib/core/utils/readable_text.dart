/// Reduces a web page to the text a person would read on it.
///
/// Deliberately not a full readability algorithm: the goal is to show the
/// original recipe *quickly*, without a model in the loop. It keeps the main
/// content region when the page marks one, drops scripts and styling, and
/// turns block boundaries into line breaks so paragraphs and list items stay
/// apart.
class ReadableText {
  final String? title;
  final String body;

  const ReadableText({required this.title, required this.body});

  bool get isEmpty => body.trim().isEmpty;
}

ReadableText readableTextFromHtml(String html) {
  final title = _match(html, r'<title[^>]*>(.*?)</title>');

  // Whole blocks nobody reads. Removed before anything else so their text
  // never leaks into the body.
  var text = html.replaceAll(
    RegExp(
      r'<(script|style|noscript|svg|head|nav|footer|header|form|iframe)[^>]*>.*?</\1>',
      caseSensitive: false,
      dotAll: true,
    ),
    ' ',
  );
  text = text.replaceAll(RegExp(r'<!--.*?-->', dotAll: true), ' ');

  // A page that marks its main content gets trimmed to it; the rest is
  // sidebars, related links and comments.
  final main = _match(text, r'<(?:article|main)[^>]*>(.*?)</(?:article|main)>');
  if (main != null && main.trim().length > 200) text = main;

  // Block edges become line breaks, so a list of ingredients does not collapse
  // into one run-on line.
  text = text.replaceAll(
    RegExp(r'<br\s*/?>|</(p|div|li|h[1-6]|tr|section|blockquote|dd|dt)>', caseSensitive: false),
    '\n',
  );
  text = text.replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ');
  text = text.replaceAll(RegExp(r'<[^>]+>'), ' ');
  text = decodeHtmlEntities(text);

  // Collapse the whitespace HTML ignores, but keep paragraph breaks.
  text = text
      .split('\n')
      .map((line) => line.replaceAll(RegExp(r'[ \t ]+'), ' ').trim())
      .join('\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();

  return ReadableText(
    title: title == null ? null : decodeHtmlEntities(title).trim(),
    body: text,
  );
}

String? _match(String source, String pattern) {
  final match = RegExp(pattern, caseSensitive: false, dotAll: true).firstMatch(source);
  return match?.group(1);
}

/// Decodes the HTML entities that show up in page titles and recipe text.
String decodeHtmlEntities(String text) {
  const named = {
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#39;': "'",
    '&apos;': "'",
    '&nbsp;': ' ',
    '&ndash;': '–',
    '&mdash;': '—',
    '&hellip;': '…',
    '&deg;': '°',
    '&frac12;': '½',
    '&frac14;': '¼',
    '&frac34;': '¾',
  };
  var out = text;
  named.forEach((entity, char) => out = out.replaceAll(entity, char));
  // Numeric entities, decimal and hex.
  out = out.replaceAllMapped(
    RegExp(r'&#(x?)([0-9a-fA-F]+);'),
    (m) {
      final code = int.tryParse(m.group(2)!, radix: m.group(1)!.isEmpty ? 10 : 16);
      return code == null ? m.group(0)! : String.fromCharCode(code);
    },
  );
  return out;
}
