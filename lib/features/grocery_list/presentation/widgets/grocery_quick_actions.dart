import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_motion.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/features/feature_gate.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/utils/undoable_removals.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../assistant/presentation/assistant_voice.dart';
import '../../data/datasources/grocery_view_prefs.dart';
import '../../domain/entities/grocery_item_entity.dart';
import '../../domain/entities/grocery_list_entity.dart';
import '../../domain/grocery_aisles.dart';
import '../../domain/grocery_list_edits.dart';
import '../../domain/grocery_voice_parser.dart';
import '../bloc/grocery_list_bloc.dart';

/// The list-wide shortcuts of the groceries tab — "bought everything", the
/// aisle view, voice entry — and the undo notices that replace the old
/// confirmations. Every write goes through [GroceryListBloc.editList] or the
/// bloc's own events, so a shared list's members see it as usual.

/// Ticks every line still open, and offers to untick exactly those again.
void boughtEverything(
  BuildContext context,
  GroceryListBloc bloc,
  GroceryListEntity list,
) {
  final ids = {
    for (final item in list.items)
      if (!item.isChecked) item.id,
  };
  if (ids.isEmpty) return;
  bloc.editList(list.id, (l) => GroceryListEdits.check(l, ids));
  AppDialog.undo(
    context,
    message: t.groceryList.boughtAllDone(count: ids.length),
    icon: Icons.done_all_rounded,
    onUndo: () =>
        bloc.editList(list.id, (l) => GroceryListEdits.uncheck(l, ids)),
  );
}

/// Deletes the ticked lines as before; with the undo flag on, the notice
/// puts them back where they were.
void deleteCheckedWithUndo(
  BuildContext context,
  GroceryListBloc bloc,
  GroceryListEntity list,
) {
  final removed = GroceryListEdits.positionsOf(list, (i) => i.isChecked);
  bloc.add(const GroceryListEvent.deleteCheckedItems());
  if (removed.isEmpty || !FeaturesFlags.undoInsteadOfConfirm.isEnabled) {
    return;
  }
  AppDialog.undo(
    context,
    message: t.groceryList.checkedDeleted(count: removed.length),
    onUndo: () =>
        bloc.editList(list.id, (l) => GroceryListEdits.restore(l, removed)),
  );
}

// ── Deleting a list ───────────────────────────────────────────────────────

String _listKey(String id) => UndoableRemovals.keyFor('groceryList', id);

/// [lists] without the ones waiting out their undo window.
List<GroceryListEntity> visibleGroceryLists(List<GroceryListEntity> lists) => [
  for (final l in lists)
    if (!UndoableRemovals.instance.isPending(_listKey(l.id))) l,
];

/// Whether [list] can go with an undo rather than a confirmation: one of
/// this account's own, not shared (deleting a shared list takes it from
/// every member, which no undo can put back), and not the last list (the
/// tab always shows one, and would open a fresh one in its place).
bool canDeleteListWithUndo(
  GroceryListEntity list,
  List<GroceryListEntity> lists,
) =>
    FeaturesFlags.undoInsteadOfConfirm.isEnabled &&
    !list.isShared &&
    visibleGroceryLists(lists).any((l) => l.id != list.id);

/// Hides [list] for the undo window and deletes it once the notice leaves
/// without an undo — through the bloc, so the open list, the shared copy
/// and the cloud mirror are handled exactly as a confirmed delete was.
void deleteListWithUndo(
  BuildContext context,
  GroceryListBloc bloc,
  GroceryListEntity list,
  List<GroceryListEntity> lists,
) {
  final state = bloc.state;
  final wasOpen = state is GroceryListLoaded && state.list.id == list.id;
  if (wasOpen) {
    final next = visibleGroceryLists(lists).firstWhere((l) => l.id != list.id);
    bloc.add(GroceryListEvent.selectList(next.id));
  }
  UndoableRemovals.instance.remove(
    context,
    key: _listKey(list.id),
    message: t.groceryList.listDeletedUndo(name: list.name),
    commit: () async {
      if (bloc.isClosed) return;
      bloc.add(GroceryListEvent.deleteList(list.id));
    },
    onUndone: () {
      if (wasOpen && !bloc.isClosed) {
        bloc.add(GroceryListEvent.selectList(list.id));
      }
    },
  );
}

// ── Aisle view ────────────────────────────────────────────────────────────

String aisleLabel(GroceryAisle aisle) => switch (aisle) {
  GroceryAisle.produce => t.groceryList.aisleProduce,
  GroceryAisle.dairy => t.groceryList.aisleDairy,
  GroceryAisle.bakery => t.groceryList.aisleBakery,
  GroceryAisle.meat => t.groceryList.aisleMeat,
  GroceryAisle.dryGoods => t.groceryList.aisleDryGoods,
  GroceryAisle.frozen => t.groceryList.aisleFrozen,
  GroceryAisle.cleaning => t.groceryList.aisleCleaning,
  GroceryAisle.other => t.groceryList.aisleOther,
};

