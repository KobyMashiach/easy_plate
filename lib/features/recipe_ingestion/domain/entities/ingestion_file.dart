import 'dart:typed_data';

import '../../../../core/constants/app_enums.dart';

/// A file handed to the analysis: a recording of someone reading out a
/// recipe, a voice note, a PDF. Read into memory, since it goes to the
/// model inline.
class IngestionFile {
  final String name;
  final Uint8List bytes;
  final String mimeType;

  const IngestionFile({
    required this.name,
    required this.bytes,
    required this.mimeType,
  });

  /// The proxy takes a request of 16 MB; base64 adds a third, so everything
  /// sent together has to stay well under that. Ten minutes of voice notes
  /// fit comfortably.
  static const maxBytes = 10 * 1024 * 1024;

  bool get isPdf => mimeType == 'application/pdf';
  bool get isAudio => mimeType.startsWith('audio/');
  bool get isSupported => isPdf || isAudio;

  /// Whether [files] together exceed what one request may carry.
  static bool tooLarge(Iterable<IngestionFile> files) =>
      files.fold<int>(0, (sum, f) => sum + f.bytes.length) > maxBytes;

  /// The MIME type a file's extension implies, for the formats the model
  /// reads; null for anything else. The share sheet often hands a file over
  /// with no type, so this is what the type falls back to.
  static String? mimeTypeFor(String path) {
    final dot = path.lastIndexOf('.');
    final ext = dot == -1 ? '' : path.substring(dot + 1).toLowerCase();
    return switch (ext) {
      'pdf' => 'application/pdf',
      'mp3' => 'audio/mpeg',
      'm4a' || 'aac' => 'audio/aac',
      'wav' => 'audio/wav',
      'ogg' || 'oga' => 'audio/ogg',
      'opus' => 'audio/opus',
      'flac' => 'audio/flac',
      'aiff' || 'aif' => 'audio/aiff',
      'amr' => 'audio/amr',
      'caf' => 'audio/x-caf',
      'webm' || 'weba' => 'audio/webm',
      _ => null,
    };
  }

  /// Extensions the picker offers, matching [mimeTypeFor].
  static const pickerExtensions = [
    'pdf',
    'mp3',
    'm4a',
    'aac',
    'wav',
    'ogg',
    'oga',
    'opus',
    'flac',
    'aiff',
    'aif',
    'amr',
    'caf',
    'webm',
    'weba',
  ];
}

/// What the ingestion screen opens on when something was handed to it from
/// outside — the system share sheet, a notification — rather than chosen in
/// the app. Every field is optional; the screen falls back to its defaults.
///
/// Several [files] are the parts of one recipe: a voice note that came in
/// three pieces, a recording plus the PDF it refers to. They are analysed
/// together, in order.
class IngestionLaunch {
  final RecipeIngestionChannel? channel;
  final String? text;
  final List<IngestionFile> files;

  const IngestionLaunch({this.channel, this.text, this.files = const []});

  /// The channel a shared piece of text belongs to: a link to one of the
  /// video platforms is a video, any other link a page, the rest pasted text.
  static RecipeIngestionChannel channelForText(String text) {
    final uri = Uri.tryParse(text.trim());
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return RecipeIngestionChannel.rawText;
    }
    final host = uri.host.toLowerCase();
    const video = [
      'tiktok.com',
      'instagram.com',
      'youtube.com',
      'youtu.be',
      'facebook.com',
      'fb.watch',
    ];
    final isVideo = video.any((h) => host == h || host.endsWith('.$h'));
    return isVideo
        ? RecipeIngestionChannel.socialVideo
        : RecipeIngestionChannel.urlScrape;
  }
}
