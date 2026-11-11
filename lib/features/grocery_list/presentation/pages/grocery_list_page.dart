import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_enums.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/account_avatar_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/notification_bell_button.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../../core/home_widgets/home_widget_launch.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../../../core/widgets/measurement_unit_label.dart';
import '../../domain/entities/grocery_list_entity.dart';
import '../bloc/grocery_list_bloc.dart';
import '../../../meal_planner/domain/entities/meal_plan_entity.dart';
import '../widgets/grocery_lists_ui.dart';
import '../widgets/grocery_progress_card.dart';
import '../widgets/meal_plan_filter_card.dart';
import '../widgets/grocery_section.dart';
import '../../../../core/walkthrough/walkthrough.dart';
import '../../../../core/walkthrough/app_walkthroughs.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../price_book/presentation/scan_receipt_flow.dart';
import '../../../price_book/presentation/widgets/product_picker_sheet.dart';
import '../../../price_book/domain/entities/price_unit.dart';
import '../../../price_book/presentation/price_book_service.dart';
import '../../../price_book/presentation/widgets/price_widgets.dart';
import '../../../user_profile/domain/usecases/get_user_preferences_usecase.dart';
import '../../../../core/constants/app_motion.dart';
import '../../../../core/features/feature_gate.dart';
import '../../domain/parse_amount.dart';
import '../../../../core/utils/undoable_removals.dart';
import '../../../../core/utils/amount_format.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/grocery_view_prefs.dart';
import '../../domain/grocery_list_edits.dart';
import '../../domain/grocery_voice_parser.dart';
import '../widgets/grocery_quick_actions.dart';

