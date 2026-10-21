import 'dart:async';

import 'package:easy_plate/core/ads/ads_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a consent lookup that never calls back gives up', () async {
    final finished = await AdsService.withinConsentTimeout(
      () => Completer<void>().future,
      timeout: const Duration(milliseconds: 20),
    );
    expect(finished, isFalse);
  });

  test('a consent lookup that answers in time goes on to the SDK', () async {
    final finished = await AdsService.withinConsentTimeout(() async {});
    expect(finished, isTrue);
  });
}
