import 'package:easy_plate/core/constants/legal_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the legal pages follow the app language, English without a prefix', () {
    expect(
      LegalLinks.localizedFor('privacy', 'he').toString(),
      'https://aieasyplate.app/he/privacy',
    );
    expect(
      LegalLinks.localizedFor('terms', 'ar').toString(),
      'https://aieasyplate.app/ar/terms',
    );
    expect(
      LegalLinks.localizedFor('terms', 'fr').toString(),
      'https://aieasyplate.app/fr/terms',
    );
    expect(
      LegalLinks.localizedFor('privacy', 'ru').toString(),
      'https://aieasyplate.app/ru/privacy',
    );
    expect(
      LegalLinks.localizedFor('privacy', 'en').toString(),
      'https://aieasyplate.app/privacy',
    );
    // An unknown language falls back to the English page rather than a 404.
    expect(
      LegalLinks.localizedFor('terms', 'de').toString(),
      'https://aieasyplate.app/terms',
    );
  });
}
