import 'package:flutter/widgets.dart';

/// Where the things a walkthrough can point at are on screen.
///
/// A control that a step may highlight wraps itself in a [WalkthroughTarget]
/// with a stable id; the overlay asks here for that id's rectangle each time
/// it draws. Several widgets may carry the same id — the account avatar sits
/// in every main tab's bar — and the first one that is laid out answers.
abstract class WalkthroughTargets {
  static final _keys = <String, List<GlobalKey>>{};

  static void register(String id, GlobalKey key) => (_keys[id] ??= []).add(key);

  static void unregister(String id, GlobalKey key) => _keys[id]?.remove(key);

  /// Whether anything with this id is in the tree right now.
  static bool isMounted(String id) => rectOf(id) != null;

  /// The target's rectangle in screen coordinates, or null when nothing with
  /// this id is laid out at the moment.
  static Rect? rectOf(String id) {
    for (final key in _keys[id] ?? const <GlobalKey>[]) {
      final box = key.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      if (!rect.isEmpty) return rect;
    }
    return null;
  }
}

/// Marks its child as something a walkthrough step can point at.
class WalkthroughTarget extends StatefulWidget {
  final String id;
  final Widget child;

  const WalkthroughTarget({super.key, required this.id, required this.child});

  @override
  State<WalkthroughTarget> createState() => _WalkthroughTargetState();
}

class _WalkthroughTargetState extends State<WalkthroughTarget> {
  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    WalkthroughTargets.register(widget.id, _key);
  }

  @override
  void didUpdateWidget(WalkthroughTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      WalkthroughTargets.unregister(oldWidget.id, _key);
      WalkthroughTargets.register(widget.id, _key);
    }
  }

  @override
  void dispose() {
    WalkthroughTargets.unregister(widget.id, _key);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KeyedSubtree(key: _key, child: widget.child);
}
