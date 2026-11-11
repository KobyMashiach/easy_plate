import '../../../core/constants/app_enums.dart';
import '../../../core/services/share_intent_service.dart';
import 'channel_detector.dart';
import 'entities/ingestion_file.dart';

/// One recipe the bulk import may bring in: a link (a page or a video) or
/// the text of a message that reads like a written-out recipe.
class BulkCandidate {
  /// The link itself, or the message text with nothing of who sent it.
  final String text;

  /// How it is read: [RecipeIngestionChannel.urlScrape],
  /// [RecipeIngestionChannel.socialVideo] or [RecipeIngestionChannel.rawText].
  final RecipeIngestionChannel kind;

  const BulkCandidate(this.text, this.kind);

  bool get isLink => kind != RecipeIngestionChannel.rawText;

  @override
  bool operator ==(Object other) =>
      other is BulkCandidate && other.text == text && other.kind == kind;

  @override
  int get hashCode => Object.hash(text, kind);

  @override
  String toString() => 'BulkCandidate(${kind.name}, $text)';
}

/// What the bulk screen opens on when several recipes came in at once —
/// a share with many links, a WhatsApp chat export.
class BulkImportLaunch {
  final List<BulkCandidate> candidates;

  /// The shared text as it came, for the single-recipe form when the bulk
  /// import is switched off: a share of several links used to open there.
  /// Null for a chat export, which had no such home.
  final String? fallbackText;

  /// Read out of a chat export rather than a share of links.
  final bool fromChat;

  const BulkImportLaunch({
    required this.candidates,
    this.fallbackText,
    this.fromChat = false,
  });
}

/// Finds the recipes in a pile of text. Pure: no I/O, so it is tested on
/// its own and runs before anything leaves the phone.
abstract final class BulkImportParser {
  /// A screen of more than this many rows is a chat history, not a list of
  /// recipes; the oldest past it are left out.
  static const maxCandidates = 100;

  static final _url = RegExp(r'(https?://|www\.)\S+', caseSensitive: false);
  static final _trailing = RegExp(r'''[)\].,!?;:'"»”]+$''');

  /// Every distinct web link in [text], in order, cleaned the same way the
  /// single form cleans one, without the app's own links.
  static List<String> linksIn(String text) {
    final seen = <String>{};
    final links = <String>[];
    for (final match in _url.allMatches(text)) {
      // The sentence's own punctuation off first: a whole-text link is
      // taken as it is by findWebUrl, full stop included.
      final raw = match.group(0)!.replaceFirst(_trailing, '');
      final url = IngestionLaunch.findWebUrl(raw);
      if (url == null || ShareIntentService.isOwnLink(url)) continue;
      if (seen.add(url)) links.add(url);
    }
    return links;
  }

  /// A shared piece of text with two or more links — a list someone sent,
  /// a note of saved recipes — as one candidate per link; null when it has
  /// fewer, so the single form takes it as it always did.
  static List<BulkCandidate>? fromSharedText(String text) {
    final links = linksIn(text);
    if (links.length < 2) return null;
    return [
      for (final link in links.take(maxCandidates))
        BulkCandidate(link, IngestionLaunch.channelForText(link)),
    ];
  }

  /// The links and the recipe-looking messages of a typed list or a chat
  /// export, deduplicated, in the order they were written.
  static List<BulkCandidate> fromChat(String chat) {
    final messages = chatMessages(chat);
    final seen = <String>{};
    final out = <BulkCandidate>[];
    void add(BulkCandidate c) {
      if (out.length < maxCandidates && seen.add(c.text)) out.add(c);
    }

    for (final message in messages) {
      final links = linksIn(message);
      if (links.isNotEmpty) {
        // A link with a caption is the link: the caption is a "look at
        // this", not the recipe. A long recipe that quotes its source is
        // still the recipe, though.
        final rest = message.replaceAll(_url, '').trim();
        if (looksLikeRecipe(rest)) {
          add(BulkCandidate(message, RecipeIngestionChannel.rawText));
        } else {
          for (final link in links) {
            add(BulkCandidate(link, IngestionLaunch.channelForText(link)));
          }
        }
        continue;
      }
      if (looksLikeRecipe(message)) {
        add(BulkCandidate(message, RecipeIngestionChannel.rawText));
      }
    }
    return out;
  }

