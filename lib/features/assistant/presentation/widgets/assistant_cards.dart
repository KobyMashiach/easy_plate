import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/widgets/measurement_unit_label.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../domain/assistant_models.dart';

/// Renders a tool's card the way the app itself shows the same thing: a
/// recipe tile, a live grocery checklist, a planned meal, search results.
class AssistantCardView extends StatelessWidget {
  final AssistantCard card;
  final void Function(RecipeEntity recipe) onOpenRecipe;
  final void Function(String listId, String itemId) onToggleItem;
  final void Function(String text) onSend;

  const AssistantCardView({
    super.key,
    required this.card,
    required this.onOpenRecipe,
    required this.onToggleItem,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return switch (card) {
      RecipeCard(:final recipe, :final caption) => _recipe(recipe, caption),
      RecipeListCard(:final title, :final recipes) => _recipeList(
        title,
        recipes,
      ),
      GroceryCard() => _grocery(card as GroceryCard),
      PlannedMealCard() => _planned(card as PlannedMealCard),
      WebResultsCard(:final results) => _web(results),
      StatusCard(:final text, :final icon) => _status(text, icon),
      LinesCard(:final title, :final lines) => _lines(title, lines),
    };
  }

  Widget _recipe(RecipeEntity recipe, String? caption) {
    final meta = [
      if (recipe.servings != null)
        '${recipe.servings} ${t.nutrition.servings.toLowerCase()}',
      if (recipe.prepTimeMinutes != null)
        t.recipe.minutes(count: recipe.prepTimeMinutes!),
      if (recipe.nutrition != null)
        '${recipe.nutrition!.calories} ${t.nutrition.kcal}',
    ].join(' · ');
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.gutter),
      onTap: () => onOpenRecipe(recipe),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              Icons.restaurant_menu_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (caption != null)
                  Text(
                    caption,
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                Text(
                  recipe.title,
                  style: AppTextStyles.bodyLg,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (meta.isNotEmpty)
                  Text(
                    meta,
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.outline),
        ],
      ),
    );
  }

  Widget _recipeList(String title, List<RecipeEntity> recipes) => ClayCard(
    radius: AppRadius.md,
    padding: const EdgeInsets.all(AppSpacing.gutter),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        for (final r in recipes.take(8))
          InkWell(
            onTap: () => onOpenRecipe(r),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 6, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(r.title, style: AppTextStyles.bodyMd)),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.outline,
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );

  Widget _grocery(GroceryCard card) => ClayCard(
    radius: AppRadius.md,
    padding: const EdgeInsets.all(AppSpacing.gutter),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.shopping_cart_rounded,
              size: 18,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: Text(card.listName, style: AppTextStyles.bodyLg),
            ),
            Text(
              '${card.items.where((i) => i.isChecked).length}/${card.items.length}',
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.base),
        for (final item in card.items.take(12))
          InkWell(
            onTap: () => onToggleItem(card.listId, item.id),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  BouncyCheckbox(
                    value: item.isChecked,
                    onChanged: (_) => onToggleItem(card.listId, item.id),
                    size: 22,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      [
                        if (item.totalAmount > 0)
                          item.totalAmount.toString().replaceAll(
                            RegExp(r'\.0$'),
                            '',
                          ),
                        measurementUnitLabel(item.unit),
                        item.name,
                      ].where((s) => s.isNotEmpty).join(' '),
                      style: AppTextStyles.bodyMd.copyWith(
                        color: item.isChecked
                            ? AppColors.outline
                            : AppColors.onSurface,
                        decoration: item.isChecked
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (card.items.length > 12)
          Text(
            '+${card.items.length - 12}',
            style: AppTextStyles.labelMd.copyWith(color: AppColors.outline),
          ),
      ],
    ),
  );

  Widget _planned(PlannedMealCard card) => ClayCard(
    radius: AppRadius.md,
    padding: const EdgeInsets.all(AppSpacing.gutter),
    onTap: card.recipe == null ? null : () => onOpenRecipe(card.recipe!),
    child: Row(
      children: [
        Icon(Icons.calendar_month_rounded, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${card.dayLabel} · ${card.mealName}',
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Text(card.title, style: AppTextStyles.bodyLg),
              Text(
                card.planName,
                style: AppTextStyles.labelSm.copyWith(color: AppColors.outline),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _web(List results) => ClayCard(
    radius: AppRadius.md,
    padding: const EdgeInsets.all(AppSpacing.gutter),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final r in results)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.title as String, style: AppTextStyles.bodyMd),
                Text(
                  r.snippet as String,
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: ActionChip(
                    avatar: const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: Text(t.ingestion.parse),
                    onPressed: () =>
                        onSend('${t.ingestion.urlScrape}: ${r.url}'),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _status(String text, String icon) {
    final data = switch (icon) {
      'delete' => Icons.delete_outline_rounded,
      'book' => Icons.menu_book_rounded,
      'calendar' => Icons.calendar_month_rounded,
      'flame' => Icons.local_fire_department_rounded,
      'timer' => Icons.timer_rounded,
      'scale' => Icons.scale_rounded,
      _ => Icons.check_circle_rounded,
    };
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.secondaryContainer,
      child: Row(
        children: [
          Icon(data, size: 20, color: AppColors.onSecondaryContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lines(String title, List<String> lines) => ClayCard(
    radius: AppRadius.md,
    padding: const EdgeInsets.all(AppSpacing.gutter),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final line in lines.take(14))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(line, style: AppTextStyles.bodyMd),
          ),
      ],
    ),
  );
}
