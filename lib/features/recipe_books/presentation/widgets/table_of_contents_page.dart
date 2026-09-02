import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';

class TableOfContentsPage extends StatelessWidget {
  final String bookTitle;
  final List<RecipeEntity> recipes;
  final ValueChanged<int> onSelectRecipe;

  const TableOfContentsPage({
    super.key,
    required this.bookTitle,
    required this.recipes,
    required this.onSelectRecipe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.parchment,
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(bookTitle, style: AppTextStyles.bookTitle),
          const SizedBox(height: 4),
          Text(t.books.tableOfContents, style: AppTextStyles.caption),
          const Divider(height: 32),
          Expanded(
            child: recipes.isEmpty
                ? Center(child: Text(t.books.emptyBook, style: AppTextStyles.body))
                : ListView.separated(
                    itemCount: recipes.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];
                      return InkWell(
                        onTap: () => onSelectRecipe(index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Expanded(child: Text(recipe.title, style: AppTextStyles.body)),
                              Text('${index + 2}', style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
