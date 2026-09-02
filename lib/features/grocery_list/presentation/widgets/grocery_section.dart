import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/grocery_item_entity.dart';
import 'grocery_item_card.dart';

/// Collapsible group of grocery lines — one for what's still to collect, one
/// for what's already in the basket.
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

class _GrocerySectionState extends State<GrocerySection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.only(bottom: AppSpacing.base),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.surfaceVariant)),
            ),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: _expanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(
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
                  decoration: const ShapeDecoration(
                    color: AppColors.primaryFixed,
                    shape: StadiumBorder(),
                  ),
                  child: Text(
                    '${widget.items.length}',
                    style: AppTextStyles.labelSm.copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          sizeCurve: Curves.easeOut,
          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.gutter),
            child: Column(
              children: [
                for (final item in widget.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: GroceryItemCard(item: item),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
