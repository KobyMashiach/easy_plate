import 'package:easy_plate/features/community/presentation/widgets/author_row.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only our own bucket and Google account photos are loaded', () {
    for (final ok in [
      'https://firebasestorage.googleapis.com/v0/b/easy-plate.firebasestorage.app/o/profile_photos%2Fu.jpg?alt=media',
      'https://firebasestorage.googleapis.com/v0/b/easy-plate.appspot.com/o/profile_photos%2Fu.jpg?alt=media&token=t',
      'https://storage.googleapis.com/easy-plate.firebasestorage.app/profile_photos/u.jpg',
      'https://storage.googleapis.com/easy-plate.appspot.com/profile_photos/u.jpg',
      'https://lh3.googleusercontent.com/a/abc=s96-c',
      'https://lh6.googleusercontent.com/-x/photo.jpg',
    ]) {
      expect(AuthorRow.trustedPhotoUrl(ok), isTrue, reason: ok);
    }
    for (final bad in [
      null,
      '',
      'not a url',
      'http://firebasestorage.googleapis.com/v0/b/easy-plate.appspot.com/o/x',
      'https://evil.example/huge.jpg',
      'https://firebasestorage.googleapis.com.evil.example/x',
      'https://evilgoogleusercontent.com/x',
      // Another project's bucket: its owner reads the access logs.
      'https://firebasestorage.googleapis.com/v0/b/app/o/profile_photos%2Fu.jpg',
      'https://storage.googleapis.com/someone-else/u.jpg',
      'https://storage.googleapis.com/easy-plate.appspot.com.evil/u.jpg',
      'https://firebasestorage.googleapis.com/v0/b/easy-plate.appspot.comx/o/u',
      // A live server on googleusercontent (a Colab proxy), not a photo.
      'https://abc-dot-colab.googleusercontent.com/x',
      'https://googleusercontent.com/x',
      'https://lh3.googleusercontent.com.evil.example/x',
      'https://lh3.googleusercontent.com@evil.example/x',
      'https://lh3.googleusercontent.com:8443/x',
      'https://lh3.googleusercontent.com/${'a' * 2100}',
    ]) {
      expect(AuthorRow.trustedPhotoUrl(bad), isFalse, reason: '$bad');
    }
  });
}
