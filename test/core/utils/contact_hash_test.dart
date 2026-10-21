import 'package:easy_plate/core/utils/contact_hash.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeContact', () {
    test('emails are lower-cased and trimmed', () {
      final c = normalizeContact('  Koby@Example.COM ');
      expect(c?.value, 'koby@example.com');
      expect(c?.isEmail, isTrue);
    });

    test(
      'a local Israeli mobile becomes E.164 in Hebrew, like the sign-in form',
      () {
        expect(
          normalizeContact('0508247743', israeliLocal: true)?.value,
          '+972508247743',
        );
        expect(
          normalizeContact('050-824 7743', israeliLocal: true)?.value,
          '+972508247743',
        );
        expect(
          normalizeContact('972508247743', israeliLocal: true)?.value,
          '+972508247743',
        );
        expect(
          normalizeContact('0508247743', israeliLocal: true)?.isEmail,
          isFalse,
        );
      },
    );

    test('outside Hebrew a bare number is refused, not guessed Israeli', () {
      // A French 06… used to be looked up as +9726…: a stranger's hash.
      expect(normalizeContact('0612345678', israeliLocal: false), isNull);
      expect(normalizeContact('33612345678', israeliLocal: false), isNull);
      // Bare digits that are not Israeli are refused in Hebrew too.
      expect(normalizeContact('33612345678', israeliLocal: true), isNull);
    });

    test('an E.164 number hashes exactly as before, in every language', () {
      for (final local in [true, false]) {
        final c = normalizeContact('+972508247743', israeliLocal: local);
        expect(c?.value, '+972508247743');
        expect(
          contactHash(c!.value),
          // sha256('+972508247743'), what the directory already holds.
          '3e9674331352560c51f1ca2aa3ba880fa6c7304c37bfc94b415d406cdfd3dd8c',
        );
        expect(
          normalizeContact('+33 6 12-34-56-78', israeliLocal: local)?.value,
          '+33612345678',
        );
      }
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
      expect(
        contactHash('koby@example.com'),
        isNot(contactHash('+972508247743')),
      );
    });
  });
}
