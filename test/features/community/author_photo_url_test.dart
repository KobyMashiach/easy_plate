import 'package:easy_plate/features/community/presentation/widgets/author_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only our bucket and Google account photos are loaded', () {
    for (final ok in [
      'https://firebasestorage.googleapis.com/v0/b/app/o/profile_photos%2Fu.jpg?alt=media',
      'https://storage.googleapis.com/app/profile_photos/u.jpg',
      'https://lh3.googleusercontent.com/a/abc=s96-c',
    ]) {
      expect(AuthorRow.trustedPhotoUrl(ok), isTrue, reason: ok);
    }
    for (final bad in [
      null,
      '',
      'http://firebasestorage.googleapis.com/x',
      'https://evil.example/huge.jpg',
      'https://firebasestorage.googleapis.com.evil.example/x',
      'https://evilgoogleusercontent.com/x',
      'not a url',
    ]) {
      expect(AuthorRow.trustedPhotoUrl(bad), isFalse, reason: '$bad');
    }
  });
}
