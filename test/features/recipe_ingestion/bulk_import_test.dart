import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:easy_plate/core/constants/app_enums.dart';
import 'package:easy_plate/core/errors/app_exception.dart';
import 'package:easy_plate/core/services/share_intent_service.dart';
import 'package:easy_plate/dev/fake_recipes.dart';
import 'package:easy_plate/features/my_recipes/domain/entities/recipe_entity.dart';
import 'package:easy_plate/features/recipe_ingestion/data/chat_export_reader.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/bulk_import.dart';
import 'package:easy_plate/features/recipe_ingestion/domain/bulk_import_runner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

const _recipe = '''Shakshuka
Ingredients: 4 eggs, 2 tomatoes, 1 onion
Fry the onion, add the tomatoes
Crack the eggs and cover for 5 minutes''';

const _androidChat =
    '12/31/23, 9:41 PM - Messages and calls are end-to-end encrypted. Tap to learn more.\n'
    '12/31/23, 9:42 PM - Dana Levi: look at this https://www.tiktok.com/@chef/video/123 !!\n'
    '12/31/23, 9:43 PM - Moshe: ok see you at 8\n'
    '1/1/24, 10:00 AM - Dana Levi: $_recipe\n'
    '1/1/24, 10:05 AM - Moshe: <Media omitted>\n'
    '1/1/24, 10:06 AM - Moshe: https://example.com/cake. and https://example.com/cake\n';

const _iosChat =
    '\u200e[31/12/2023, 21:41:05] Dana Levi: \u200eMessages and calls are end-to-end encrypted.\n'
    '[31/12/2023, 21:42:10] Dana Levi: https://www.instagram.com/reel/abc/\n'
    '[1/1/2024, 9:00:00\u202fAM] Moshe: \u200eimage omitted\n'
    '[1/1/2024, 9:01:00\u202fAM] Moshe: $_recipe\n';

/// A zip with one entry per [files] entry, stored or deflated.
Uint8List _zip(Map<String, String> files, {bool deflate = true}) {
  final out = BytesBuilder();
  final central = BytesBuilder();
  var count = 0;
  void u16(BytesBuilder b, int v) => b.add([v & 0xff, (v >> 8) & 0xff]);
  void u32(BytesBuilder b, int v) =>
      b.add([v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >> 24) & 0xff]);
  for (final MapEntry(key: name, value: text) in files.entries) {
    final raw = utf8.encode(text);
    final data = deflate ? ZLibEncoder(raw: true).convert(raw) : raw;
    final nameBytes = utf8.encode(name);
    final offset = out.length;
    u32(out, 0x04034b50);
    u16(out, 20);
    u16(out, 0);
    u16(out, deflate ? 8 : 0);
    u32(out, 0); // time + date
    u32(out, 0); // crc, unchecked by the reader
    u32(out, data.length);
    u32(out, raw.length);
    u16(out, nameBytes.length);
    u16(out, 0);
    out.add(nameBytes);
    out.add(data);

    u32(central, 0x02014b50);
    u16(central, 20);
    u16(central, 20);
    u16(central, 0);
    u16(central, deflate ? 8 : 0);
    u32(central, 0);
    u32(central, 0);
    u32(central, data.length);
    u32(central, raw.length);
    u16(central, nameBytes.length);
    u16(central, 0);
    u16(central, 0);
    u16(central, 0);
    u16(central, 0);
    u32(central, 0);
    u32(central, offset);
    central.add(nameBytes);
    count++;
  }
  final cdOffset = out.length;
  final cd = central.toBytes();
  out.add(cd);
  u32(out, 0x06054b50);
  u16(out, 0);
  u16(out, 0);
  u16(out, count);
  u16(out, count);
  u32(out, cd.length);
  u32(out, cdOffset);
  u16(out, 0);
  return out.toBytes();
}

