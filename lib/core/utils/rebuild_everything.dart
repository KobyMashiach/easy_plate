import 'package:flutter/widgets.dart';

/// Marks every element in the tree dirty, so the whole app rebuilds in the
/// very next frame.
///
/// Needed wherever a value is read through a plain global instead of an
/// inherited widget, so nothing subscribes to it: the colours (`AppColors`)
/// and the strings (slang's `t`). The widgets that happen to depend on the
/// `TranslationProvider` or `Theme.of` rebuild on their own; the tabs kept
/// alive in an `IndexedStack`, pages under the router, and any child its
/// parent hands the same instance are skipped and keep the old value until
/// something else rebuilds them. This is the sweep hot reload does, minus the
/// `reassemble` calls that would reset state.
void rebuildEverything() {
  final root = WidgetsBinding.instance.rootElement;
  if (root == null) return;
  void visit(Element element) {
    element.markNeedsBuild();
    element.visitChildren(visit);
  }

  visit(root);
}
