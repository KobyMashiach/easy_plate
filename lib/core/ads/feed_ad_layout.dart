/// One position in a feed that mixes content with ad cards.
sealed class FeedSlot {
  const FeedSlot();
}

class ContentSlot extends FeedSlot {
  /// Index into the feed's own item list.
  final int index;
  const ContentSlot(this.index);
}

class AdSlot extends FeedSlot {
  /// The n-th ad in the feed, from zero. Stable across rebuilds, which is what
  /// lets a loaded ad stay put while the content around it changes.
  final int adIndex;
  const AdSlot(this.adIndex);
}

/// Where the ad cards go, as arithmetic.
///
/// One ad after every [interval] items, and only *between* items: a feed of
/// exactly [interval] items ends on content, not on an ad. With no items, or a
/// non-positive interval, the layout is the plain list.
class FeedAdLayout {
  final int itemCount;
  final int interval;

  const FeedAdLayout({required this.itemCount, required this.interval});

  bool get _hasAds => interval > 0 && itemCount > interval;

  int get adCount => _hasAds ? (itemCount - 1) ~/ interval : 0;

  int get length => itemCount + adCount;

  FeedSlot slotAt(int position) {
    if (!_hasAds) return ContentSlot(position);
    final block = position ~/ (interval + 1);
    final offset = position % (interval + 1);
    if (offset == interval) return AdSlot(block);
    return ContentSlot(block * interval + offset);
  }
}
