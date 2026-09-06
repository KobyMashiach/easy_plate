import 'package:easy_plate/core/hive/user_scope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() => UserScope().resetForTest());

  test('opening before a user resolves throws instead of falling back', () async {
    // A silent fallback to an unscoped box is precisely the bug this prevents:
    // it is how one account's recipes became visible to the next.
    expect(() => UserScope().open<String>('recipesBox'), throwsStateError);
  });

  test('every scoped box is listed, so none keeps a device-wide name', () {
    expect(
      UserScope.scopedBoxes,
      containsAll([
        'userPreferencesBox',
        'recipesBox',
        'recipeBooksBox',
        'mealPlansBox',
        'groceryListsBox',
      ]),
    );
  });

  test('switching accounts moves the scope', () async {
    final scope = UserScope();
    await scope.switchTo('user-1');
    expect(scope.uid, 'user-1');

    await scope.switchTo('user-2');
    expect(scope.uid, 'user-2');
  });

  test('switching to the same account is a no-op', () async {
    final scope = UserScope();
    await scope.switchTo('user-1');
    await scope.switchTo('user-1');
    expect(scope.uid, 'user-1');
  });
}
