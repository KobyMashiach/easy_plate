import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Gives a small control a finger-sized hit area (48×48 by default, the
/// Android and WCAG minimum) without changing how big it is drawn or how
/// much room it takes in its row.
///
/// Growing the layout box instead (what Material's padded tap target does)
/// would push every bar and chip row apart by the difference; these
/// controls were laid out for their drawn size. So the box keeps the
/// child's size, and only hit testing and the bounds reported to screen
/// readers are inflated around it. A touch in the margin is handed to the
/// child at the nearest point of its own box, so the gesture detector
/// inside sees an ordinary tap.
///
/// The margin only catches touches that reach this widget: an ancestor
/// that clips hit testing to its own bounds (a SizedBox as tall as the
/// button) still limits it, which is why it helps most in rows and lists.
class MinTapTarget extends SingleChildRenderObjectWidget {
  final double minSize;

  const MinTapTarget({super.key, this.minSize = 48, required Widget child})
    : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderMinTapTarget(minSize: minSize);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderMinTapTarget renderObject,
  ) {
    renderObject.minSize = minSize;
  }
}

class RenderMinTapTarget extends RenderProxyBox {
  RenderMinTapTarget({required double minSize}) : _minSize = minSize;

  double _minSize;
  double get minSize => _minSize;
  set minSize(double value) {
    if (value == _minSize) return;
    _minSize = value;
    markNeedsSemanticsUpdate();
  }

  /// The child's box grown evenly on each side up to [minSize].
  Rect get _target {
    final dx = ((minSize - size.width) / 2).clamp(0.0, double.infinity);
    final dy = ((minSize - size.height) / 2).clamp(0.0, double.infinity);
    return Rect.fromLTRB(-dx, -dy, size.width + dx, size.height + dy);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!_target.contains(position)) return false;
    // Pulled onto the child's own box, just inside its far edges (Size
    // .contains is exclusive there), so the child accepts it.
    final inside = Offset(
      position.dx.clamp(0.0, (size.width - 0.01).clamp(0.0, double.infinity)),
      position.dy.clamp(0.0, (size.height - 0.01).clamp(0.0, double.infinity)),
    );
    final hit = hitTestChildren(result, position: inside);
    if (hit) result.add(BoxHitTestEntry(this, position));
    return hit;
  }

  /// One node for the whole control, as [MergeSemantics] makes, so the
  /// bounds a screen reader (and the accessibility scanner) sees are the
  /// inflated ones below rather than the drawn circle's.
  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..isMergingSemanticsOfDescendants = true;
  }

  @override
  Rect get semanticBounds => _target;

  @override
  Rect get paintBounds => Offset.zero & size;
}
