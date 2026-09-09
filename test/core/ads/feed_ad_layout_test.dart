import 'package:easy_plate/core/ads/feed_ad_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<String> render(FeedAdLayout layout) => [
        for (var i = 0; i < layout.length; i++)
          switch (layout.slotAt(i)) {
            ContentSlot(index: final index) => 'c$index',
            AdSlot(adIndex: final adIndex) => 'ad$adIndex',
          },
      ];

  test('an ad after every five items, and never as the last row', () {
    expect(
      render(const FeedAdLayout(itemCount: 12, interval: 5)),
      ['c0', 'c1', 'c2', 'c3', 'c4', 'ad0', 'c5', 'c6', 'c7', 'c8', 'c9', 'ad1', 'c10', 'c11'],
    );
  });

  test('exactly five items carry no ad', () {
    expect(render(const FeedAdLayout(itemCount: 5, interval: 5)), ['c0', 'c1', 'c2', 'c3', 'c4']);
  });

  test('six items carry one, between the fifth and the sixth', () {
    expect(
      render(const FeedAdLayout(itemCount: 6, interval: 5)),
      ['c0', 'c1', 'c2', 'c3', 'c4', 'ad0', 'c5'],
    );
  });

  test('ten items carry one ad, not a trailing second', () {
    final rows = render(const FeedAdLayout(itemCount: 10, interval: 5));
    expect(rows.where((r) => r.startsWith('ad')).length, 1);
    expect(rows.last, 'c9');
  });

  test('a zero interval is the plain list — premium, or ads switched off', () {
    expect(render(const FeedAdLayout(itemCount: 7, interval: 0)), [
      'c0', 'c1', 'c2', 'c3', 'c4', 'c5', 'c6', //
    ]);
  });

  test('an empty feed has nothing in it', () {
    expect(const FeedAdLayout(itemCount: 0, interval: 5).length, 0);
  });

  test('every content index appears exactly once', () {
    const layout = FeedAdLayout(itemCount: 23, interval: 4);
    final seen = render(layout).where((r) => r.startsWith('c')).toList();
    expect(seen.toSet().length, 23);
    expect(seen.length, 23);
  });
}