class GroceryListPage extends StatelessWidget {
  const GroceryListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // This device's layout choice, read before the list first shows.
    GroceryViewPrefs.instance.load();
    return BlocProvider(
      create: (context) => GroceryListBloc.fromContext(context),
      child: ChangeNotifierProvider(
        // The price book beside the list: loaded once, asked on every line.
        create: (context) {
          final service = PriceBookService(repository: context.read());
          GetUserPreferencesUseCase(context.read())()
              .then((prefs) {
                service.communityEnabled = prefs.communityPricesEnabled;
                service.load();
              })
              .catchError((Object _) {
                service.load();
              });
          return service;
        },
        child: Builder(
          builder: (context) => ClayScaffold(
            appBar: ClayTopAppBar(
              title: t.appName,
              leading: const AccountAvatarButton(),
              actions: const [NotificationBellButton()],
            ),
            body: _HomeWidgetAddListener(
              child: BlocBuilder<GroceryListBloc, GroceryListState>(
                builder: (context, state) {
                  return switch (state) {
                    GroceryListLoading() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    GroceryListLoaded(
                      list: final list,
                      plans: final plans,
                      lists: final lists,
                    ) =>
                      // Lists waiting out a delete's undo are left out; the
                      // aisle view is this device's own choice.
                      ListenableBuilder(
                        listenable: Listenable.merge([
                          UndoableRemovals.instance.pending,
                          GroceryViewPrefs.instance.byAisle,
                        ]),
                        builder: (context, _) => _ListBody(
                          list: list,
                          plans: plans,
                          lists: visibleGroceryLists(lists),
                          byAisle:
                              GroceryViewPrefs.instance.byAisle.value &&
                              FeaturesFlags.groceryAisleSort.isEnabled,
                        ),
                      ),
                    GroceryListError(error: final error) => ErrorRetryView(
                      error: error,
                      onRetry: () => context.read<GroceryListBloc>().add(
                        const GroceryListEvent.init(),
                      ),
                    ),
                  };
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A home-screen widget asked for the add sheet: the list it named is
/// opened first, then the sheet, once the bloc has that list loaded. The
/// request waits in [HomeWidgetRequests] while the tab is not yet built.
/// A receipt scan asked for by the app icon's shortcut waits the same way.
class _HomeWidgetAddListener extends StatefulWidget {
  final Widget child;
  const _HomeWidgetAddListener({required this.child});

  @override
  State<_HomeWidgetAddListener> createState() => _HomeWidgetAddListenerState();
}

class _HomeWidgetAddListenerState extends State<_HomeWidgetAddListener> {
  StreamSubscription<GroceryListState>? _waiting;

  @override
  void initState() {
    super.initState();
    HomeWidgetRequests.groceryAdd.addListener(_onRequest);
    HomeWidgetRequests.receiptScan.addListener(_onReceiptRequest);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onRequest();
      _onReceiptRequest();
    });
  }

  @override
  void dispose() {
    HomeWidgetRequests.groceryAdd.removeListener(_onRequest);
    HomeWidgetRequests.receiptScan.removeListener(_onReceiptRequest);
    _waiting?.cancel();
    super.dispose();
  }

  void _onReceiptRequest() {
    if (!HomeWidgetRequests.receiptScan.value || !mounted) return;
    HomeWidgetRequests.receiptScan.value = false;
    scanReceipt(context);
  }

  void _onRequest() {
    final request = HomeWidgetRequests.groceryAdd.value;
    if (request == null || !mounted) return;
    HomeWidgetRequests.groceryAdd.value = null;
    final bloc = context.read<GroceryListBloc>();
    final wanted = request.listId;
    final current = bloc.state;
    final ready =
        current is GroceryListLoaded &&
        (wanted == null || current.list.id == wanted);
    if (ready) {
      _openAddSheet(current.list);
      return;
    }
    if (wanted != null) bloc.add(GroceryListEvent.selectList(wanted));
    _waiting?.cancel();
    _waiting = bloc.stream
        .where(
          (s) =>
              s is GroceryListLoaded && (wanted == null || s.list.id == wanted),
        )
        .take(1)
        .timeout(const Duration(seconds: 5), onTimeout: (sink) => sink.close())
        .listen((state) {
          if (mounted) _openAddSheet((state as GroceryListLoaded).list);
        });
  }

  /// The add sheet, or — for a list shared with this account view-only —
  /// why there is none: an item typed there was dropped without a word.
  void _openAddSheet(GroceryListEntity list) {
    if (!list.canEdit) {
      AppDialog.warning(
        message: t.sharing.viewerCannotEditList,
      ).notify(context);
      return;
    }
    showAddGroceryItemSheet(context);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Scans a receipt and, when prices were saved, refreshes the estimates.
Future<void> scanReceipt(BuildContext context) async {
  final service = context.read<PriceBookService>();
  final saved = await scanReceiptFlow(context);
  if (saved != null && saved > 0) {
    await service.load();
  }
}

class _ListBody extends StatelessWidget {
  final GroceryListEntity list;
  final List<MealPlanEntity> plans;
  final List<GroceryListEntity> lists;

  /// Open lines grouped by supermarket aisle.
  final bool byAisle;

  const _ListBody({
    required this.list,
    required this.plans,
    required this.lists,
    this.byAisle = false,
  });

  /// Which list is open, then what it is made from: the menu picker for a
  /// plans list, the servings for a recipe list, nothing for a hand-made one.
  List<Widget> _header() => [
    GroceryListSwitcherCard(list: list, lists: lists),
    const SizedBox(height: AppSpacing.gutter),
    // A shared list says so, and what this account may do with it.
    if (list.isShared) ...[
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: ClayTag(
          label: switch (list.collabRole) {
            CollabRole.owner => t.sharing.ownerTag,
            CollabRole.editor => t.sharing.editorTag,
            _ => t.sharing.viewerTag,
          },
          icon: Icons.group_rounded,
          background: AppColors.secondaryContainer,
          foreground: AppColors.onSecondaryContainer,
        ),
      ),
      const SizedBox(height: AppSpacing.gutter),
    ],
    ...switch (list.source) {
      GroceryListSource.plans => [
        MealPlanFilterCard(list: list, plans: plans),
        const SizedBox(height: AppSpacing.gutter),
      ],
      GroceryListSource.recipe => [
        RecipeListCard(list: list),
        const SizedBox(height: AppSpacing.gutter),
      ],
      GroceryListSource.manual => const <Widget>[],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<GroceryListBloc>();

    if (list.items.isEmpty) {
      return _scroll(
        context,
        bloc,
        list,
        children: [
          ..._header(),
          const SizedBox(height: AppSpacing.sm),
          ClayEmptyState(
            icon: Icons.shopping_basket_rounded,
            message: t.groceryList.empty,
            action: !list.canEdit
                ? null
                : switch (list.source) {
                    GroceryListSource.manual => ClayButton(
                      label: t.groceryList.addFirstItem,
                      icon: Icons.add_rounded,
                      onPressed: () => showAddGroceryItemSheet(context),
                    ),
                    GroceryListSource.recipe => ClayButton(
                      label: t.groceryList.rebuildFromRecipe,
                      icon: Icons.autorenew_rounded,
                      onPressed: () =>
                          bloc.add(const GroceryListEvent.regenerate()),
                    ),
                    GroceryListSource.plans => ClayButton(
                      label: t.groceryList.aggregated,
                      icon: Icons.autorenew_rounded,
                      onPressed: () =>
                          bloc.add(const GroceryListEvent.regenerate()),
                    ),
                  },
          ),
        ],
      );
    }

    final unchecked = list.items.where((i) => !i.isChecked).toList();
    final checked = list.items.where((i) => i.isChecked).toList();
    final allChecked = unchecked.isEmpty;

    return _scroll(
      context,
      bloc,
      list,
      children: [
        ..._header(),
        GroceryProgressCard(
          collected: checked.length,
          total: list.items.length,
        ),
        const SizedBox(height: AppSpacing.gutter),
        if (list.canEdit) ...[
          Row(
            children: [
              Expanded(
                // "Bought everything" ticks what is open and can be taken
                // back; without its flag, the old select-all.
                child: !allChecked && FeaturesFlags.groceryCheckAll.isEnabled
                    ? _BulkAction(
                        icon: Icons.done_all_rounded,
                        label: t.groceryList.boughtAll,
                        onTap: () => boughtEverything(context, bloc, list),
                      )
                    : _BulkAction(
                        icon: allChecked
                            ? Icons.remove_done_rounded
                            : Icons.done_all_rounded,
                        label: allChecked
                            ? t.groceryList.clearAll
                            : t.groceryList.selectAll,
                        onTap: () => bloc.add(.setAllChecked(!allChecked)),
                      ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _BulkAction(
                  icon: Icons.delete_sweep_rounded,
                  label: t.groceryList.deleteChecked,
                  isDestructive: true,
                  onTap: checked.isEmpty
                      ? null
                      : () => deleteCheckedWithUndo(context, bloc, list),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        const FeatureGate(
          feature: FeaturesFlags.groceryAisleSort,
          gapAfter: AppSpacing.sm,
          child: AisleToggle(),
        ),
      ],
      // A viewer of a shared list reads it; the lines take no taps. The
      // sections are slivers of their own, so only the rows on screen are
      // built.
      sections: SliverIgnorePointer(
        ignoring: !list.canEdit,
        sliver: SliverMainAxisGroup(
          slivers: [
            GrocerySection(
              title: t.groceryList.uncheckedSection,
              items: unchecked,
              // Only what is still to collect is walked through the shop.
              groups: byAisle ? aisleGroups(unchecked) : null,
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
            GrocerySection(
              title: t.groceryList.checkedSection,
              items: checked,
              // Collected lines are done with — kept out of the way by
              // default.
              initiallyExpanded: false,
            ),
          ],
        ),
      ),
      after: [
        const SizedBox(height: AppSpacing.lg),
        // What the shop will cost, as far as past receipts can tell.
        FeatureGate(
          feature: FeaturesFlags.groceryCost,
          child: Consumer<PriceBookService>(
            builder: (context, prices, _) => GroceryCostCard(
              summary: prices.summarize(unchecked),
              onScanReceipt: () {
                if (guardFeature(context, FeaturesFlags.receiptScan)) {
                  scanReceipt(context);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// The title floats away as the list scrolls and returns on the first
/// scroll back up; the three actions stay in their corner throughout.
Widget _scroll(
  BuildContext context,
  GroceryListBloc bloc,
  GroceryListEntity list, {
  required List<Widget> children,
  Widget? sections,
  List<Widget> after = const [],
}) {
  return ClayFloatingHeaderView(
    title: t.groceryList.title,
    trailing: _actions(context, bloc, list),
    // Three buttons and the gaps between them; a viewer gets only the
    // price book. The copilot floats over every tab, so it has no button
    // here.
    trailingWidth: list.canEdit ? 48 * 3 + AppSpacing.base * 2 : 48,
    bottomGap: AppSpacing.lg,
    slivers: [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.marginMobile,
          0,
          AppSpacing.marginMobile,
          ClayNavDock.bottomPadding(context),
        ),
        sliver: SliverMainAxisGroup(
          slivers: [
            SliverList.list(children: children),
            ?sections,
            if (after.isNotEmpty) SliverList.list(children: after),
          ],
        ),
      ),
    ],
  );
}

/// The list's own controls sit with its title: a rebuild from the meal plans,
/// and a line added by hand.
Widget _actions(
  BuildContext context,
  GroceryListBloc bloc,
  GroceryListEntity list,
) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      FeatureGate(
        feature: FeaturesFlags.priceBook,
        compact: true,
        axis: Axis.horizontal,
        gapAfter: AppSpacing.base,
        child: WalkthroughTarget(
          id: WalkthroughIds.groceriesPriceBook,
          child: ClayIconButton(
            icon: Icons.receipt_long_rounded,
            size: 48,
            tooltip: t.receipt.priceBook,
            onTap: () async {
              final service = context.read<PriceBookService>();
              await context.pushNamed(Routing.priceBook);
              await service.load();
            },
          ),
        ),
      ),
      if (list.canEdit) ...[
        WalkthroughTarget(
          id: WalkthroughIds.groceriesRegenerate,
          // A hand-made list has nothing to rebuild from: the button stays
          // in its place, greyed, so the row does not shift between lists.
          child: ClayIconButton(
            icon: Icons.autorenew_rounded,
            size: 48,
            tooltip: list.source == GroceryListSource.recipe
                ? t.groceryList.rebuildFromRecipe
                : t.groceryList.aggregated,
            onTap: list.canRegenerate
                ? () => bloc.add(const GroceryListEvent.regenerate())
                : null,
          ),
        ),
        const SizedBox(width: AppSpacing.base),
        WalkthroughTarget(
          id: WalkthroughIds.groceriesAdd,
          child: ClayIconButton(
            icon: Icons.add_rounded,
            filled: true,
            size: 48,
            tooltip: t.groceryList.addItem,
            onTap: () => showAddGroceryItemSheet(context),
          ),
        ),
      ],
    ],
  );
}

class _BulkAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _BulkAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = !enabled
        ? AppColors.outlineVariant
        : isDestructive
        ? AppColors.error
        : AppColors.primary;

    return ClayCard(
      radius: AppRadius.full,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.base),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMd.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Adds a free-text line. It captures a quantity and unit up front so the new
/// item behaves exactly like one that came from a recipe.
Future<void> showAddGroceryItemSheet(BuildContext context) {
  final bloc = context.read<GroceryListBloc>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _AddItemForm(
      onSubmit: (name, amount, unit) =>
          bloc.add(.addAdHocItem(name, amount, unit)),
      onSubmitMany: (heard) {
        final state = bloc.state;
        if (state is! GroceryListLoaded) return;
        final lines = GroceryListEdits.adHocLines(
          heard,
          newId: const Uuid().v4,
        );
        bloc.editList(state.list.id, (l) => GroceryListEdits.add(l, lines));
        AppDialog.success(
          message: t.groceryList.itemsAdded(count: lines.length),
        ).notify(context);
      },
    ),
  );
}

class _AddItemForm extends StatefulWidget {
  final void Function(String name, double amount, MeasurementUnit unit)
  onSubmit;

  /// Several products heard at once, added in one write.
  final void Function(List<VoiceGroceryItem> items)? onSubmitMany;

  const _AddItemForm({required this.onSubmit, this.onSubmitMany});

  @override
  State<_AddItemForm> createState() => _AddItemFormState();
}

class _AddItemFormState extends State<_AddItemForm> {
  // The tour brings a name along, so the line can be added without typing.
  final _nameController = TextEditingController(
    text: Walkthrough.prefill(t.walkthrough.demo.groceryItem),
  );
  final _amountController = TextEditingController(text: '1');
  MeasurementUnit _unit = MeasurementUnit.unit;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  /// Drives the add button's enabled state, so an empty name reads as a
  /// disabled button rather than a tap that silently does nothing.
  bool get _canSubmit => _nameController.text.trim().isNotEmpty;

  void _submit() {
    // Already closing (a second tap in the same frame): popping again
    // would close the page under this sheet, and the item was added twice.
    if (ModalRoute.of(context)?.isCurrent != true) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final amount = parseAmount(_amountController.text) ?? 1;
    widget.onSubmit(name, amount, _unit);
    Navigator.of(context).pop();
  }

  /// Products heard by voice. One goes into the fields as if typed, to be
  /// checked and added as usual; several wait as chips for one tap.
  List<VoiceGroceryItem> _heard = const [];

  void _onHeard(List<VoiceGroceryItem> heard) {
    setState(() {
      if (heard.length == 1) {
        final item = heard.single;
        _heard = const [];
        _nameController.text = item.name;
        _amountController.text = formatAmount(item.amount);
        _unit = item.unit;
      } else {
        _heard = heard;
        _nameController.clear();
      }
    });
  }

  String _describeHeard(VoiceGroceryItem item) {
    if (item.amount == 1 && item.unit == MeasurementUnit.unit) {
      return item.name;
    }
    final unit = measurementUnitLabel(item.unit);
    return '${item.name} · ${formatAmount(item.amount)} $unit'.trim();
  }

  void _submitHeard() {
    if (ModalRoute.of(context)?.isCurrent != true || _heard.isEmpty) return;
    widget.onSubmitMany?.call(_heard);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.marginMobile,
        right: AppSpacing.marginMobile,
        bottom:
            MediaQuery.of(context).viewInsets.bottom + AppSpacing.marginMobile,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.groceryList.addItem, style: AppTextStyles.headlineMd),
            const SizedBox(height: AppSpacing.gutter),
            // Start from a product the receipts already know: its name, and
            // the unit its price is per, so the estimate lines up.
            ClayButton(
              label: t.receipt.pickFromPrices,
              icon: Icons.sell_rounded,
              expanded: true,
              onPressed: () async {
                final picked = await showProductPickerSheet(context);
                if (picked == null || !mounted) return;
                setState(() {
                  _nameController.text = picked.name;
                  _unit = switch (picked.unit) {
                    PriceUnit.kg => MeasurementUnit.kilogram,
                    PriceUnit.liter => MeasurementUnit.liter,
                    PriceUnit.unit => MeasurementUnit.unit,
                  };
                });
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            WalkthroughTarget(
              id: WalkthroughIds.groceriesItemName,
              child: TextField(
                controller: _nameController,
                // Filled in by the tour: the keyboard then waits for a tap.
                autofocus: !Walkthrough.isActive,
                style: AppTextStyles.bodyMd,
                decoration: InputDecoration(
                  labelText: t.groceryList.itemName,
                  // Several products in one breath; the recognizer is the
                  // device's own, the splitting is done here.
                  suffixIcon:
                      widget.onSubmitMany != null &&
                          FeaturesFlags.groceryVoiceAdd.isVisible
                      ? GroceryMicButton(
                          onPartial: (words) => setState(() {
                            _heard = const [];
                            _nameController.text = words;
                          }),
                          onHeard: _onHeard,
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_heard.isNotEmpty)
              HeardItemsPanel(
                items: _heard,
                describe: _describeHeard,
                onRemove: (index) =>
                    setState(() => _heard = [..._heard]..removeAt(index)),
                onAdd: _submitHeard,
              )
            else ...[
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: AppTextStyles.bodyMd,
                decoration: InputDecoration(labelText: t.groceryList.amount),
              ),
              const SizedBox(height: AppSpacing.gutter),
              Text(t.groceryList.unit, style: AppTextStyles.labelMd),
              const SizedBox(height: AppSpacing.base),
              Wrap(
                spacing: AppSpacing.base,
                runSpacing: AppSpacing.base,
                children: MeasurementUnit.values.map((unit) {
                  final isSelected = unit == _unit;
                  return GestureDetector(
                    onTap: () => setState(() => _unit = unit),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: AppMotion.quick,
                      curve: AppMotion.easeOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.base,
                      ),
                      decoration: ShapeDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surfaceContainerLow,
                        shape: StadiumBorder(
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.outlineVariant,
                          ),
                        ),
                      ),
                      child: Text(
                        measurementUnitPickerLabel(unit),
                        style: AppTextStyles.labelMd.copyWith(
                          color: isSelected
                              ? AppColors.onPrimary
                              : AppColors.tertiary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              WalkthroughTarget(
                id: WalkthroughIds.groceriesItemSave,
                child: ClayButton(
                  label: t.common.add,
                  icon: Icons.add_rounded,
                  expanded: true,
                  onPressed: _canSubmit ? _submit : null,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
