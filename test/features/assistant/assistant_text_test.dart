import 'package:easy_plate/features/assistant/domain/assistant_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('markdown marks are stripped for the bubble, lines kept', () {
    expect(
      AssistantText.display('**חשוב**: לערבב *היטב*.'),
      'חשוב: לערבב היטב.',
    );
    expect(
      AssistantText.display('## כותרת\n* אחד\n- שניים'),
      'כותרת\n• אחד\n• שניים',
    );
    expect(
      AssistantText.display('use `salt` and 2*3 stars*'),
      'use salt and 23 stars',
    );
    expect(AssistantText.display('__bold__ and _it_'), 'bold and it');
  });

  test('the voice gets words only: no bullets, symbols or emoji', () {
    expect(
      AssistantText.speech('**שלום** 👋\n* מלח\n* פלפל'),
      'שלום\nמלח\nפלפל',
    );
    expect(
      AssistantText.speech('2 כוסות קמח, 1/2 כפית מלח?'),
      '2 כוסות קמח, 1 2 כפית מלח?',
    );
    expect(AssistantText.speech('a > b # c'), 'a b c');
  });

  test('a reply that ends on a question reopens the microphone', () {
    expect(AssistantText.asks('הוספתי. **לאיזה יום** לשים את זה?'), isTrue);
    expect(AssistantText.asks('ما رأيك؟'), isTrue);
    expect(AssistantText.asks('Done. Enjoy!'), isFalse);
    expect(AssistantText.asks('Which day?\nI added the rest.'), isFalse);
    expect(AssistantText.asks(''), isFalse);
  });
}
