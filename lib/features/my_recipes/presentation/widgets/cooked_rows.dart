import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_motion.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../data/datasources/recipes_ui_store.dart';
import '../../domain/entities/recipe_entity.dart';
import 'recipe_card.dart';

/// "Recently cooked" and "Most cooked" at the top of My Recipes (flag
/// `recentCooked`): the dishes this account actually makes, one swipe away
/// instead of a search. Fed by the cook-mode sessions recorded on this
/// device ([RecipesUiStore]); each row is left out while it has nothing,
/// and a deleted recipe is simply not found in [recipes].
class CookedRows extends StatefulWidget {
  /// The recipes the list shows now — a hidden or deleted one is not here,
  /// so it drops out of the rows too.
  final List<RecipeEntity> recipes;

  /// The grid's own card, with the grid's taps, so a card behaves the same
  /// wherever it is drawn.
  final Widget Function(RecipeEntity recipe) cardBuilder;

  /// Folded away (Koby, 2026-11-24): the page opens on its title, search
  /// and the mine/saved switch; the rows come down only when the list is
  /// pulled past its top, and a small hint with an up arrow says so.
  final bool collapsed;

  /// Opens the rows from the hint, for whoever does not pull.
  final VoidCallback? onReveal;

  const CookedRows({
    super.key,
    required this.recipes,
    required this.cardBuilder,
    this.collapsed = false,
    this.onReveal,
  });

  static const _cardWidth = 168.0;

  @override
  State<CookedRows> createState() => _CookedRowsState();
}

class _CookedRowsState extends State<CookedRows> {
  final _store = RecipesUiStore.instance;
  Map<String, CookRecord> _history = const {};

  @override
  void initState() {
    super.initState();
    _load();
    _store.revision.addListener(_load);
  }

  @override
  void dispose() {
    _store.revision.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final history = await _store.cookHistory();
    if (mounted) setState(() => _history = history);
  }

  @override
  Widget build(BuildContext context) {
    final recent = recentlyCooked(_history, widget.recipes);
    final most = mostCooked(_history, widget.recipes);
    if (recent.isEmpty && most.isEmpty) return const SizedBox.shrink();
    return AnimatedSize(
      duration: AppMotion.reduced(context)
          ? Duration.zero
          : AppMotion.emphasized,
      curve: AppMotion.easeOut,
      alignment: Alignment.topCenter,
      child: widget.collapsed
          ? _hint()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (recent.isNotEmpty) _row(t.recipe.recentlyCooked, recent),
                if (most.isNotEmpty) _row(t.recipe.mostCooked, most),
              ],
            ),
    );
  }

  Widget _hint() {
    final color = AppColors.onSurfaceVariant;
    return Semantics(
      button: true,
      label: t.recipe.cookedHint,
      excludeSemantics: true,
      child: InkWell(
        onTap: widget.onReveal,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.xs,
            bottom: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.keyboard_double_arrow_up_rounded,
                size: 16,
                color: color,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                t.recipe.cookedHint,
                style: AppTextStyles.labelSm.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String title, List<RecipeEntity> recipes) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headlineMd),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: RecipeCard.height,
            // Out to the screen edges, so a card scrolling past is cut by
            // the edge rather than by the page margin.
            child: OverflowBox(
              maxWidth: MediaQuery.sizeOf(context).width,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.marginMobile,
                ),
                itemCount: recipes.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) => SizedBox(
                  width: CookedRows._cardWidth,
                  child: widget.cardBuilder(recipes[index]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
