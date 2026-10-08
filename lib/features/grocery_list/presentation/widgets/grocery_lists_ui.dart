import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/amount_format.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../my_recipes/domain/entities/recipe_entity.dart';
import '../../../my_recipes/presentation/widgets/recipe_picker_sheet.dart';
import '../../domain/entities/grocery_list_entity.dart';
import '../bloc/grocery_list_bloc.dart';
import '../../../../core/features/feature_gate.dart';
import '../../../collab_containers/presentation/widgets/container_share_sheets.dart';

/// Everything about having more than one list: the card that names the open
/// one, the sheet that switches between them, the sheet that starts a new
/// one, and — for a list made from a recipe — the card that scales it.

/// One line saying what a list is made from.
String groceryListSourceLabel(GroceryListEntity list) => switch (list.source) {
  GroceryListSource.plans => t.groceryList.sourcePlans,
  GroceryListSource.recipe => t.groceryList.sourceRecipe(
    title: list.recipeTitle ?? list.name,
  ),
  GroceryListSource.manual => t.groceryList.sourceManual,
};

IconData groceryListSourceIcon(GroceryListSource source) => switch (source) {
  GroceryListSource.plans => Icons.calendar_month_rounded,
  GroceryListSource.recipe => Icons.restaurant_menu_rounded,
  GroceryListSource.manual => Icons.edit_note_rounded,
};

/// The open list's name, what it is made from, and how many lists there
/// are; a tap opens the switcher.
class GroceryListSwitcherCard extends StatelessWidget {
  final GroceryListEntity list;
  final List<GroceryListEntity> lists;

  const GroceryListSwitcherCard({
    super.key,
    required this.list,
    required this.lists,
  });

