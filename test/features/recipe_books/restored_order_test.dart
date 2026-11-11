import 'package:easy_plate/features/recipe_books/presentation/bloc/book_viewer_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a removed recipe goes back to its old place', () {
    expect(
      restoredOrder(
        before: ['a', 'b', 'c', 'd'],
        current: ['a', 'c', 'd'],
        removed: {'b'},
      ),
      ['a', 'b', 'c', 'd'],
    );
  });

  test('several removed ones, and one added meanwhile stays at the end', () {
    expect(
      restoredOrder(
        before: ['a', 'b', 'c', 'd'],
        current: ['c', 'e'],
        removed: {'a', 'b'},
      ),
      ['a', 'b', 'c', 'e'],
    );
  });

  test('a recipe removed elsewhere and not undone stays out', () {
    expect(
      restoredOrder(
        before: ['a', 'b', 'c'],
        current: ['a'],
        removed: {'b'},
      ),
      ['a', 'b'],
    );
  });
}
