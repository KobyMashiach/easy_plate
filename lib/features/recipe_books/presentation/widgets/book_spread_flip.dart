import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'book_page_surface.dart';

/// Drives a [BookSpreadFlip] from outside: the capsule's jumps, a contents
/// row, the shell's riffle.
class BookSpreadController {
  _BookSpreadFlipState? _state;

  /// The spread lying open right now.
  int get spread => _state?._spread ?? 0;

  /// Turns one leaf forward; resolves when it has landed. Refused, and
  /// resolved at once, at the back of the book or while a turn is in flight.
  Future<void> next() => _state?._animateTurn(forward: true) ?? Future.value();

  Future<void> previous() => _state?._animateTurn(forward: false) ?? Future.value();

  /// Opens the book straight at [spread], with no turn.
  void jumpTo(int spread) => _state?._jumpTo(spread);
}

/// A book lying open at two pages, turned the way a real book is: the page
/// on the fore-edge lifts, swings over the spine, and lands on the other
/// side showing its back — which is the next page — while the page under it
/// is revealed. Dragged by hand, or turned through a [BookSpreadController].
///
/// Pages are paired in reading order: spread `s` shows pages `2s` and
/// `2s + 1`, the first on the start side. The direction the leaf swings
/// follows the text direction, so a Hebrew book turns from left to right.
class BookSpreadFlip extends StatefulWidget {
  final List<Widget> pages;
  final int initialSpread;
  final BookSpreadController? controller;
  final ValueChanged<int>? onSpreadChanged;
  final Duration duration;

  /// The stock a missing page is printed on — the empty facing page of an
  /// odd-numbered book.
  final Color backgroundColor;

  const BookSpreadFlip({
    super.key,
    required this.pages,
    this.initialSpread = 0,
    this.controller,
    this.onSpreadChanged,
    this.duration = const Duration(milliseconds: 450),
    this.backgroundColor = Colors.white,
  });

  /// How many spreads [pageCount] pages make: an odd last page faces a blank.
  static int spreadCount(int pageCount) => math.max(1, (pageCount + 1) ~/ 2);

  @override
  State<BookSpreadFlip> createState() => _BookSpreadFlipState();
}

class _BookSpreadFlipState extends State<BookSpreadFlip> with SingleTickerProviderStateMixin {
  late int _spread = widget.initialSpread.clamp(0, _spreadCount - 1);

  /// 0 is the leaf flat where it started, 1 flat where it lands.
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  /// Whether a leaf is off the page right now, by hand or by animation.
  bool _turning = false;
  bool _forward = true;
  bool _dragging = false;
  double _halfWidth = 1;

  int get _spreadCount => BookSpreadFlip.spreadCount(widget.pages.length);

