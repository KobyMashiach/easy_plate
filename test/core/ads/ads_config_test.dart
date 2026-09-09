import 'package:easy_plate/core/constants/ads_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('debug builds serve test ads unless a define says otherwise', () {
    expect(AdsConfig.resolveUseTestAds('', debug: true), isTrue);
    expect(AdsConfig.resolveUseTestAds('', debug: false), isFalse);
    expect(AdsConfig.resolveUseTestAds('false', debug: true), isFalse);
    expect(AdsConfig.resolveUseTestAds('true', debug: false), isTrue);
  });

  test('a blank unit id falls back to the test unit rather than an empty string', () {
    expect(
      AdsConfig.resolveUnit(configured: '', test: 'test-unit', useTest: false),
      'test-unit',
    );
    expect(
      AdsConfig.resolveUnit(configured: '   ', test: 'test-unit', useTest: false),
      'test-unit',
    );
  });

  test('a configured unit is used in release, and ignored when test ads are forced', () {
    expect(
      AdsConfig.resolveUnit(configured: ' real-unit ', test: 'test-unit', useTest: false),
      'real-unit',
    );
    expect(
      AdsConfig.resolveUnit(configured: 'real-unit', test: 'test-unit', useTest: true),
      'test-unit',
    );
  });

  test('the sample units are Google\'s, not ours', () {
    for (final id in [
      AdsConfig.testNativeAndroid,
      AdsConfig.testNativeIos,
      AdsConfig.testRewardedAndroid,
      AdsConfig.testRewardedIos,
    ]) {
      expect(id, startsWith('ca-app-pub-3940256099942544/'));
    }
  });
}
