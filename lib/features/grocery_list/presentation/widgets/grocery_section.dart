import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/grocery_item_entity.dart';
import 'grocery_item_card.dart';
import '../../../../core/constants/app_motion.dart';

/// Collapsible group of grocery lines — one for what's still to collect, one
/// for what's already in the basket.
///
/// A sliver: the lines are built lazily, so a list of hundreds only builds
/// the rows on screen, and a collapsed section builds none of them. The
/// expand/collapse animation sizes and fades each built row together, which
/// reads as the whole group opening and closing.
class GrocerySection extends StatefulWidget {
  final String title;
  final List<GroceryItemEntity> items;
  final bool initiallyExpanded;

  const GrocerySection({
    super.key,
    required this.title,
    required this.items,
    this.initiallyExpanded = true,
  });

  @override
  State<GrocerySection> createState() => _GrocerySectionState();
}

class _GrocerySectionState extends State<GrocerySection>
    with SingleTickerProviderStateMixin {
  late bool _expanded = widget.initiallyExpanded;

  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: AppMotion.standard,
    value: _expanded ? 1 : 0,
  )..addStatusListener(_onRevealStatus);

  late final Animation<double> _size = CurvedAnimation(
    parent: _reveal,
    curve: AppMotion.easeOut,
  );

  /// Once fully closed the rows leave the tree.
  void _onRevealStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && mounted) setState(() {});
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _reveal.forward();
    } else {
      _reveal.reverse();
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  /// Keeps a row's state (its open breakdown) with its item when lines move
  /// between sections or are removed.
  int? _indexOfKey(Key key) {
    if (key is! ValueKey<String>) return null;
    final index = widget.items.indexWhere((item) => item.id == key.value);
    return index < 0 ? null : index + 1;
  }

  Widget _row(BuildContext context, int index) {
    // Row 0 is the gap under the header, sized with the rows.
    final item = index == 0 ? null : widget.items[index - 1];
    return SizeTransition(
      key: item == null ? null : ValueKey<String>(item.id),
      sizeFactor: _size,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: _reveal,
        child: item == null
            ? const SizedBox(width: double.infinity, height: AppSpacing.gutter)
            : Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: GroceryItemCard(item: item),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showRows = _expanded || !_reveal.isDismissed;
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: _header()),
        if (showRows)
          SliverList.builder(
            itemCount: widget.items.length + 1,
            findChildIndexCallback: _indexOfKey,
            itemBuilder: _row,
          ),
      ],
    );
  }

  Widget _header() {
    return GestureDetector(
      onTap: _toggle,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.only(bottom: AppSpacing.base),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.surfaceVariant),
          ),
        ),
        child: Row(
          children: [
            AnimatedRotation(
              turns: _expanded ? 0.25 : 0,
              duration: AppMotion.standard,
              curve: AppMotion.easeOut,
              child: Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: Text(widget.title, style: AppTextStyles.headlineMd),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: ShapeDecoration(
                color: AppColors.primaryFixed,
                shape: const StadiumBorder(),
              ),
              child: Text(
                '${widget.items.length}',
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