  bool get _canGoForward => _spread < _spreadCount - 1;
  bool get _canGoBack => _spread > 0;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _turn.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(BookSpreadFlip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._state = null;
      widget.controller?._state = this;
    }
    if (_spread > _spreadCount - 1) _spread = _spreadCount - 1;
  }

  @override
  void dispose() {
    widget.controller?._state = null;
    _turn.dispose();
    super.dispose();
  }

  bool _allowed(bool forward) => forward ? _canGoForward : _canGoBack;

  Future<void> _animateTurn({required bool forward}) async {
    if (_turning || !_allowed(forward)) return;
    setState(() {
      _turning = true;
      _forward = forward;
    });
    _turn.value = 0;
    await _turn.forward();
    if (mounted) _land();
  }

  /// The leaf has come to rest on the far side: the book is open one spread
  /// on from where it was.
  void _land() {
    setState(() {
      _spread += _forward ? 1 : -1;
      _turning = false;
      _turn.value = 0;
    });
    widget.onSpreadChanged?.call(_spread);
  }

  void _jumpTo(int spread) {
    final target = spread.clamp(0, _spreadCount - 1);
    if (target == _spread && !_turning) return;
    setState(() {
      _spread = target;
      _turning = false;
      _turn.value = 0;
    });
    widget.onSpreadChanged?.call(_spread);
  }

  bool get _rtl => Directionality.of(context) == TextDirection.rtl;

  /// Drag distance in the "forward" sense — toward the start side, which is
  /// the left in a Latin book and the right in a Hebrew one.
  double _forwardDelta(double dx) => _rtl ? dx : -dx;

  void _onDragStart(DragStartDetails _) {
    if (_turn.isAnimating) return;
    _dragging = true;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_dragging) return;
    final delta = _forwardDelta(details.delta.dx);
    if (!_turning) {
      if (delta == 0) return;
      final forward = delta > 0;
      if (!_allowed(forward)) {
        _dragging = false;
        return;
      }
      setState(() {
        _turning = true;
        _forward = forward;
      });
    }
    final signed = _forward ? delta : -delta;
    _turn.value = (_turn.value + signed / _halfWidth).clamp(0.0, 1.0);
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    if (!_dragging) return;
    _dragging = false;
    if (!_turning) return;
    final fling = _forwardDelta(details.primaryVelocity ?? 0);
    final commits = _turn.value > 0.5 || (_forward ? fling > 300 : fling < -300);
    if (commits) {
      await _turn.forward();
      if (mounted) _land();
    } else {
      await _turn.reverse();
      if (mounted) setState(() => _turning = false);
    }
  }

  Widget _page(int index, {required bool isStart}) {
    final page = index >= 0 && index < widget.pages.length
        ? widget.pages[index]
        : ColoredBox(color: widget.backgroundColor);
    // The start page is bound on its end edge: the spine runs down the middle.
    return BookPageSide(spineAtEnd: isStart, child: page);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _halfWidth = constraints.maxWidth / 2;
        final rtl = _rtl;

        // What lies flat on the desk while a leaf is up: the pages the leaf
        // is not, on either side.
        final int startBase;
        final int endBase;
        if (!_turning) {
          startBase = 2 * _spread;
          endBase = 2 * _spread + 1;
        } else if (_forward) {
          startBase = 2 * _spread;
          endBase = 2 * _spread + 3;
        } else {
          startBase = 2 * _spread - 2;
          endBase = 2 * _spread + 1;
        }
        final leftIndex = rtl ? endBase : startBase;
        final rightIndex = rtl ? startBase : endBase;

        return GestureDetector(
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          behavior: HitTestBehavior.opaque,
          child: ClipRect(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Row(
                    children: [
                      Expanded(child: _page(leftIndex, isStart: !rtl)),
                      Expanded(child: _page(rightIndex, isStart: rtl)),
                    ],
                  ),
                ),
                if (_turning) _leaf(rtl),
              ],
            ),
          ),
        );
      },
    );
  }

  /// The leaf in flight. Its front is the page that was lying on the side it
  /// lifts from; its back, the page that will lie on the side it lands on.
  Widget _leaf(bool rtl) {
    final front = _forward ? 2 * _spread + 1 : 2 * _spread;
    final back = _forward ? 2 * _spread + 2 : 2 * _spread - 1;
    // Forward lifts the end page. The end side is the left in a Hebrew book.
    final fromLeft = _forward ? rtl : !rtl;
    final angle = _turn.value * math.pi;
    final showFront = angle <= math.pi / 2;
    final onLeft = showFront ? fromLeft : !fromLeft;
    // Hinged on the spine, which is the leaf's inner edge either way.
    final hinge = onLeft ? Alignment.centerRight : Alignment.centerLeft;
    final rotation = showFront
        ? (fromLeft ? angle : -angle)
        : (fromLeft ? -(math.pi - angle) : math.pi - angle);
    final pageIndex = showFront ? front : back;
    final isStart = onLeft ? !rtl : rtl;
    // The leaf darkens as it stands up, the way paper turns from the light.
    final shade = 0.22 * math.sin(angle);

    return Positioned(
      left: onLeft ? 0 : _halfWidth,
      width: _halfWidth,
      top: 0,
      bottom: 0,
      child: Transform(
        alignment: hinge,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateY(rotation),
        child: DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18 * math.sin(angle)),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _page(pageIndex, isStart: isStart),
              IgnorePointer(
                child: ColoredBox(color: Colors.black.withValues(alpha: shade)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
