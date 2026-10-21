import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/grocery_list/domain/entities/grocery_list_entity.dart';
import 'package:easy_plate/features/settings/presentation/pages/home_widgets_page.dart';
import 'package:flutter_test/flutter_test.dart';

GroceryListEntity _list(String id, DateTime at, {CollabRole? role}) =>
    GroceryListEntity(
      id: id,
      name: id,
      items: const [],
      createdAt: at,
      collabId: role == null ? null : 'c-$id',
      collabRole: role,
    );

void main() {
  test('the widget picker offers only lists this account may write to', () {
    final choices = widgetListChoices([
      _list('shared-editor', DateTime(2026, 3), role: CollabRole.editor),
      _list('own', DateTime(2026, 1)),
      _list('view-only', DateTime(2026, 2), role: CollabRole.viewer),
      _list('owned-shared', DateTime(2026, 4), role: CollabRole.owner),
    ]);
    expect(choices.map((l) => l.id), [
      'own',
      'shared-editor',
      'owned-shared',
    ]);
  });
}
