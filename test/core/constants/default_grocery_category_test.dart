import 'package:easy_plate/core/constants/app_constants.dart';
import 'package:easy_plate/features/grocery_list/data/models/grocery_item_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the core default category is the grocery model\'s own default', () {
    const item = GroceryItemModel(id: 'i', name: 'n', sources: []);
    expect(item.category, kDefaultGroceryCategory);
    // A line stored without the field reads back the same way.
    expect(
      GroceryItemModel.fromJson({
        'id': 'i',
        'name': 'n',
        'sources': [],
      }).category,
      kDefaultGroceryCategory,
    );
  });
}