void main() {
  group('linksIn', () {
    test('every distinct link, cleaned, without the app\'s own', () {
      expect(
        BulkImportParser.linksIn(
          'a https://a.com/x, b www.b.com/y! again https://a.com/x '
          'mine https://aieasyplate.app/s/ABC easyplate://open',
        ),
        ['https://a.com/x', 'https://www.b.com/y'],
      );
    });
  });

  group('fromSharedText', () {
    test('one link stays with the single form', () {
      expect(BulkImportParser.fromSharedText('see https://a.com/x'), isNull);
    });

    test('two links become two rows of the right kind', () {
      expect(
        BulkImportParser.fromSharedText(
          'https://a.com/x\nhttps://youtu.be/abc',
        ),
        const [
          BulkCandidate('https://a.com/x', RecipeIngestionChannel.urlScrape),
          BulkCandidate(
            'https://youtu.be/abc',
            RecipeIngestionChannel.socialVideo,
          ),
        ],
      );
    });
  });

  group('chatMessages', () {
    test('Android export: prefixes and system lines gone, lines joined', () {
      final messages = BulkImportParser.chatMessages(_androidChat);
      expect(messages, hasLength(4));
      expect(messages[0], startsWith('look at this https://www.tiktok.com'));
      expect(messages[2], _recipe);
      for (final m in messages) {
        expect(m, isNot(contains('Dana')));
        expect(m, isNot(contains('Moshe')));
        expect(m, isNot(contains('12/31/23')));
      }
    });

    test('iPhone export: brackets, seconds, AM/PM, its own notes dropped', () {
      final messages = BulkImportParser.chatMessages(_iosChat);
      expect(messages, [
        'https://www.instagram.com/reel/abc/',
        _recipe,
      ]);
    });

    test('plain text: a list of links is a message per line', () {
      expect(
        BulkImportParser.chatMessages('https://a.com/1\nhttps://a.com/2'),
        ['https://a.com/1', 'https://a.com/2'],
      );
    });
  });

  group('fromChat', () {
    test('links and recipes, not chat, deduplicated, no names', () {
      final found = BulkImportParser.fromChat(_androidChat);
      expect(found, const [
        BulkCandidate(
          'https://www.tiktok.com/@chef/video/123',
          RecipeIngestionChannel.socialVideo,
        ),
        BulkCandidate(_recipe, RecipeIngestionChannel.rawText),
        BulkCandidate(
          'https://example.com/cake',
          RecipeIngestionChannel.urlScrape,
        ),
      ]);
    });

    test('short chat is not a recipe', () {
      expect(BulkImportParser.looksLikeRecipe('ok see you at 8'), isFalse);
      expect(
        BulkImportParser.looksLikeRecipe('ok see you at 8\nbring wine'),
        isFalse,
      );
      expect(BulkImportParser.looksLikeRecipe(_recipe), isTrue);
    });
  });

  group('ChatExportReader', () {
    test('a plain text export is read as it is', () {
      expect(
        ChatExportReader.textOf(Uint8List.fromList(utf8.encode('שלום'))),
        'שלום',
      );
    });

    test('the chat comes out of a deflated zip, media ignored', () {
      final zip = _zip({
        'IMG-1.jpg': 'not a picture',
        '_chat.txt': _iosChat,
      });
      expect(ChatExportReader.textOf(zip), _iosChat);
    });

    test('a stored zip, and a zip without text', () {
      expect(
        ChatExportReader.textOf(_zip({'notes.txt': 'hi'}, deflate: false)),
        'hi',
      );
      expect(ChatExportReader.textOf(_zip({'a.jpg': 'x'})), isNull);
    });
  });

  group('BulkImportRunner', () {
    const items = [
      BulkCandidate('https://a.com/1', RecipeIngestionChannel.urlScrape),
      BulkCandidate('https://a.com/2', RecipeIngestionChannel.urlScrape),
      BulkCandidate('https://a.com/3', RecipeIngestionChannel.urlScrape),
    ];

    BulkImportRunner runner({
      required Future<bool> Function() gate,
      Future<RecipeEntity> Function(BulkCandidate)? extract,
      List<String>? extracted,
      List<RecipeEntity>? saved,
      bool Function(BulkCandidate)? allowed,
    }) => BulkImportRunner(
      gate: gate,
      extract:
          extract ??
          (c) async {
            extracted?.add(c.text);
            return fakeParsedRecipe(RecipeIngestionChannel.urlScrape);
          },
      save: (r) async => saved?.add(r),
      delivered: () {},
      allowed: allowed ?? (_) => true,
    );

    test('every row is paid for, extracted and saved, in order', () async {
      var paid = 0;
      final extracted = <String>[];
      final saved = <RecipeEntity>[];
      final statuses = <(int, BulkRowStatus)>[];
      final reason = await runner(
        gate: () async => ++paid > 0,
        extracted: extracted,
        saved: saved,
      ).run(items, (i, s) => statuses.add((i, s)));
      expect(reason, BulkStopReason.none);
      expect(paid, 3);
      expect(extracted, [for (final c in items) c.text]);
      expect(saved, hasLength(3));
      expect(statuses.last, (2, BulkRowStatus.done));
    });

    test('the allowance running out stops the run, nothing past it', () async {
      var asked = 0;
      final extracted = <String>[];
      final statuses = <int, BulkRowStatus>{};
      final reason = await runner(
        gate: () async => ++asked == 1,
        extracted: extracted,
      ).run(items, (i, s) => statuses[i] = s);
      expect(reason, BulkStopReason.quota);
      expect(asked, 2);
      expect(extracted, ['https://a.com/1']);
      expect(statuses, {
        0: BulkRowStatus.done,
        1: BulkRowStatus.skipped,
        2: BulkRowStatus.skipped,
      });
    });

    test('a failed row moves on; a server quota refusal stops', () async {
      var n = 0;
      final statuses = <int, BulkRowStatus>{};
      final reason = await runner(
        gate: () async => true,
        extract: (c) async {
          n++;
          if (n == 1) throw Exception('page broke');
          throw const AppException(AppErrorType.quotaExceeded);
        },
      ).run(items, (i, s) => statuses[i] = s);
      expect(reason, BulkStopReason.quota);
      expect(n, 2);
      expect(statuses, {
        0: BulkRowStatus.failed,
        1: BulkRowStatus.failed,
        2: BulkRowStatus.skipped,
      });
    });

    test('a row whose way in is off is skipped without paying', () async {
      var paid = 0;
      final reason = await runner(
        gate: () async => ++paid > 0,
        allowed: (c) => c.text != 'https://a.com/2',
      ).run(items, (_, _) {});
      expect(reason, BulkStopReason.none);
      expect(paid, 2);
    });

    test('cancel stops after the row in flight', () async {
      late BulkImportRunner r;
      final statuses = <int, BulkRowStatus>{};
      r = runner(
        gate: () async => true,
        extract: (c) async {
          r.cancel();
          return fakeParsedRecipe(RecipeIngestionChannel.urlScrape);
        },
      );
      final reason = await r.run(items, (i, s) => statuses[i] = s);
      expect(reason, BulkStopReason.cancelled);
      expect(statuses[0], BulkRowStatus.done);
      expect(statuses[1], BulkRowStatus.skipped);
    });
  });

  group('ShareIntentService.bulkLaunchFor', () {
    test('a shared text with several links', () async {
      const text = 'my list https://a.com/1 https://a.com/2';
      final launch = await ShareIntentService.bulkLaunchFor([
        SharedMediaFile(path: text, type: SharedMediaType.text),
      ]);
      expect(launch?.candidates, hasLength(2));
      expect(launch?.fallbackText, text);
      expect(launch?.fromChat, isFalse);
    });

    test('a single link is not a bulk import', () async {
      final launch = await ShareIntentService.bulkLaunchFor([
        SharedMediaFile(path: 'https://a.com/1', type: SharedMediaType.url),
      ]);
      expect(launch, isNull);
    });

    test('an Android .txt export arrives as text with a path', () async {
      final dir = await Directory.systemTemp.createTemp('chat');
      final file = File('${dir.path}/WhatsApp Chat with Dana.txt')
        ..writeAsStringSync(_androidChat);
      final launch = await ShareIntentService.bulkLaunchFor([
        SharedMediaFile(
          path: file.path,
          type: SharedMediaType.text,
          mimeType: 'text/plain',
        ),
      ]);
      expect(launch?.fromChat, isTrue);
      expect(launch?.fallbackText, isNull);
      expect(launch?.candidates, hasLength(3));
      await dir.delete(recursive: true);
    });

    test('an iPhone .zip export', () async {
      final dir = await Directory.systemTemp.createTemp('chat');
      final file = File('${dir.path}/WhatsApp Chat - Dana.zip')
        ..writeAsBytesSync(_zip({'_chat.txt': _iosChat}));
      final launch = await ShareIntentService.bulkLaunchFor([
        SharedMediaFile(path: file.path, type: SharedMediaType.file),
      ]);
      expect(launch?.fromChat, isTrue);
      expect(launch?.candidates, const [
        BulkCandidate(
          'https://www.instagram.com/reel/abc/',
          RecipeIngestionChannel.socialVideo,
        ),
        BulkCandidate(_recipe, RecipeIngestionChannel.rawText),
      ]);
      await dir.delete(recursive: true);
    });

    test('a recording is not a chat export', () async {
      final launch = await ShareIntentService.bulkLaunchFor([
        SharedMediaFile(path: '/tmp/note.m4a', type: SharedMediaType.file),
      ]);
      expect(launch, isNull);
    });
  });
}
