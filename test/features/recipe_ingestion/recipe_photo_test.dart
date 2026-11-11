import 'dart:typed_data';

import 'package:easy_plate/features/recipe_ingestion/data/datasources/recipe_ai_datasource.dart';
import 'package:easy_plate/features/recipe_ingestion/data/recipe_image_shrinker.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/entities/ingestion_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

IngestionFile _file(String mime) =>
    IngestionFile(name: 'x', bytes: Uint8List(1), mimeType: mime);

/// A noisy picture, so the encoders cannot squeeze it to nothing.
img.Image _noisy(int width, int height) {
  final image = img.Image(width: width, height: height);
  var seed = 7;
  for (final p in image) {
    seed = (seed * 1103515245 + 12345) & 0x7fffffff;
    p
      ..r = seed & 0xff
      ..g = (seed >> 8) & 0xff
      ..b = (seed >> 16) & 0xff;
  }
  return image;
}

void main() {
  group('IngestionFile images', () {
    test('mimeTypeFor ignores pictures unless asked', () {
      expect(IngestionFile.mimeTypeFor('page.jpg'), isNull);
      expect(IngestionFile.mimeTypeFor('page.JPG', images: true), 'image/jpeg');
      expect(IngestionFile.mimeTypeFor('shot.png', images: true), 'image/png');
      expect(IngestionFile.mimeTypeFor('a.heic', images: true), 'image/heic');
      expect(IngestionFile.mimeTypeFor('a.webp', images: true), 'image/webp');
      expect(IngestionFile.mimeTypeFor('a.gif', images: true), isNull);
      // Audio and PDF are unchanged either way.
      expect(
        IngestionFile.mimeTypeFor('b.pdf', images: true),
        'application/pdf',
      );
      expect(IngestionFile.mimeTypeFor('v.opus', images: true), 'audio/opus');
    });

    test('readableImageType normalises and refuses', () {
      expect(IngestionFile.readableImageType('image/JPG'), 'image/jpeg');
      expect(IngestionFile.readableImageType('image/png'), 'image/png');
      expect(IngestionFile.readableImageType('image/gif'), isNull);
      expect(IngestionFile.readableImageType('image/svg+xml'), isNull);
    });

    test('isImage and isSupported', () {
      expect(_file('image/jpeg').isImage, isTrue);
      expect(_file('image/jpeg').isSupported, isTrue);
      expect(_file('audio/aac').isImage, isFalse);
      expect(_file('video/mp4').isSupported, isFalse);
    });
  });

  group('RecipeImageShrinker', () {
    test('a large picture comes back as a JPEG within the long side', () {
      final png = Uint8List.fromList(img.encodePng(_noisy(1200, 3000)));
      final out = RecipeImageShrinker.shrinkBytes(png);
      expect(out, isNotNull);
      expect(out!.length, lessThan(png.length));
      final decoded = img.decodeJpg(out)!;
      expect(decoded.height, RecipeImageShrinker.maxSide);
      expect(decoded.width, 800);
    });

    test('an undecodable format is left alone', () {
      expect(
        RecipeImageShrinker.shrinkBytes(Uint8List.fromList(List.filled(64, 3))),
        isNull,
      );
    });

    test('small pictures and other files pass through untouched', () async {
      final small = IngestionFile(
        name: 'a.png',
        bytes: Uint8List(100),
        mimeType: 'image/png',
      );
      expect(identical(await RecipeImageShrinker.shrink(small), small), isTrue);
      final audio = IngestionFile(
        name: 'a.m4a',
        bytes: Uint8List(RecipeImageShrinker.keepBelowBytes + 1),
        mimeType: 'audio/aac',
      );
      expect(identical(await RecipeImageShrinker.shrink(audio), audio), isTrue);
    });

    test('jpegName swaps the extension', () {
      expect(RecipeImageShrinker.jpegName('IMG_1.HEIC'), 'IMG_1.jpg');
      expect(RecipeImageShrinker.jpegName('shot'), 'shot.jpg');
      expect(RecipeImageShrinker.jpegName('.hidden'), '.hidden.jpg');
    });
  });

  group('filesPromptWithImages', () {
    test('one photo is read as one recipe, handwriting included', () {
      final prompt = filesPromptWithImages([_file('image/jpeg')]);
      expect(prompt, contains('כתב יד'));
      expect(prompt, contains('התמונה המצורפת'));
    });

    test('several photos are the pages of one recipe', () {
      final prompt = filesPromptWithImages([
        _file('image/jpeg'),
        _file('image/jpeg'),
      ]);
      expect(prompt, contains('(2)'));
      expect(prompt, contains('מתכון אחד'));
      expect(prompt, contains('חפיפה'));
    });

    test('a photo with a recording is one recipe in parts', () {
      final prompt = filesPromptWithImages([
        _file('image/png'),
        _file('audio/aac'),
      ]);
      expect(prompt, contains('הקבצים המצורפים'));
      expect(prompt, contains('הקלטות'));
    });
  });
}
