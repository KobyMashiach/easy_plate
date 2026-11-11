import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/channel_detector.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/entities/ingestion_file.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  RecipeIngestionChannel detect(String text) => ChannelDetector.detect(text);

  group('ChannelDetector', () {
    test('empty text defaults to a web search', () {
      expect(detect('   '), RecipeIngestionChannel.webSearch);
    });

    test('a short dish name is a web search', () {
      expect(detect('מתכון לקובה'), RecipeIngestionChannel.webSearch);
      expect(detect('beet kubbeh'), RecipeIngestionChannel.webSearch);
    });

    test('video platform links are videos', () {
      expect(
        detect('https://www.instagram.com/reel/abc/'),
        RecipeIngestionChannel.socialVideo,
      );
      expect(
        detect('https://vm.tiktok.com/ZMabc/'),
        RecipeIngestionChannel.socialVideo,
      );
      expect(
        detect('https://youtu.be/xyz'),
        RecipeIngestionChannel.socialVideo,
      );
    });

    test('any other link is a page', () {
      expect(
        detect('https://www.10dakot.co.il/recipe/kubbeh'),
        RecipeIngestionChannel.urlScrape,
      );
      expect(detect('www.example.com/r'), RecipeIngestionChannel.urlScrape);
    });

    test('a link inside a short caption keeps its kind', () {
      expect(
        detect('תראי איזה מתכון https://www.tiktok.com/@a/video/1 😍'),
        RecipeIngestionChannel.socialVideo,
      );
    });

    test('a recipe that quotes its source is pasted text', () {
      final recipe = [
        'עוגת שמרים',
        'מצרכים:',
        '3 כוסות קמח',
        '2 ביצים',
        'אופן ההכנה:',
        'מערבבים הכול',
        'מקור: https://example.com/cake',
      ].join('\n');
      expect(detect(recipe), RecipeIngestionChannel.rawText);
    });

    test('several lines or a heading make pasted text', () {
      expect(detect('2 cups flour\n1 egg'), RecipeIngestionChannel.rawText);
      expect(
        detect('Ingredients\nflour, eggs'),
        RecipeIngestionChannel.rawText,
      );
    });

    test('a long single line is pasted text', () {
      expect(detect('א' * 200), RecipeIngestionChannel.rawText);
    });

    test('asking for something to be made up is a request', () {
      expect(
        detect('יש לי עוף ואורז, מה אפשר להכין?'),
        RecipeIngestionChannel.aiRequest,
      );
      expect(
        detect('invent a vegan dessert with dates'),
        RecipeIngestionChannel.aiRequest,
      );
      expect(
        detect('придумай ужин из курицы'),
        RecipeIngestionChannel.aiRequest,
      );
    });
  });

  group('IngestionLaunch.findWebUrl', () {
    test('returns a bare link as is', () {
      expect(
        IngestionLaunch.findWebUrl(' https://a.com/x '),
        'https://a.com/x',
      );
    });

    test('takes the link out of a caption, without trailing punctuation', () {
      expect(
        IngestionLaunch.findWebUrl('look (https://a.com/x).'),
        'https://a.com/x',
      );
    });

    test('adds https to a bare www', () {
      expect(IngestionLaunch.findWebUrl('see www.a.com/x'), 'https://www.a.com/x');
    });

    test('null when there is no link', () {
      expect(IngestionLaunch.findWebUrl('kubbeh'), isNull);
    });
  });
}
