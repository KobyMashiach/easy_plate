import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';

/// Jump list for the open book. Tapping an entry returns its index; dragging
/// an entry reorders the book through [onReorder].
///
/// The order is mirrored locally so the drag lands immediately — the sheet sits
/// on its own route and can't see the book bloc's rebuilt state.
Future<int?> showQuickNavSheet(
  BuildContext context,
  List<RecipeEntity> recipes, {
  required void Function(int oldIndex, int newIndex) onReorder,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      expand: false,
      builder: (context, scrollController) => _QuickNavBody(
        recipes: recipes,
        onReorder: onReorder,
        scrollController: scrollController,
      ),
    ),
  );
}

class _QuickNavBody extends StatefulWidget {
  final List<RecipeEntity> recipes;
  final void Function(int oldIndex, int newIndex) onReorder;
  final ScrollController scrollController;

  const _QuickNavBody({
    required this.recipes,
    required this.onReorder,
    required this.scrollController,
  });

  @override
  State<_QuickNavBody> createState() => _QuickNavBodyState();
}

class _QuickNavBodyState extends State<_QuickNavBody> {
  late final List<RecipeEntity> _recipes = [...widget.recipes];

  void _onReorder(int oldIndex, int newIndex) {
    // ReorderableListView reports the insertion slot, which sits one past the
    // item once it's lifted out of the list above its destination.
    final target = newIndex > oldIndex ? newIndex - 1 : newIndex;
    if (target == oldIndex) return;
    setState(() => _recipes.insert(target, _recipes.removeAt(oldIndex)));
    widget.onReorder(oldIndex, target);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.marginMobile,
          0,
          AppSpacing.marginMobile,
          AppSpacing.marginMobile,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.books.quickNav, style: AppTextStyles.headlineMd),
            const SizedBox(height: AppSpacing.xs),
            Text(
              t.books.reorderHint,
              style: AppTextStyles.labelMd.copyWith(color: AppColors.outline),
            ),
            const SizedBox(height: AppSpacing.gutter),
            // Expanded rather than a fixed height: a long book used to overflow
            // the sheet instead of scrolling.
            Expanded(
              child: ReorderableListView.builder(
                scrollController: widget.scrollController,
                buildDefaultDragHandles: false,
                itemCount: _recipes.length,
                onReorder: _onReorder,
                proxyDecorator: (child, index, animation) => Material(
                  color: Colors.transparent,
                  child: child,
                ),
                itemBuilder: (context, index) {
                  final recipe = _recipes[index];
                  return Padding(
                    key: ValueKey(recipe.id),
                    padding: const EdgeInsets.only(bottom: AppSpacing.base),
                    child: ClayCard(
                      radius: AppRadius.std,
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      onTap: () => Navigator.of(context).pop(index),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryFixed,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${index + 2}',
                              style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              recipe.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodyMd,
                            ),
                          ),
                          ReorderableDragStartListener(
                            index: index,
                            child: const Padding(
                              padding: EdgeInsets.all(AppSpacing.xs),
                              child: Icon(
                                Icons.drag_handle_rounded,
                                color: AppColors.outline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
