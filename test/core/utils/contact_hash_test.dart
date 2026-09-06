import 'package:easy_plate/core/utils/contact_hash.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeContact', () {
    test('emails are lower-cased and trimmed', () {
      final c = normalizeContact('  Koby@Example.COM ');
      expect(c?.value, 'koby@example.com');
      expect(c?.isEmail, isTrue);
    });

    test('a local Israeli mobile becomes E.164, like the sign-in form', () {
      expect(normalizeContact('0508247743')?.value, '+972508247743');
      expect(normalizeContact('050-824 7743')?.value, '+972508247743');
      expect(normalizeContact('0508247743')?.isEmail, isFalse);
    });

    test('an international number is kept as given', () {
      expect(normalizeContact('+33612345678')?.value, '+33612345678');
    });

    test('neither an email nor a phone is null, not a guess', () {
      expect(normalizeContact('koby'), isNull);
      expect(normalizeContact('koby@'), isNull);
      expect(normalizeContact('12'), isNull);
      expect(normalizeContact(''), isNull);
    });
  });

  group('contactHash', () {
    test('is deterministic and never the contact itself', () {
      final h = contactHash('koby@example.com');
      expect(h, contactHash('koby@example.com'));
      expect(h, hasLength(64));
      expect(h, isNot(contains('@')));
    });

    test('differs between contacts', () {
      expect(contactHash('a@b.com'), isNot(contactHash('b@a.com')));
    });

    test('the same person keyed by email or by phone is two entries', () {
      // Both hashes point at the same uid in the directory; that is why the
      // profile publishes one entry per verified contact.
      expect(contactHash('koby@example.com'), isNot(contactHash('+972508247743')));
    });
  });
}
