import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../domain/entities/ingestion_file.dart';

/// Photos of a recipe are made small before they go to the model: a phone
/// photo is 3–8 MB and a few pages of a cookbook would pass the 10 MB a
/// request may carry ([IngestionFile.maxBytes]). The model reads text, not
/// detail, so 2000 px on the long side at JPEG 82 keeps small print and
/// handwriting legible at a few hundred kilobytes a page.
class RecipeImageShrinker {
  const RecipeImageShrinker._();

  static const maxSide = 2000;
  static const quality = 82;

  /// Below this a picture goes as it is: decoding it costs more time than
  /// the bytes it would save.
  static const keepBelowBytes = 600 * 1024;

  /// [file] ready to send: a picture re-encoded off the UI isolate, anything
  /// else untouched. A format the decoder cannot read (HEIC) goes as it is
  /// — the model reads it, and the size check still applies.
  static Future<IngestionFile> shrink(IngestionFile file) async {
    if (!file.isImage || file.bytes.length <= keepBelowBytes) return file;
    final out = await compute(shrinkBytes, file.bytes);
    if (out == null) return file;
    return IngestionFile(
      name: jpegName(file.name),
      bytes: out,
      mimeType: 'image/jpeg',
    );
  }

  /// [bytes] decoded, turned upright, scaled to [maxSide] and re-encoded as
  /// JPEG; null when the format cannot be decoded or the result would be no
  /// smaller than what came in.
  @visibleForTesting
  static Uint8List? shrinkBytes(Uint8List bytes) {
    final img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes);
    } catch (_) {
      return null;
    }
    if (decoded == null) return null;
    // A phone photo is stored sideways with an EXIF turn; the turn is lost
    // in the re-encode, so it is applied to the pixels first.
    var image = img.bakeOrientation(decoded);
    final longSide = image.width > image.height ? image.width : image.height;
    if (longSide > maxSide) {
      image = image.width >= image.height
          ? img.copyResize(
              image,
              width: maxSide,
              interpolation: img.Interpolation.average,
            )
          : img.copyResize(
              image,
              height: maxSide,
              interpolation: img.Interpolation.average,
            );
    }
    final out = img.encodeJpg(image, quality: quality);
    return out.length < bytes.length ? out : null;
  }

  /// [name] with its extension swapped for `.jpg`, for the row on screen.
  @visibleForTesting
  static String jpegName(String name) {
    final dot = name.lastIndexOf('.');
    return '${dot <= 0 ? name : name.substring(0, dot)}.jpg';
  }
}
