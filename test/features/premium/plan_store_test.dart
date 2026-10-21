import 'package:easy_plate/features/premium/domain/plan_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

void main() {
  test('a plan from the other store is not replaced from this one', () {
    expect(
      planReplaceableHere(Store.appStore, TargetPlatform.android),
      isFalse,
    );
    expect(planReplaceableHere(Store.playStore, TargetPlatform.iOS), isFalse);
    expect(planReplaceableHere(Store.stripe, TargetPlatform.android), isFalse);
  });

  test('the same store, or an unknown one, keeps the replacement', () {
    expect(
      planReplaceableHere(Store.playStore, TargetPlatform.android),
      isTrue,
    );
    expect(planReplaceableHere(Store.appStore, TargetPlatform.iOS), isTrue);
    expect(planReplaceableHere(null, TargetPlatform.android), isTrue);
  });
}
