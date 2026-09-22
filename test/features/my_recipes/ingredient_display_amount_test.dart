import 'package:easy_plate/features/my_recipes/domain/entities/recipe_ingredient_entity.dart';
import 'package:flutter_test/flutter_test.dart';

RecipeIngredientEntity of(double? amount) =>
    RecipeIngredientEntity(name: 'x', amount: amount);

void main() {
  test('whole amounts lose the decimal point', () {
    expect(of(800).displayAmount, '800');
    expect(of(1).displayAmount, '1');
  });

  test('fractions keep what matters, two decimals at most', () {
    expect(of(1.5).displayAmount, '1.5');
    expect(of(0.25).displayAmount, '0.25');
    expect(of(0.333333).displayAmount, '0.33');
    expect(of(2.10).displayAmount, '2.1');
  });

  test('a missing amount is blank', () {
    expect(of(null).displayAmount, '');
  });
}