/// [items] under aisle headings, in walking order.
List<(String, List<GroceryItemEntity>)> aisleGroups(
  List<GroceryItemEntity> items,
) => [
  for (final (aisle, lines) in GroceryAisles.group(items))
    (aisleLabel(aisle), lines),
];

/// The "by aisle" switch over the list; remembered on this device.
class AisleToggle extends StatelessWidget {
  const AisleToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = GroceryViewPrefs.instance;
    return ValueListenableBuilder<bool>(
      valueListenable: prefs.byAisle,
      builder: (context, on, _) => Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Semantics(
          toggled: on,
          button: true,
          child: GestureDetector(
            onTap: () => prefs.setByAisle(!on),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: AppMotion.quick,
              curve: AppMotion.easeOut,
              constraints: const BoxConstraints(minHeight: 40),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.base,
              ),
              decoration: ShapeDecoration(
                color: on ? AppColors.primary : AppColors.surfaceContainerLow,
                shape: StadiumBorder(
                  side: BorderSide(
                    color: on ? AppColors.primary : AppColors.outlineVariant,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.storefront_rounded,
                    size: 16,
                    color: on ? AppColors.onPrimary : AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    t.groceryList.aisleSort,
                    style: AppTextStyles.labelMd.copyWith(
                      color: on ? AppColors.onPrimary : AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Voice entry ───────────────────────────────────────────────────────────

/// The microphone by the add sheet's name field. While the shopper speaks
/// the words show in the field ([onPartial]); when they stop, the sentence
/// is split into products on the device ([onHeard]) — no recording or text
/// leaves the phone beyond what the platform recognizer itself does.
class GroceryMicButton extends StatefulWidget {
  final ValueChanged<String> onPartial;
  final ValueChanged<List<VoiceGroceryItem>> onHeard;

  const GroceryMicButton({
    super.key,
    required this.onPartial,
    required this.onHeard,
  });

  @override
  State<GroceryMicButton> createState() => _GroceryMicButtonState();
}

class _GroceryMicButtonState extends State<GroceryMicButton> {
  /// Made on the first tap, so opening the sheet never touches the mic.
  AssistantVoice? _voice;

  @override
  void dispose() {
    unawaited(_voice?.dispose());
    super.dispose();
  }

  Future<void> _toggle() async {
    if (!guardFeature(context, FeaturesFlags.groceryVoiceAdd)) return;
    final voice = _voice ??= AssistantVoice();
    if (voice.listening.value) return voice.stopListening();
    setState(() {});
    final ok = await voice.listen((words, {required isFinal}) {
      if (!mounted) return;
      if (!isFinal) {
        widget.onPartial(words);
        return;
      }
      final heard = GroceryVoiceParser.parse(words);
      if (heard.isEmpty) {
        AppDialog.warning(message: t.groceryList.voiceNothing).notify(context);
        return;
      }
      widget.onHeard(heard);
    });
    if (!ok && mounted) {
      AppDialog.warning(
        message: t.groceryList.voiceUnavailable,
      ).notify(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget button(bool listening) => IconButton(
      tooltip: t.groceryList.voiceAdd,
      icon: Icon(
        listening ? Icons.stop_circle_rounded : Icons.mic_rounded,
        color: listening ? AppColors.error : AppColors.primary,
      ),
      onPressed: _toggle,
    );
    final voice = _voice;
    if (voice == null) return button(false);
    return ValueListenableBuilder<bool>(
      valueListenable: voice.listening,
      builder: (context, listening, _) => button(listening),
    );
  }
}

/// The products heard, as chips to drop before they are added — the one
/// confirmation, since a recognizer mishearing "bread" as "red" should not
/// land on the list unseen.
class HeardItemsPanel extends StatelessWidget {
  final List<VoiceGroceryItem> items;
  final ValueChanged<int> onRemove;
  final VoidCallback onAdd;
  final String Function(VoiceGroceryItem item) describe;

  const HeardItemsPanel({
    super.key,
    required this.items,
    required this.onRemove,
    required this.onAdd,
    required this.describe,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          t.groceryList.voiceHeard(count: items.length),
          style: AppTextStyles.labelMd.copyWith(color: AppColors.outline),
        ),
        const SizedBox(height: AppSpacing.base),
        Wrap(
          spacing: AppSpacing.base,
          runSpacing: AppSpacing.base,
          children: [
            for (var i = 0; i < items.length; i++)
              InputChip(
                label: Text(describe(items[i])),
                onDeleted: () => onRemove(i),
                deleteButtonTooltipMessage: t.common.delete,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.gutter),
        ClayButton(
          label: t.groceryList.voiceAddAll(count: items.length),
          icon: Icons.add_rounded,
          expanded: true,
          onPressed: items.isEmpty ? null : onAdd,
        ),
      ],
    );
  }
}
