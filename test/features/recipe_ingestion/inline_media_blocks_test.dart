import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:easy_plate/features/recipe_ingestion/data/datasources/recipe_ai_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('inline blocks keep the order, type and MIME type of every part', () {
    final photo = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0, 1, 2]);
    final pdf = Uint8List.fromList(utf8.encode('%PDF-1.4'));
    final blocks = inlineMediaBlocks([
      (type: 'image', mimeType: 'image/jpeg', bytes: photo),
      (type: 'document', mimeType: 'application/pdf', bytes: pdf),
    ]);
    expect(blocks, [
      {'type': 'image', 'mime_type': 'image/jpeg', 'data': base64Encode(photo)},
      {
        'type': 'document',
        'mime_type': 'application/pdf',
        'data': base64Encode(pdf),
      },
    ]);
  });

  test('the isolate encode produces the same body as the inline one', () async {
    final parts = [
      (
        type: 'audio',
        mimeType: 'audio/aac',
        bytes: Uint8List.fromList(List.generate(70000, (i) => i % 251)),
      ),
    ];
    expect(await encodeInlineMedia(parts), inlineMediaBlocks(parts));
  });

  test('no parts is no blocks', () {
    expect(inlineMediaBlocks(const []), isEmpty);
  });

  group('request body', () {
    final media = {
      'model': 'm',
      'input': [
        ...inlineMediaBlocks([
          (
            type: 'image',
            mimeType: 'image/jpeg',
            bytes: Uint8List.fromList(List.generate(300000, (i) => i % 256)),
          ),
        ]),
        {'type': 'text', 'text': 'חלץ את המוצרים'},
      ],
    };

    test('only a body with attachments is encoded ahead', () {
      expect(carriesInlineMedia(media), isTrue);
      expect(
        carriesInlineMedia({
          'input': [
            {'type': 'text', 'text': 'hi'},
          ],
        }),
        isFalse,
      );
      expect(carriesInlineMedia({'input': 'a prompt'}), isFalse);
    });

    test('the isolate encode is the bytes Dio would have sent', () async {
      expect(await encodeJsonBody(media), utf8.encode(jsonEncode(media)));
    });

    test('Dio sends the encoded bytes untouched, as JSON', () async {
      final adapter = _Capture();
      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://example.invalid',
          headers: {'Content-Type': 'application/json'},
        ),
      )..httpClientAdapter = adapter;
      final bytes = await encodeJsonBody(media);
      await dio.post<dynamic>('/x', data: bytes);
      expect(adapter.body, bytes);
      expect(adapter.contentType, startsWith('application/json'));
      expect(jsonDecode(utf8.decode(adapter.body!)), media);
    });
  });
}

class _Capture implements HttpClientAdapter {
  List<int>? body;
  String? contentType;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final chunks = <int>[];
    await for (final chunk in requestStream!) {
      chunks.addAll(chunk);
    }
    body = chunks;
    contentType = options.contentType;
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
