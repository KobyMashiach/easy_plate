import 'package:easy_plate/features/my_recipes/domain/entities/recipe_ingredient_entity.dart';
import 'package:flutter_test/flutter_test.dart';

RecipeIngredientEntity line(String name, {double? amount, String? section}) =>
    RecipeIngredientEntity(name: name, amount: amount, section: section);

void main() {
  test('a heading line becomes the section of the lines under it', () {
    final lifted = sectionHeadingsLifted([
      line('מצרכים לבשר:'),
      line('בשר טחון', amount: 500),
      line('בצל', amount: 1),
      line('מצרכים לרוטב'),
      line('רסק עגבניות', amount: 2),
      line('For the topping:'),
      line('cheese', amount: 100),
    ]);
    expect(
      [for (final i in lifted) i.name],
      [
        'בשר טחון',
        'בצל',
        'רסק עגבניות',
        'cheese',
      ],
    );
    expect(
      [for (final i in lifted) i.section],
      [
        'בשר',
        'בשר',
        'רוטב',
        'topping',
      ],
    );
  });

  test('a bare "מצרכים:" heading starts no section and is dropped', () {
    final lifted = sectionHeadingsLifted([
      line('מצרכים:'),
      line('קמח', amount: 2),
    ]);
    expect(lifted.single.name, 'קמח');
    expect(lifted.single.section, isNull);
  });

  test('a real ingredient is never taken for a heading', () {
    expect(isSectionHeading(line('מלח לפי הטעם')), isFalse);
    expect(isSectionHeading(line('for the brave: chili', amount: 1)), isFalse);
    expect(isSectionHeading(line('rice for the bowl')), isFalse);
  });

  test('a section the model gave is kept, a heading only fills the gaps', () {
    final lifted = sectionHeadingsLifted([
      line('לרוטב:'),
      line('שמן', amount: 1, section: 'טיגון'),
      line('שום', amount: 2),
    ]);
    expect([for (final i in lifted) i.section], ['טיגון', 'לרוטב']);
  });

  test('a heading is drawn only where the section changes', () {
    final list = [
      line('a'),
      line('b', section: 'רוטב'),
      line('c', section: 'רוטב'),
      line('d', section: 'בשר'),
    ];
    expect(
      [for (var i = 0; i < list.length; i++) sectionStartingAt(list, i)],
      [
        null,
        'רוטב',
        null,
        'בשר',
      ],
    );
    expect(ingredientSections(list), ['רוטב', 'בשר']);
    expect(ingredientSection('   '), isNull);
  });
}
