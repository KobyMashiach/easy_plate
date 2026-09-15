import 'package:easy_plate/core/constants/purchases_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('picks the key for the platform', () {
    expect(PurchasesConfig.resolveKey(android: 'goog_a', ios: 'appl_i', isIos: false), 'goog_a');
    expect(PurchasesConfig.resolveKey(android: 'goog_a', ios: 'appl_i', isIos: true), 'appl_i');
  });

  test('a blank or whitespace key reads as none', () {
    expect(PurchasesConfig.resolveKey(android: '  ', ios: '', isIos: false), isEmpty);
    expect(PurchasesConfig.resolveKey(android: 'goog_a', ios: '', isIos: true), isEmpty);
  });

  test('the entitlement id is the one the webhook writes for', () {
    // Changing this means changing functions/revenueCatWebhook.js and the
    // RevenueCat dashboard together.
    expect(PurchasesConfig.premiumEntitlementId, 'easy_plate_ai_pro');
  });
}
