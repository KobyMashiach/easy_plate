import 'dart:convert';
import 'dart:typed_data';

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
}
