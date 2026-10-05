import 'dart:async';

/// Tells the community feed that one of its posts was written from
/// somewhere other than the feed itself — the recipe details page updating
/// the post behind a local recipe, or a share made from the recipes tab.
/// The feed lives in an IndexedStack and reads Firestore once; without this
/// it kept showing the post as it was until the user pulled to refresh.
class SharedFeedChanges {
  SharedFeedChanges._();
  static final SharedFeedChanges instance = SharedFeedChanges._();

  /// Synchronous on purpose: the feed bloc ignores the signal while one of
  /// its own writes is in flight, and that window closes the moment the
  /// use case returns. A queued delivery would land after it and make the
  /// bloc reload a feed it had already patched in place.
  final _controller = StreamController<String>.broadcast(sync: true);

  /// The id of the post that changed.
  Stream<String> get stream => _controller.stream;

  void notify(String sharedId) => _controller.add(sharedId);
}
