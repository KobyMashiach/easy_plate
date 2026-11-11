import 'package:easy_plate/core/constants/app_constants.dart';
import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/grocery_list/domain/entities/grocery_item_entity.dart';
import 'package:easy_plate/features/grocery_list/domain/grocery_aisles.dart';
import 'package:flutter_test/flutter_test.dart';

GroceryItemEntity line(
  String name, {
  String category = kDefaultGroceryCategory,
}) => GroceryItemEntity(
  id: name,
  name: name,
  unit: MeasurementUnit.unit,
  sources: const [],
  category: category,
);

void main() {
  GroceryAisle c(String name) => GroceryAisles.classify(name);

  test('English', () {
    expect(c('Tomatoes'), GroceryAisle.produce);
    expect(c('milk'), GroceryAisle.dairy);
    expect(c('whole wheat bread'), GroceryAisle.bakery);
    expect(c('chicken breast'), GroceryAisle.meat);
    expect(c('basmati rice'), GroceryAisle.dryGoods);
    expect(c('frozen peas'), GroceryAisle.frozen);
    expect(c('dish soap'), GroceryAisle.cleaning);
    expect(c('peanut butter'), GroceryAisle.dryGoods);
    expect(c('batteries'), GroceryAisle.other);
  });

  test('Hebrew, with the ה / ו prefixes', () {
    expect(c('עגבניות'), GroceryAisle.produce);
    expect(c('תפוחי אדמה'), GroceryAisle.produce);
    expect(c('חלב 3%'), GroceryAisle.dairy);
    expect(c('גבינה צהובה'), GroceryAisle.dairy);
    expect(c('פיתות'), GroceryAisle.bakery);
    expect(c('חזה עוף'), GroceryAisle.meat);
    expect(c('בשר טחון'), GroceryAisle.meat);
    expect(c('אורז'), GroceryAisle.dryGoods);
    expect(c('שעועית ירוקה קפואה'), GroceryAisle.frozen);
    expect(c('נוזל כלים'), GroceryAisle.cleaning);
    expect(c('החלב'), GroceryAisle.dairy);
    expect(c('חלבון'), isNot(GroceryAisle.dairy));
  });

  test('French', () {
    expect(c('tomates'), GroceryAisle.produce);
    expect(c('laitue'), GroceryAisle.produce);
    expect(c('lait'), GroceryAisle.dairy);
    expect(c('baguette'), GroceryAisle.bakery);
    expect(c('poulet'), GroceryAisle.meat);
    expect(c('pâtes'), GroceryAisle.dryGoods);
    expect(c('glace vanille'), GroceryAisle.frozen);
    expect(c('lessive'), GroceryAisle.cleaning);
  });

  test('Russian', () {
    expect(c('огурцы'), GroceryAisle.produce);
    expect(c('молоко'), GroceryAisle.dairy);
    expect(c('хлеб'), GroceryAisle.bakery);
    expect(c('куриное филе'), GroceryAisle.meat);
    expect(c('гречка'), GroceryAisle.dryGoods);
    expect(c('пельмени'), GroceryAisle.frozen);
    expect(c('мыло'), GroceryAisle.cleaning);
  });

  test('Arabic, with the ال prefix', () {
    expect(c('طماطم'), GroceryAisle.produce);
    expect(c('الحليب'), GroceryAisle.dairy);
    expect(c('خبز'), GroceryAisle.bakery);
    expect(c('دجاج'), GroceryAisle.meat);
    expect(c('أرز'), GroceryAisle.dryGoods);
    expect(c('خضار مجمدة'), GroceryAisle.frozen);
    expect(c('صابون'), GroceryAisle.cleaning);
  });

  test('a stored aisle category wins over the name', () {
    expect(
      GroceryAisles.of(line('milk', category: 'cleaning')),
      GroceryAisle.cleaning,
    );
    expect(GroceryAisles.of(line('milk')), GroceryAisle.dairy);
  });

  test('group keeps walking order and the list order inside an aisle', () {
    final groups = GroceryAisles.group([
      line('soap'),
      line('milk'),
      line('apples'),
      line('cheese'),
      line('batteries'),
    ]);
    expect(groups.map((g) => g.$1), [
      GroceryAisle.produce,
      GroceryAisle.dairy,
      GroceryAisle.cleaning,
      GroceryAisle.other,
    ]);
    expect(groups[1].$2.map((i) => i.name), ['milk', 'cheese']);
  });
}
