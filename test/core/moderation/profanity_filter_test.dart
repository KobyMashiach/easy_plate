import 'package:easy_plate/core/moderation/profanity_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The same sentences functions/profanity.test.js checks.
  const clean = [
    '2 כוסות קמח וכוס סוכר',
    'כוסית יין לבן',
    'מתכון מזין ובריא',
    'אני מכין את זה כבר שנים',
    '5 כפות שמן, 100 גרם חמאה',
    'this is a cook book',
    'Cocktail with dick tracy',
    'מספר 1 בעולם!!',
  ];
  const dirty = [
    'כוס אמק מה זה',
    'יא בן זונה',
    'what the f u c k!',
    'fuuuuck this',
    'sh1t',
    'putain c’est bon',
    'enculé',
    'сука блять',
    'פאקינג טעים',
    'זין',
  ];

  for (final text in clean) {
    test(
      'lets through: $text',
      () => expect(ProfanityFilter.findIn(text), isNull),
    );
  }
  for (final text in dirty) {
    test(
      'refuses: $text',
      () => expect(ProfanityFilter.findIn(text), isNotNull),
    );
  }

  test('check throws for a refused text', () {
    expect(
      () => ProfanityFilter.check(['שלום', 'בן זונה']),
      throwsA(isA<OffensiveContentException>()),
    );
    expect(() => ProfanityFilter.check(['עוגת שוקולד']), returnsNormally);
  });
}
