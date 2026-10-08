import 'package:easy_plate/core/errors/app_exception.dart';
import 'package:easy_plate/core/network/image_search_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a page is read from the function body, bad items dropped', () {
    final page = WebImagePage.fromJson({
      'items': [
        {
          'url': 'https://a/1.jpg',
          'thumbnail': 'https://t/1',
          'width': 800,
          'height': 600,
          'title': 'one',
          'source': 'a',
        },
        {'url': '', 'thumbnail': 'https://t/2'},
        {'url': 'https://a/3.png'},
        'junk',
      ],
      'nextStart': 11,
    });
    expect(page.items.length, 2);
    expect(page.items[0].thumbnail, 'https://t/1');
    expect(page.items[0].width, 800);
    // No thumbnail: the picture itself stands in.
    expect(page.items[1].thumbnail, 'https://a/3.png');
    expect(page.items[1].title, '');
    expect(page.nextStart, 11);
    expect(page.hasMore, isTrue);
  });

  test('the last page has no next', () {
    final page = WebImagePage.fromJson({'items': [], 'nextStart': null});
    expect(page.items, isEmpty);
    expect(page.hasMore, isFalse);
  });

  test('the server saying "not configured" is told apart from a blip', () {
    expect(
      isImageSearchUnavailable(
        const AppException(
          AppErrorType.overloaded,
          message: '{error: {code: not_configured, message: x}}',
        ),
      ),
      isTrue,
    );
    expect(
      isImageSearchUnavailable(
        const AppException(AppErrorType.overloaded, message: 'HTTP 503'),
      ),
      isFalse,
    );
    expect(
      isImageSearchUnavailable(
        const AppException(
          AppErrorType.networkError,
          message: 'not_configured',
        ),
      ),
      isFalse,
    );
  });
}
