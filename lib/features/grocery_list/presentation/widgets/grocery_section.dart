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

  /// The same lines split under small headings (supermarket aisles), in
  /// the order given. Null for one plain run of [items].
  final List<(String, List<GroceryItemEntity>)>? groups;

  const GrocerySection({
    super.key,
    required this.title,
    required this.items,
    this.initiallyExpanded = true,
    this.groups,
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
    final index = _rows.indexWhere(
      (row) => row is GroceryItemEntity && row.id == key.value,
    );
    return index < 0 ? null : index + 1;
  }

  /// What the list shows under the header: the lines, or — grouped — each
  /// group's heading (a String) followed by its lines. Worked out once per
  /// build, not once per row.
  List<Object> _rows = const [];

  List<Object> _rowsOf(GrocerySection widget) {
    final groups = widget.groups;
    if (groups == null) return widget.items;
    return [
      for (final (label, items) in groups) ...[label, ...items],
    ];
  }

  Widget _row(BuildContext context, int index) {
    // Row 0 is the gap under the header, sized with the rows.
    final row = index == 0 ? null : _rows[index - 1];
    return SizeTransition(
      key: row is GroceryItemEntity ? ValueKey<String>(row.id) : null,
      sizeFactor: _size,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: _reveal,
        child: switch (row) {
          null => const SizedBox(
            width: double.infinity,
            height: AppSpacing.gutter,
          ),
          final GroceryItemEntity item => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: GroceryItemCard(item: item),
          ),
          _ => Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.xs,
              top: AppSpacing.xs,
              bottom: AppSpacing.base,
            ),
            child: Semantics(
              header: true,
              child: Text(
                '$row',
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showRows = _expanded || !_reveal.isDismissed;
    _rows = _rowsOf(widget);
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: _header()),
        if (showRows)
          SliverList.builder(
            itemCount: _rows.length + 1,
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
            // The chevron mirrors itself under RTL (it points left there), so
            // it turns the other way to land pointing down.
            AnimatedRotation(
              turns: _expanded ? disclosureOpenTurns(context) : 0,
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
