import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/measurement_unit_label.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';

class RecipeBookPage extends StatelessWidget {
  final RecipeEntity recipe;
  final int pageNumber;

  const RecipeBookPage({super.key, required this.recipe, required this.pageNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.parchment,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.title, style: AppTextStyles.bookTitle),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    children: [
                      Text(
                        '${t.recipe.prepTime}: ${recipe.prepTimeMinutes ?? kMissingInfoPlaceholder}',
                        style: AppTextStyles.caption,
                      ),
                      Text(
                        '${t.recipe.cookTime}: ${recipe.cookTimeMinutes ?? kMissingInfoPlaceholder}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                  const Divider(height: 28),
                  Text(t.recipe.ingredients, style: AppTextStyles.pageHeading),
                  const SizedBox(height: 8),
                  ...recipe.ingredients.map((ingredient) {
                    final amount =
                        ingredient.isAmountMissing ? kMissingInfoPlaceholder : ingredient.amount.toString();
                    final unit = measurementUnitLabel(ingredient.unit);
                    final line = [amount, unit, ingredient.name].where((s) => s.isNotEmpty).join(' ');
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text('• $line', style: AppTextStyles.body),
                    );
                  }),
                  const SizedBox(height: 20),
                  Text(t.recipe.instructions, style: AppTextStyles.pageHeading),
                  const SizedBox(height: 8),
                  ...recipe.steps.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Text('${entry.key + 1}. ${entry.value}', style: AppTextStyles.body),
                        ),
                      ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Text('$pageNumber', style: AppTextStyles.caption),
          ),
        ],
      ),
    );
  }
}
