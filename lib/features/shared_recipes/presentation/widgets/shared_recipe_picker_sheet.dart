import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/auth_session_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../domain/entities/shared_recipe_entity.dart';
import '../../domain/repositories/shared_recipes_repository.dart';
import '../../domain/usecases/get_shared_recipes_usecase.dart';

/// Picks a recipe from the community feed to link to from a forum reply.
Future<SharedRecipeEntity?> showSharedRecipePickerSheet(BuildContext context) {
  return showModalBottomSheet<SharedRecipeEntity>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
    ),
    builder: (sheetContext) => _SharedRecipePickerSheet(
      repository: context.read<SharedRecipesRepository>(),
    ),
  );
}

class _SharedRecipePickerSheet extends StatefulWidget {
  final SharedRecipesRepository repository;

  const _SharedRecipePickerSheet({required this.repository});

  @override
  State<_SharedRecipePickerSheet> createState() => _SharedRecipePickerSheetState();
}

class _SharedRecipePickerSheetState extends State<_SharedRecipePickerSheet> {
  late final Future<List<SharedRecipeEntity>> _future = GetSharedRecipesUseCase(
    widget.repository,
  )(viewerUid: AuthSessionService().user?.uid ?? '');

  String _query = '';

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.md,
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClaySectionHeader(title: t.community.attachRecipe, underline: true),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                style: AppTextStyles.bodyMd,
                decoration: InputDecoration(hintText: t.community.searchHint),
                onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: FutureBuilder<List<SharedRecipeEntity>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final all = snapshot.data ?? const <SharedRecipeEntity>[];
                    final visible = all
                        .where((r) =>
                            _query.isEmpty ||
                            r.recipe.title.toLowerCase().contains(_query) ||
                            r.authorName.toLowerCase().contains(_query))
                        .toList();

                    if (visible.isEmpty) {
                      return ClayEmptyState(
                        icon: Icons.search_off_rounded,
                        message: _query.isEmpty
                            ? t.community.noSharedRecipes
                            : t.community.noResults,
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final shared = visible[index];
                        return ClayCard(
                          radius: AppRadius.md,
                          padding: const EdgeInsets.all(AppSpacing.gutter),
                          onTap: () => Navigator.of(context).pop(shared),
                          child: Row(
                            children: [
                              const Icon(Icons.restaurant_menu_rounded,
                                  size: 20, color: AppColors.primary),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shared.recipe.title,
                                      style: AppTextStyles.bodyMd,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      t.community.byAuthor(name: shared.authorName),
                                      style: AppTextStyles.labelSm
                                          .copyWith(color: AppColors.onSurfaceVariant),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
