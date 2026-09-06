import 'package:flutter/material.dart';

/// Wraps a non-scrolling body so a surrounding [RefreshIndicator] still has a
/// scrollable to listen to.
///
/// Without this, pull-to-refresh is unreachable precisely when it is most
/// wanted: an empty list has nothing to overscroll, so the gesture never
/// starts.
class RefreshableEmptyState extends StatelessWidget {
  final Widget child;

  const RefreshableEmptyState({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }
}
