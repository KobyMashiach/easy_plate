import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/recipe_entity.dart';

class RecipeCard extends StatelessWidget {
  final RecipeEntity recipe;
  final VoidCallback onTap;

  const RecipeCard({super.key, required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(recipe.title, style: AppTextStyles.pageHeading, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: AppColors.leatherDark),
                  const SizedBox(width: 4),
                  Text(
                    '${(recipe.prepTimeMinutes ?? 0) + (recipe.cookTimeMinutes ?? 0)} דק׳',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.list_alt, size: 16, color: AppColors.leatherDark),
                  const SizedBox(width: 4),
                  Text('${recipe.ingredients.length} מצרכים', style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
