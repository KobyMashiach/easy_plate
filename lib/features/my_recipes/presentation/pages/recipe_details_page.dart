import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/measurement_unit_label.dart';
import '../../domain/entities/recipe_entity.dart';
import '../../domain/entities/recipe_ingredient_entity.dart';

class RecipeDetailsPage extends StatelessWidget {
  final RecipeEntity recipe;

  const RecipeDetailsPage({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(recipe.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              _TimeChip(label: t.recipe.prepTime, minutes: recipe.prepTimeMinutes),
              const SizedBox(width: 12),
              _TimeChip(label: t.recipe.cookTime, minutes: recipe.cookTimeMinutes),
            ],
          ),
          const SizedBox(height: 24),
          Text(t.recipe.ingredients, style: AppTextStyles.pageHeading),
          const SizedBox(height: 12),
          ...recipe.ingredients.map(
            (ingredient) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(_ingredientLine(ingredient), style: AppTextStyles.body),
            ),
          ),
          const SizedBox(height: 24),
          Text(t.recipe.instructions, style: AppTextStyles.pageHeading),
          const SizedBox(height: 12),
          ...recipe.steps.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text('${entry.key + 1}. ${entry.value}', style: AppTextStyles.body),
                ),
              ),
        ],
      ),
    );
  }

  String _ingredientLine(RecipeIngredientEntity ingredient) {
    final amount = ingredient.isAmountMissing ? kMissingInfoPlaceholder : ingredient.amount.toString();
    final unit = measurementUnitLabel(ingredient.unit);
    return [amount, unit, ingredient.name].where((s) => s.isNotEmpty).join(' ');
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final int? minutes;

  const _TimeChip({required this.label, required this.minutes});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: ${minutes != null ? '$minutes דק׳' : kMissingInfoPlaceholder}'),
    );
  }
}
