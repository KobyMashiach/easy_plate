import 'dart:async';

/// Tells the screens that hold their own copy of the account's content that
/// it was rewritten underneath them — after a language switch, every book,
/// plan and list changed words at once. The recipes tab watches its box and
/// needs none of this; the library, the planner and the shopping list load
/// once and would otherwise keep showing the old language until reopened.
class ContentChanges {
  ContentChanges._();
  static final ContentChanges instance = ContentChanges._();

  final _controller = StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  void notify() => _controller.add(null);
}
