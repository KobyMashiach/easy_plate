import 'dart:io';

import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/services/share_intent_service.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/entities/ingestion_file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

void main() {
  group('channelForText', () {
    test('a video platform link is a video', () {
      expect(
        IngestionLaunch.channelForText('https://www.tiktok.com/@x/video/1'),
        RecipeIngestionChannel.socialVideo,
      );
      expect(
        IngestionLaunch.channelForText('https://youtu.be/abc'),
        RecipeIngestionChannel.socialVideo,
      );
    });

    test('any other link is a page', () {
      expect(
        IngestionLaunch.channelForText('https://example.com/recipe'),
        RecipeIngestionChannel.urlScrape,
      );
    });

    test('plain text is pasted text', () {
      expect(
        IngestionLaunch.channelForText('2 cups flour\n1 egg'),
        RecipeIngestionChannel.rawText,
      );
    });
  });

  group('mimeTypeFor', () {
    test('knows the recording and PDF formats, and nothing else', () {
      expect(IngestionFile.mimeTypeFor('note.M4A'), 'audio/aac');
      expect(IngestionFile.mimeTypeFor('voice.opus'), 'audio/opus');
      expect(IngestionFile.mimeTypeFor('book.pdf'), 'application/pdf');
      expect(IngestionFile.mimeTypeFor('photo.jpg'), isNull);
    });
  });

  group('launchFor', () {
    test('shared text lands on the matching text channel, filled in', () async {
      final launch = await ShareIntentService.launchFor([
        SharedMediaFile(
          path: 'https://www.instagram.com/reel/abc/',
          type: SharedMediaType.url,
        ),
      ]);
      expect(launch?.channel, RecipeIngestionChannel.socialVideo);
      expect(launch?.text, 'https://www.instagram.com/reel/abc/');
      expect(launch?.files, isEmpty);
    });

    test('a photo is not something the model reads', () async {
      final launch = await ShareIntentService.launchFor([
        SharedMediaFile(
          path: '/tmp/photo.jpg',
          type: SharedMediaType.image,
          mimeType: 'image/jpeg',
        ),
      ]);
      expect(launch, isNull);
    });

    test('several recordings arrive as the parts of one recipe', () async {
      final dir = await Directory.systemTemp.createTemp('share');
      final a = File('${dir.path}/part1.m4a')..writeAsBytesSync([1, 2, 3]);
      final b = File('${dir.path}/part2.opus')..writeAsBytesSync([4, 5]);
      final launch = await ShareIntentService.launchFor([
        SharedMediaFile(path: a.path, type: SharedMediaType.file),
        SharedMediaFile(
          path: '${dir.path}/photo.jpg',
          type: SharedMediaType.file,
        ),
        SharedMediaFile(path: b.path, type: SharedMediaType.file),
      ]);
      expect(launch?.channel, RecipeIngestionChannel.file);
      expect(launch?.files.map((f) => f.name), ['part1.m4a', 'part2.opus']);
      expect(launch?.files.first.mimeType, 'audio/aac');
      await dir.delete(recursive: true);
    });

    test('a missing file is ignored', () async {
      final launch = await ShareIntentService.launchFor([
        SharedMediaFile(
          path: '/nowhere/recipe.m4a',
          type: SharedMediaType.file,
          mimeType: 'audio/x-m4a',
        ),
      ]);
      expect(launch, isNull);
    });
  });
}