  @override
  Widget build(BuildContext context) {
    final count = lists.length;
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => showGroceryListsSheet(context),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              groceryListSourceIcon(list.source),
              size: 20,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  list.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLg,
                ),
                Text(
                  groceryListSourceLabel(list),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: ShapeDecoration(
              color: AppColors.surfaceContainerLow,
              shape: StadiumBorder(
                side: BorderSide(color: AppColors.outlineVariant),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  count <= 1
                      ? t.groceryList.oneList
                      : t.groceryList.listsCount(count: count),
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.unfold_more_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Every list, the open one marked; tap to open, the menu to rename or
/// delete, and the button at the bottom for a new one. Follows the bloc, so
/// a rename or a delete shows in place.
Future<void> showGroceryListsSheet(BuildContext context) async {
  final bloc = context.read<GroceryListBloc>();
  // The sheet answers true for "new list". The next sheet is opened from
  // here, with the page's context: the lists sheet's own context is gone
  // the moment it closes, and a flow run from it stopped at its first
  // `mounted` check — the options showed, and a choice added nothing.
  final wantsNew = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(value: bloc, child: const _ListsSheet()),
  );
  if (wantsNew == true && context.mounted) {
    await showNewGroceryListSheet(context, bloc);
  }
}

class _ListsSheet extends StatelessWidget {
  const _ListsSheet();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GroceryListBloc>();
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        child: BlocBuilder<GroceryListBloc, GroceryListState>(
          builder: (context, state) {
            if (state is! GroceryListLoaded) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.marginMobile,
                AppSpacing.md,
                AppSpacing.marginMobile,
                AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClaySectionHeader(
                    title: t.groceryList.myLists,
                    underline: true,
                  ),
                  const SizedBox(height: AppSpacing.gutter),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: state.lists.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final list = state.lists[index];
                        return _ListRow(
                          list: list,
                          isOpen: list.id == state.list.id,
                          onOpen: () {
                            bloc.add(GroceryListEvent.selectList(list.id));
                            Navigator.of(context).pop();
                          },
                          onRename: () => _rename(context, bloc, list),
                          // Only the owner hands a list on.
                          onShare: list.isMine
                              ? () => _share(context, bloc, list)
                              : null,
                          onDelete: () => _delete(context, bloc, list),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ClayButton(
                    label: t.groceryList.newList,
                    icon: Icons.add_rounded,
                    expanded: true,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _rename(
    BuildContext context,
    GroceryListBloc bloc,
    GroceryListEntity list,
  ) async {
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _NameSheet(
        title: t.groceryList.renameList,
        initial: list.name,
        confirmLabel: t.common.save,
      ),
    );
    if (name != null) bloc.add(GroceryListEvent.renameList(list.id, name));
  }

  Future<void> _share(
    BuildContext context,
    GroceryListBloc bloc,
    GroceryListEntity list,
  ) async {
    if (!guardFeature(context, FeaturesFlags.shareGroceryLists)) return;
    final sent = await showListShareSheet(context, list);
    if (sent == true && context.mounted) {
      AppDialog.success(message: t.sharing.sent).notify(context);
      // The share tagged the list with its collab id: re-read it so the
      // next write publishes.
      bloc.add(const GroceryListEvent.init());
    }
  }

  /// A member does not delete a shared list; they leave it.
  Future<void> _delete(
    BuildContext context,
    GroceryListBloc bloc,
    GroceryListEntity list,
  ) async {
    final leaves = list.isShared && !list.isMine;
    final confirmed = await AppDialog.warning(
      title: leaves ? t.sharing.leave : t.groceryList.deleteList,
      message: leaves
          ? t.groceryList.leaveListConfirm(name: list.name)
          : t.groceryList.deleteListConfirm(name: list.name),
      icon: leaves ? Icons.logout_rounded : Icons.delete_outline_rounded,
      confirmLabel: leaves ? t.sharing.leave : t.common.delete,
      cancelLabel: t.common.cancel,
      destructive: true,
    ).show(context);
    if (confirmed == true) bloc.add(GroceryListEvent.deleteList(list.id));
  }
}

enum _RowAction { rename, share, delete }

class _ListRow extends StatelessWidget {
  final GroceryListEntity list;
  final bool isOpen;
  final VoidCallback onOpen;
  final VoidCallback onRename;

  /// Null for a list this account does not own: a member cannot share it
  /// further.
  final VoidCallback? onShare;
  final VoidCallback onDelete;

  const _ListRow({
    required this.list,
    required this.isOpen,
    required this.onOpen,
    required this.onRename,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      color: isOpen ? AppColors.primaryFixed : null,
      onTap: onOpen,
      child: Row(
        children: [
          Icon(
            isOpen
                ? Icons.check_circle_rounded
                : groceryListSourceIcon(list.source),
            size: 22,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  list.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLg,
                ),
                Text(
                  groceryListSourceLabel(list),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (list.isShared) ...[
            Icon(Icons.group_rounded, size: 16, color: AppColors.tertiary),
            const SizedBox(width: AppSpacing.xs),
          ],
          if (list.items.isNotEmpty)
            Text(
              t.groceryList.progress(
                checked: list.checkedCount,
                total: list.items.length,
              ),
              textDirection: TextDirection.ltr,
              style: AppTextStyles.labelMd.copyWith(color: AppColors.tertiary),
            ),
          PopupMenuButton<_RowAction>(
            icon: Icon(Icons.more_vert_rounded, color: AppColors.tertiary),
            onSelected: (action) => switch (action) {
              _RowAction.rename => onRename(),
              _RowAction.share => onShare?.call(),
              _RowAction.delete => onDelete(),
            },
            itemBuilder: (_) {
              final share = FeaturesFlags.shareGroceryLists.access;
              final leaves = list.isShared && !list.isMine;
              return [
                // A viewer may not rename: the name is part of what is
                // shared.
                if (list.canEdit)
                  PopupMenuItem(
                    value: _RowAction.rename,
                    child: Text(t.groceryList.renameList),
                  ),
                // The console's switch: gone, tagged, or as built. The tap
                // itself is answered by guardFeature in the sheet.
                if (onShare != null && share.isVisible)
                  PopupMenuItem(
                    value: _RowAction.share,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t.sharing.shareList),
                        if (!share.isEnabled) ...[
                          const SizedBox(width: AppSpacing.base),
                          AccessTag(access: share, compact: true),
                        ],
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: _RowAction.delete,
                  child: Text(
                    leaves ? t.sharing.leave : t.groceryList.deleteList,
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }
}

/// A name and what to build the list from: the menus, one recipe, or
/// nothing. The recipe path goes through the recipe picker and the scale
/// sheet before the list is made.
Future<void> showNewGroceryListSheet(
  BuildContext context,
  GroceryListBloc bloc,
) async {
  final choice =
      await showModalBottomSheet<({String name, GroceryListSource source})>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const _NewListSheet(),
      );
  if (choice == null || !context.mounted) return;

  if (choice.source != GroceryListSource.recipe) {
    bloc.add(GroceryListEvent.createList(choice.name, choice.source));
    return;
  }

  final recipe = await showRecipePickerSheet(
    context,
    where: (r) => r.ingredients.isNotEmpty,
  );
  if (recipe == null || !context.mounted) return;
  final options = await showRecipeGroceryListSheet(
    context,
    recipe,
    initialName: choice.name,
  );
  if (options == null) return;
  bloc.add(
    GroceryListEvent.createRecipeList(recipe, options.name, options.scale),
  );
}

class _NewListSheet extends StatefulWidget {
  const _NewListSheet();

  @override
  State<_NewListSheet> createState() => _NewListSheetState();
}

class _NewListSheetState extends State<_NewListSheet> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _pick(GroceryListSource source) =>
      Navigator.of(context).pop((name: _name.text.trim(), source: source));

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.marginMobile,
          AppSpacing.md,
          AppSpacing.marginMobile,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClaySectionHeader(
                title: t.groceryList.newListTitle,
                underline: true,
              ),
              const SizedBox(height: AppSpacing.gutter),
              TextField(
                controller: _name,
                textInputAction: TextInputAction.done,
                style: AppTextStyles.bodyMd,
                decoration: InputDecoration(
                  labelText: t.groceryList.listName,
                  hintText: t.groceryList.defaultListName,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FeatureGate(
                feature: FeaturesFlags.mealPlans,
                gapAfter: AppSpacing.sm,
                child: _SourceOption(
                  icon: groceryListSourceIcon(GroceryListSource.plans),
                  title: t.groceryList.fromPlans,
                  hint: t.groceryList.fromPlansHint,
                  onTap: () => _pick(GroceryListSource.plans),
                ),
              ),
              _SourceOption(
                icon: groceryListSourceIcon(GroceryListSource.recipe),
                title: t.groceryList.fromRecipe,
                hint: t.groceryList.fromRecipeHint,
                onTap: () => _pick(GroceryListSource.recipe),
              ),
              const SizedBox(height: AppSpacing.sm),
              _SourceOption(
                icon: groceryListSourceIcon(GroceryListSource.manual),
                title: t.groceryList.emptyList,
                hint: t.groceryList.emptyListHint,
                onTap: () => _pick(GroceryListSource.manual),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String hint;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.title,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyLg),
                Text(
                  hint,
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.tertiary),
        ],
      ),
    );
  }
}

/// A one-field sheet for a name. Owns its controller, so nothing is
/// disposed while the sheet's exit animation still draws the field.
class _NameSheet extends StatefulWidget {
  final String title;
  final String initial;
  final String confirmLabel;

  const _NameSheet({
    required this.title,
    required this.initial,
    required this.confirmLabel,
  });

  @override
  State<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<_NameSheet> {
  late final _name = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.marginMobile,
          AppSpacing.md,
          AppSpacing.marginMobile,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClaySectionHeader(title: widget.title, underline: true),
            const SizedBox(height: AppSpacing.gutter),
            TextField(
              controller: _name,
              autofocus: true,
              style: AppTextStyles.bodyMd,
              decoration: InputDecoration(labelText: t.groceryList.listName),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.md),
            ClayButton(
              label: widget.confirmLabel,
              icon: Icons.check_rounded,
              expanded: true,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

/// The smallest and largest amount a recipe list can be scaled to.
const _minScale = 0.5;
const _maxScale = 20.0;

/// How a scale reads and steps: in servings when the recipe says how many
/// it makes, otherwise as a multiplier in halves.
class RecipeScaleStepper extends StatelessWidget {
  final double scale;
  final int? baseServings;
  final ValueChanged<double> onChanged;

  const RecipeScaleStepper({
    super.key,
    required this.scale,
    required this.baseServings,
    required this.onChanged,
  });

  bool get _byServings => baseServings != null && baseServings! > 0;

  double _step(int direction) {
    if (_byServings) {
      final base = baseServings!;
      final servings = (scale * base).round() + direction;
      return (servings.clamp(1, base * _maxScale.toInt()) / base).toDouble();
    }
    return (scale + 0.5 * direction).clamp(_minScale, _maxScale);
  }

  @override
  Widget build(BuildContext context) {
    final label = _byServings
        ? t.groceryList.servings
        : t.groceryList.timesOver;
    final value = _byServings
        ? '${(scale * baseServings!).round()}'
        : t.groceryList.scaleValue(value: formatAmount(scale));
    final canLower = _step(-1) < scale;
    final canRaise = _step(1) > scale;

    return Row(
      children: [
        Expanded(child: Text(label, style: AppTextStyles.bodyMd)),
        IconButton.filledTonal(
          onPressed: canLower ? () => onChanged(_step(-1)) : null,
          icon: const Icon(Icons.remove_rounded),
        ),
        SizedBox(
          width: 56,
          child: Text(
            value,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: AppTextStyles.headlineMd,
          ),
        ),
        IconButton.filledTonal(
          onPressed: canRaise ? () => onChanged(_step(1)) : null,
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}

/// For a list made from a recipe: which recipe, how much of it, and a way
/// back to its lines as the recipe has them.
class RecipeListCard extends StatelessWidget {
  final GroceryListEntity list;

  const RecipeListCard({super.key, required this.list});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GroceryListBloc>();
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.restaurant_menu_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  list.recipeTitle ?? list.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyLg,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          RecipeScaleStepper(
            scale: list.recipeScale,
            baseServings: list.recipeServings,
            onChanged: (scale) =>
                bloc.add(GroceryListEvent.setRecipeScale(scale)),
          ),
        ],
      ),
    );
  }
}

/// Name and amount for a list made from [recipe], before it is created.
/// Resolves null when the user backs out. Used by the recipe's own page and
/// by "new list → from a recipe" on the groceries tab.
Future<({String name, double scale})?> showRecipeGroceryListSheet(
  BuildContext context,
  RecipeEntity recipe, {
  String initialName = '',
}) {
  return showModalBottomSheet<({String name, double scale})>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _RecipeListSheet(
      recipe: recipe,
      initialName: initialName.isEmpty ? recipe.title : initialName,
    ),
  );
}

class _RecipeListSheet extends StatefulWidget {
  final RecipeEntity recipe;
  final String initialName;

  const _RecipeListSheet({required this.recipe, required this.initialName});

  @override
  State<_RecipeListSheet> createState() => _RecipeListSheetState();
}

class _RecipeListSheetState extends State<_RecipeListSheet> {
  late final _name = TextEditingController(text: widget.initialName);
  double _scale = 1;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.recipe.ingredients.length;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.marginMobile,
          AppSpacing.md,
          AppSpacing.marginMobile,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClaySectionHeader(
                title: t.groceryList.recipeListTitle,
                underline: true,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                t.groceryList.recipeListHint,
                style: AppTextStyles.labelMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.gutter),
              TextField(
                controller: _name,
                style: AppTextStyles.bodyMd,
                decoration: InputDecoration(
                  labelText: t.groceryList.listName,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              RecipeScaleStepper(
                scale: _scale,
                baseServings: widget.recipe.servings,
                onChanged: (scale) => setState(() => _scale = scale),
              ),
              const SizedBox(height: AppSpacing.md),
              ClayButton(
                label: t.groceryList.createList,
                icon: Icons.shopping_cart_rounded,
                expanded: true,
                onPressed: count == 0
                    ? null
                    : () => Navigator.of(
                        context,
                      ).pop((name: _name.text.trim(), scale: _scale)),
              ),
              if (count == 0) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  t.groceryList.noIngredients,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