  /// A message long enough, and shaped enough, to be a recipe rather than
  /// chat: the detector has to read it as pasted text, and it has to be
  /// several lines, or long with quantities in it. Two short lines ("ok
  /// see you at 8\nbring wine") are what a chat is full of.
  static bool looksLikeRecipe(String text) {
    final value = text.trim();
    if (value.isEmpty) return false;
    if (ChannelDetector.detect(value) != RecipeIngestionChannel.rawText) {
      return false;
    }
    final lines = value
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .length;
    if (lines >= 4) return true;
    return value.length >= 150 && RegExp(r'\d').hasMatch(value);
  }

  /// The start of a WhatsApp export line: a date, a time, and either
  /// " - " (Android) or brackets (iPhone). Day and month order, the
  /// separators, seconds and AM/PM differ by phone language, so all of
  /// them are allowed.
  static final _stamp = RegExp(
    r'^[\u200e\u200f\u202a-\u202e]*\[?'
    r'\d{1,4}[./-]\d{1,2}[./-]\d{1,4},?[\s\u202f]+'
    r'\d{1,2}[:.]\d{2}(?:[:.]\d{2})?'
    r'(?:[\s\u202f]*[AaPp]\.?[\s\u202f]?[Mm]\.?)?'
    r'\]?[\s\u202f]*(?:[-–][\s\u202f]*)?',
  );

  /// The sender after the stamp, up to the first ": ".
  static final _sender = RegExp(r'^[^:\n]{1,80}?:\s');

  /// What WhatsApp writes in place of what was not exported, or about a
  /// message rather than in it.
  static final _placeholders = RegExp(
    r'[\u200e\u200f]*(<[^>\n]{1,60}>|\b(image|video|audio|sticker|GIF|document) omitted\b|'
    r'\(file attached\)|This message was deleted|You deleted this message|'
    r'ההודעה נמחקה|\u200f?המדיה הושמטה|<המדיה הושמטה>)',
    caseSensitive: false,
  );

  /// The messages of a chat export, each with its "date, time - name:"
  /// prefix taken off: only what was written is kept, never who wrote it.
  /// Lines without a stamp continue the message above them. A text that
  /// is not an export at all comes back as its lines, each a message, so
  /// a pasted list of links works the same way.
  static List<String> chatMessages(String chat) {
    final text = chat.replaceAll('\r\n', '\n').replaceAll('\ufeff', '');
    final lines = text.split('\n');
    final isExport =
        lines.where(_stamp.hasMatch).length >= 2 ||
        (lines.isNotEmpty && _stamp.hasMatch(lines.first));
    if (!isExport) {
      return _blocks(text);
    }
    final messages = <String>[];
    StringBuffer? current;
    void flush() {
      final body = current?.toString().replaceAll(_placeholders, '').trim();
      if (body != null && body.isNotEmpty) messages.add(body);
      current = null;
    }

    for (final line in lines) {
      final stamp = _stamp.firstMatch(line);
      if (stamp == null) {
        current?.write('\n$line');
        continue;
      }
      flush();
      final rest = line.substring(stamp.end);
      final sender = _sender.firstMatch(rest);
      // No sender: a line WhatsApp wrote itself (the encryption notice,
      // someone joining). Nothing a person sent, so nothing to keep — nor
      // the lines that follow it until the next stamp.
      if (sender == null) continue;
      final body = rest.substring(sender.end);
      // An iPhone marks what it wrote itself under the chat's name (the
      // encryption notice, "image omitted") with a left-to-right mark first.
      if (body.startsWith('\u200e')) continue;
      current = StringBuffer(body);
    }
    flush();
    return messages;
  }

  /// Plain text split into its paragraphs, a list of lines each counting
  /// as its own block when it holds a link.
  static List<String> _blocks(String text) {
    final out = <String>[];
    for (final paragraph in text.split(RegExp(r'\n\s*\n'))) {
      final value = paragraph.trim();
      if (value.isEmpty) continue;
      // A list of links, one a line: each line its own message, so every
      // link is offered rather than the first.
      final lines = value.split('\n');
      if (lines.length > 1 && !looksLikeRecipe(value.replaceAll(_url, ''))) {
        out.addAll(lines.map((l) => l.trim()).where((l) => l.isNotEmpty));
      } else {
        out.add(value);
      }
    }
    return out;
  }
}
