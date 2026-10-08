import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/collab_containers/domain/container_adapter.dart';
import 'package:easy_plate/features/collab_containers/domain/entities/collab_container_entity.dart';
import 'package:easy_plate/features/grocery_list/domain/entities/grocery_item_entity.dart';
import 'package:easy_plate/features/grocery_list/domain/entities/grocery_item_source_entity.dart';
import 'package:easy_plate/features/grocery_list/domain/entities/grocery_list_entity.dart';
import 'package:easy_plate/features/grocery_list/domain/repositories/grocery_lists_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _Lists implements GroceryListsRepository {
  final Map<String, GroceryListEntity> stored = {};
  @override
  Future<List<GroceryListEntity>> getLists() async => stored.values.toList();
  @override
  Stream<List<GroceryListEntity>> watchLists() => const Stream.empty();
  @override
  Future<GroceryListEntity?> getListById(String id) async => stored[id];
  @override
  Future<void> saveList(
    GroceryListEntity list, {
    bool stampLanguage = true,
  }) async => stored[list.id] = list;
  @override
  Future<void> deleteList(String id) async => stored.remove(id);
}

void main() {
  const owner = 'owner';
  const friend = 'friend';

  GroceryListEntity sample() => GroceryListEntity(
    id: 'l',
    name: 'Shabbat',
    items: const [
      GroceryItemEntity(
        id: 'a',
        name: 'Tomatoes',
        unit: MeasurementUnit.gram,
        category: 'produce',
        isChecked: true,
        sources: [
          GroceryItemSourceEntity(
            label: 'Shakshuka',
            amount: 1.5,
            recipeId: 'r1',
          ),
          GroceryItemSourceEntity(label: 'extra', amount: 0.5),
        ],
      ),
      GroceryItemEntity(
        id: 'b',
        name: 'Bread',
        unit: MeasurementUnit.unspecified,
        category: '',
        isAdHoc: true,
        sources: [GroceryItemSourceEntity(label: '', amount: 1)],
      ),
    ],
    createdAt: DateTime(2026),
    source: GroceryListSource.plans,
    selectedPlanIds: const ['p1'],
  );

  test('the adapter links no recipes: lines travel as written', () {
    final adapter = GroceryListContainerAdapter(_Lists());
    expect(adapter.kind, CollabKind.groceryList);
    expect(adapter.recipeIdsOf(sample()), isEmpty);
    expect(adapter.titleOf(sample()), 'Shabbat');
    expect(adapter.isMine(sample()), isTrue);
  });

  test('the owner round-trips with amounts, ticks and the source kept', () {
    final adapter = GroceryListContainerAdapter(_Lists());
    final list = sample().copyWith(collabId: 'c', collabRole: CollabRole.owner);
    final content = adapter.encode(
      list,
      collabIdByRecipeId: const {},
      titles: const {},
    );
    // No recipe ids leave the device: a line's source is a label.
    expect(content.toString(), isNot(contains('r1')));
    final container = CollabContainerEntity(
      id: 'c',
      kind: CollabKind.groceryList,
      ownerUid: owner,
      members: const {friend: CollabRole.editor},
      title: 'Shabbat',
      content: content,
      updatedAt: DateTime(2026),
    );
    final back = adapter.decode(
      container,
      local: list,
      recipeIdByCollabId: const {},
      uid: owner,
    );
    expect(back.id, 'l');
    expect(back.items.length, 2);
    expect(back.items[0].name, 'Tomatoes');
    expect(back.items[0].unit, MeasurementUnit.gram);
    expect(back.items[0].isChecked, isTrue);
    expect(back.items[0].totalAmount, 2.0);
    expect(back.items[0].sources[0].label, 'Shakshuka');
    expect(back.items[1].isAdHoc, isTrue);
    expect(back.collabRole, CollabRole.owner);
    // The owner's copy still knows what it was built from.
    expect(back.source, GroceryListSource.plans);
    expect(back.selectedPlanIds, ['p1']);
  });

  test('a member gets a hand-made copy with their role', () {
    final adapter = GroceryListContainerAdapter(_Lists());
    final content = adapter.encode(
      sample(),
      collabIdByRecipeId: const {},
      titles: const {},
    );
    final container = CollabContainerEntity(
      id: 'c',
      kind: CollabKind.groceryList,
      ownerUid: owner,
      members: const {friend: CollabRole.viewer},
      title: 'Shabbat',
      content: content,
      updatedAt: DateTime(2026),
    );
    final copy = adapter.decode(
      container,
      local: null,
      recipeIdByCollabId: const {},
      uid: friend,
    );
    expect(copy.name, 'Shabbat');
    expect(copy.items.length, 2);
    expect(copy.collabId, 'c');
    expect(copy.collabRole, CollabRole.viewer);
    expect(copy.canEdit, isFalse);
    expect(copy.isMine, isFalse);
    expect(copy.isShared, isTrue);
    // The plans it came from are the owner's: nothing to rebuild from here.
    expect(copy.source, GroceryListSource.manual);
    expect(copy.canRegenerate, isFalse);
    expect(copy.selectedPlanIds, isEmpty);
  });

  test('clearing the collab turns the copy back into a private list', () {
    final shared = sample().copyWith(
      collabId: 'c',
      collabRole: CollabRole.editor,
    );
    final orphaned = GroceryListContainerAdapter(
      _Lists(),
    ).withoutCollab(shared);
    expect(orphaned.isShared, isFalse);
    expect(orphaned.collabRole, isNull);
    expect(orphaned.canEdit, isTrue);
    // copyWith without the flag keeps what was there.
    expect(shared.copyWith(name: 'x').collabId, 'c');
  });
}
