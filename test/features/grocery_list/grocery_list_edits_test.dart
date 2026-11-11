import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/grocery_list/domain/entities/grocery_item_entity.dart';
import 'package:easy_plate/features/grocery_list/domain/entities/grocery_list_entity.dart';
import 'package:easy_plate/features/grocery_list/domain/grocery_list_edits.dart';
import 'package:easy_plate/features/grocery_list/domain/grocery_voice_parser.dart';
import 'package:flutter_test/flutter_test.dart';

GroceryItemEntity line(String id, {bool checked = false}) => GroceryItemEntity(
  id: id,
  name: id,
  unit: MeasurementUnit.unit,
  sources: const [],
  category: 'x',
  isChecked: checked,
);

GroceryListEntity listOf(List<GroceryItemEntity> items) => GroceryListEntity(
  id: 'l',
  name: 'L',
  items: items,
  createdAt: DateTime(2026),
);

void main() {
  test('check then uncheck leaves lines that were already ticked', () {
    final list = listOf([line('a'), line('b', checked: true), line('c')]);
    final ids = {
      for (final i in list.items)
        if (!i.isChecked) i.id,
    };
    final all = GroceryListEdits.check(list, ids);
    expect(all.items.every((i) => i.isChecked), isTrue);
    final undone = GroceryListEdits.uncheck(all, ids);
    expect(undone.items.map((i) => i.isChecked), [false, true, false]);
  });

  test('restore puts removed lines back in place, never twice', () {
    final list = listOf([line('a'), line('b'), line('c'), line('d')]);
    final removed = GroceryListEdits.positionsOf(
      list,
      (i) => i.id == 'b' || i.id == 'd',
    );
    final after = listOf([line('a'), line('c'), line('e')]);
    final back = GroceryListEdits.restore(after, removed);
    expect(back.items.map((i) => i.id), ['a', 'b', 'c', 'd', 'e']);
    expect(
      GroceryListEdits.restore(back, removed).items.map((i) => i.id),
      ['a', 'b', 'c', 'd', 'e'],
    );
  });

  test('heard items become hand-added lines with their amount', () {
    var n = 0;
    final lines = GroceryListEdits.adHocLines(const [
      VoiceGroceryItem(name: 'milk', amount: 2, unit: MeasurementUnit.liter),
    ], newId: () => 'id${n++}');
    expect(lines.single.isAdHoc, isTrue);
    expect(lines.single.totalAmount, 2);
    expect(lines.single.unit, MeasurementUnit.liter);
    final added = GroceryListEdits.add(listOf([line('a')]), lines);
    expect(added.items.map((i) => i.id), ['a', 'id0']);
    expect(GroceryListEdits.add(added, lines).items, hasLength(2));
  });
}
