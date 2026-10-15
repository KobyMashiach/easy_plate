import 'package:easy_plate/features/feedback/domain/entities/feedback_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the thread interleaves the opening, follow-ups and replies by time', () {
    final f = FeedbackEntity(
      id: 'f',
      type: FeedbackType.billing,
      message: 'I was charged twice',
      authorUid: 'u',
      authorName: 'Dana',
      createdAt: DateTime(2026, 10, 15, 9),
      replies: [
        FeedbackReply(text: 'Looking into it', at: DateTime(2026, 10, 15, 10)),
        FeedbackReply(text: 'Refunded', at: DateTime(2026, 10, 15, 12)),
      ],
      followUps: [
        FeedbackReply(text: 'Thanks, any news?', at: DateTime(2026, 10, 15, 11)),
      ],
    );
    expect(f.thread.map((m) => m.text), [
      'I was charged twice',
      'Looking into it',
      'Thanks, any news?',
      'Refunded',
    ]);
    expect(f.thread.map((m) => m.fromAdmin), [false, true, false, true]);
    expect(f.last.text, 'Refunded');
    expect(f.answered, isTrue);
    expect(f.updatedAt, f.createdAt, reason: 'defaults to the opening time');
    expect(f.closed, isFalse);
  });

  test('an excerpt flattens whitespace and cuts long text', () {
    expect(FeedbackEntity.excerptOf('a\n\n  b'), 'a b');
    expect(FeedbackEntity.excerptOf('x' * 100).length, 78);
    expect(FeedbackEntity.excerptOf('x' * 100), endsWith('…'));
  });
}
