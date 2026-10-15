import 'package:easy_plate/core/monetization/purchases_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the current package is recognised however the store names it', () {
    // Google Play: one subscription, two base plans.
    const monthly = ActivePlan(productId: 'pro', basePlan: 'monthly');
    expect(monthly.matches('pro:monthly'), isTrue);
    expect(monthly.matches('pro:yearly'), isFalse);
    expect(monthly.matches('pro_duo:monthly'), isFalse);
    expect(monthly.subscriptionId, 'pro');

    // RevenueCat sometimes reports the base plan inside the id.
    const glued = ActivePlan(productId: 'pro:yearly');
    expect(glued.matches('pro:yearly'), isTrue);
    expect(glued.matches('pro:monthly'), isFalse);
    expect(glued.subscriptionId, 'pro');

    // App Store: plain product ids.
    const ios = ActivePlan(productId: 'easyplate.pro.monthly');
    expect(ios.matches('easyplate.pro.monthly'), isTrue);
    expect(ios.matches('easyplate.family.monthly'), isFalse);
  });
}
