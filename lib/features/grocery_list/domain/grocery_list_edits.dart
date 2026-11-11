import '../../../core/constants/app_constants.dart';
import 'entities/grocery_item_entity.dart';
import 'entities/grocery_item_source_entity.dart';
import 'entities/grocery_list_entity.dart';
import 'grocery_voice_parser.dart';

/// Changes to a list that come with an undo, each written so it can be made
/// on the list as stored at the moment of the write — another device may
/// have touched it since the screen read it — and taken back without
/// disturbing what that device did.
class GroceryListEdits {
  const GroceryListEdits._();

  /// Ticks the lines [ids] ("bought everything").
  static GroceryListEntity check(GroceryListEntity list, Set<String> ids) =>
      _setChecked(list, ids, true);

  /// Unticks the lines [ids] — the undo of [check], so a line that was
  /// already ticked before stays ticked.
  static GroceryListEntity uncheck(GroceryListEntity list, Set<String> ids) =>
      _setChecked(list, ids, false);

  static GroceryListEntity _setChecked(
    GroceryListEntity list,
    Set<String> ids,
    bool checked,
  ) => list.copyWith(
    items: [
      for (final item in list.items)
        ids.contains(item.id) && item.isChecked != checked
            ? item.copyWith(isChecked: checked)
            : item,
    ],
  );

  /// Puts removed lines back where they were, by their position in the list
  /// they were removed from. A line that is back already (restored on
  /// another device, rebuilt from the plans) is not doubled.
  static GroceryListEntity restore(
    GroceryListEntity list,
    List<(int, GroceryItemEntity)> removed,
  ) {
    final present = {for (final i in list.items) i.id};
    final items = [...list.items];
    final sorted = [...removed]..sort((a, b) => a.$1.compareTo(b.$1));
    for (final (index, item) in sorted) {
      if (present.contains(item.id)) continue;
      items.insert(index.clamp(0, items.length), item);
      present.add(item.id);
    }
    return list.copyWith(items: items);
  }

  /// The lines [list] holds that [test] picks, with their positions, for
  /// [restore].
  static List<(int, GroceryItemEntity)> positionsOf(
    GroceryListEntity list,
    bool Function(GroceryItemEntity item) test,
  ) => [
    for (var i = 0; i < list.items.length; i++)
      if (test(list.items[i])) (i, list.items[i]),
  ];

  /// Hand-added lines for [heard], shaped exactly like the add sheet's: a
  /// single manual source carries the amount, so each opens the same
  /// breakdown sheet as any other line.
  static List<GroceryItemEntity> adHocLines(
    List<VoiceGroceryItem> heard, {
    required String Function() newId,
  }) => [
    for (final item in heard)
      GroceryItemEntity(
        id: newId(),
        name: item.name,
        unit: item.unit,
        sources: [
          GroceryItemSourceEntity(label: item.name, amount: item.amount),
        ],
        category: kDefaultGroceryCategory,
        isAdHoc: true,
      ),
  ];

  static GroceryListEntity add(
    GroceryListEntity list,
    List<GroceryItemEntity> lines,
  ) {
    final present = {for (final i in list.items) i.id};
    return list.copyWith(
      items: [
        ...list.items,
        for (final line in lines)
          if (!present.contains(line.id)) line,
      ],
    );
  }
}
