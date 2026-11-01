import 'package:flutter/widgets.dart';

/// Pops the route [context] sits in, with [result], but only while that
/// route is still the top one. A choice row in a sheet or dialog that pops
/// unconditionally pops twice on a quick double tap: the first tap starts
/// the sheet closing, and the second — run before the rebuild — lands on
/// the page beneath it and closes the screen the user picked from.
///
/// Returns whether it popped. A context outside any route pops as before.
bool popIfCurrent<T extends Object?>(BuildContext context, [T? result]) {
  if (!context.mounted) return false;
  final route = ModalRoute.of(context);
  if (route != null && !route.isCurrent) return false;
  Navigator.of(context).pop<T>(result);
  return true;
}
