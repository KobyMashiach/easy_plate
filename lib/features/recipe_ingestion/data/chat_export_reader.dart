import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Reads the text of a WhatsApp chat export: the `.txt` itself (what an
/// Android phone shares) or the `.zip` around it (what an iPhone shares,
/// with the photos next to it). Only the chat text is taken out of a zip;
/// the media in it is never read.
///
/// A small reader of its own rather than a package: one file out of an
/// archive, stored or deflated, is all it needs, and `dart:io` inflates.
abstract final class ChatExportReader {
  /// The most chat text read out of an archive. Years of a busy group fit
  /// in a few megabytes; past this it is not a chat.
  static const maxTextBytes = 20 * 1024 * 1024;

  /// Whether [name] (a file name or path) is a chat export the bulk import
  /// takes: a text file or a zip.
  static bool isExportName(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.txt') || lower.endsWith('.zip');
  }

  /// The chat text in [bytes], or null when there is none — a zip with no
  /// text file in it, an archive it cannot read.
  static String? textOf(Uint8List bytes) {
    if (_isZip(bytes)) {
      final inner = _chatFromZip(bytes);
      return inner == null ? null : _decode(inner);
    }
    return _decode(bytes);
  }

  static String _decode(Uint8List bytes) =>
      utf8.decode(bytes, allowMalformed: true);

  static bool _isZip(Uint8List b) =>
      b.length >= 4 &&
      b[0] == 0x50 &&
      b[1] == 0x4b &&
      b[2] == 0x03 &&
      b[3] == 0x04;

  /// The bytes of `_chat.txt` (or else the first `.txt`) in a zip, read
  /// through the central directory at the end of the file.
  static Uint8List? _chatFromZip(Uint8List bytes) {
    try {
      final data = ByteData.sublistView(bytes);
      // The end-of-directory record: 22 bytes plus a comment of up to 64K,
      // found by its signature from the back.
      var eocd = -1;
      final floor = bytes.length - 22 - 0xFFFF;
      for (var i = bytes.length - 22; i >= 0 && i >= floor; i--) {
        if (data.getUint32(i, Endian.little) == 0x06054b50) {
          eocd = i;
          break;
        }
      }
      if (eocd < 0) return null;
      final count = data.getUint16(eocd + 10, Endian.little);
      var offset = data.getUint32(eocd + 16, Endian.little);

      _Entry? chosen;
      for (var n = 0; n < count; n++) {
        if (data.getUint32(offset, Endian.little) != 0x02014b50) return null;
        final method = data.getUint16(offset + 10, Endian.little);
        final compressed = data.getUint32(offset + 20, Endian.little);
        final size = data.getUint32(offset + 24, Endian.little);
        final nameLength = data.getUint16(offset + 28, Endian.little);
        final extraLength = data.getUint16(offset + 30, Endian.little);
        final commentLength = data.getUint16(offset + 32, Endian.little);
        final local = data.getUint32(offset + 42, Endian.little);
        final name = utf8.decode(
          bytes.sublist(offset + 46, offset + 46 + nameLength),
          allowMalformed: true,
        );
        final base = name.split('/').last.toLowerCase();
        final entry = _Entry(method, compressed, size, local);
        // `__MACOSX/` holds Finder's shadow copies, never the chat.
        if (!name.startsWith('__MACOSX') && base.endsWith('.txt')) {
          if (base == '_chat.txt') {
            chosen = entry;
            break;
          }
          chosen ??= entry;
        }
        offset += 46 + nameLength + extraLength + commentLength;
      }
      final entry = chosen;
      if (entry == null || entry.size > maxTextBytes) return null;

      final local = entry.localOffset;
      if (data.getUint32(local, Endian.little) != 0x04034b50) return null;
      final start =
          local +
          30 +
          data.getUint16(local + 26, Endian.little) +
          data.getUint16(local + 28, Endian.little);
      final raw = bytes.sublist(start, start + entry.compressed);
      return switch (entry.method) {
        0 => raw,
        8 => Uint8List.fromList(ZLibDecoder(raw: true).convert(raw)),
        _ => null,
      };
    } catch (e) {
      debugPrint('Chat export unreadable: $e');
      return null;
    }
  }
}

class _Entry {
  final int method;
  final int compressed;
  final int size;
  final int localOffset;
  const _Entry(this.method, this.compressed, this.size, this.localOffset);
}
