import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../features/recipe_ingestion/data/recipe_image_shrinker.dart';
import '../../features/recipe_ingestion/data/chat_export_reader.dart';
import '../../features/recipe_ingestion/domain/bulk_import.dart';
import '../../features/recipe_ingestion/domain/entities/ingestion_file.dart';
import '../constants/app_enums.dart';
import '../features/features_flags.dart';

/// What another app handed over through the system share sheet: a voice
/// note, a recording, a PDF, a link or some text, already shaped into the
/// launch the ingestion screen opens on.
///
/// [latest] carries the most recent share; the app listens and routes it
/// to the ingestion screen when the session allows. A share that arrives
/// while the app is closed is delivered the same way once it starts.
class ShareIntentService {
  ShareIntentService._();
  static final _instance = ShareIntentService._();
  factory ShareIntentService() => _instance;

  final latest = ValueNotifier<IngestionLaunch?>(null);

  /// A share that holds several recipes — a text with many links, a
  /// WhatsApp chat export — for the bulk import screen rather than the
  /// single form. Routed by the app like [latest].
  final latestBulk = ValueNotifier<BulkImportLaunch?>(null);

  /// Whether a share of either kind is waiting for the session.
  bool get hasPending => latest.value != null || latestBulk.value != null;

  StreamSubscription<List<SharedMediaFile>>? _subscription;
  bool _bound = false;

  /// Starts listening. Safe to call more than once.
  Future<void> bind() async {
    if (_bound) return;
    _bound = true;
    // Only the two mobile platforms have a share sheet to receive from.
    if (!Platform.isAndroid && !Platform.isIOS) return;
    final plugin = ReceiveSharingIntent.instance;
    _subscription = plugin.getMediaStream().listen(
      _receive,
      onError: (Object e) => debugPrint('Share stream error: $e'),
    );
    try {
      _receive(await plugin.getInitialMedia());
      // Consumed: a restart must not open the same share twice.
      await plugin.reset();
    } catch (e) {
      debugPrint('Initial share read failed: $e');
    }
  }

  Future<void> _receive(List<SharedMediaFile> files) async {
    if (files.isEmpty) return;
    // The plugin also sees the app's own deep links (a widget tap, a share
    // link) as a "shared URL"; those belong to the router, not to the
    // ingestion screen.
    if (files.every((f) => isOwnLink(f.path))) return;
    try {
      // Several recipes in one share go to the bulk screen; whether that
      // screen is switched on is decided when it is routed, since the
      // console's flags may not be in yet on a cold start.
      final bulk = await bulkLaunchFor(files);
      if (bulk != null) {
        latestBulk.value = bulk;
        return;
      }
      final launch = await launchFor(files);
      if (launch != null) latest.value = launch;
    } catch (e) {
      debugPrint('Shared content unreadable: $e');
    }
  }

  /// `easyplate://…` and `https://aieasyplate.app/s/…`: links the app opens
  /// itself, never recipe sources. Also asked by the clipboard prompt and
  /// the bulk import, which must not offer them either.
  static bool isOwnLink(String text) {
    final uri = Uri.tryParse(text.trim());
    if (uri == null) return false;
    if (uri.scheme == 'easyplate') return true;
    return uri.host == 'aieasyplate.app' && uri.path.startsWith('/s/');
  }

  /// The largest shared file read into memory.
  @visibleForTesting
  static const readCap = 64 * 1024 * 1024;

  /// The ingestion launch a share maps to. Text and links fill the matching
  /// text channel; files are read into memory for the file channel, all of
  /// them, in the order shared — they are the parts of one recipe. Files
  /// the model cannot read (a photo, a video) are left out; null when
  /// nothing usable remains.
  @visibleForTesting
  static Future<IngestionLaunch?> launchFor(List<SharedMediaFile> files) async {
    final first = files.first;
    if (first.type == SharedMediaType.text ||
        first.type == SharedMediaType.url) {
      final text = first.path.trim();
      if (text.isEmpty) return null;
      return IngestionLaunch(
        channel: IngestionLaunch.channelForText(text),
        text: text,
      );
    }
    final read = <IngestionFile>[];
    for (final shared in files) {
      final mimeType = _mimeTypeOf(shared);
      if (mimeType == null) continue;
      final file = File(shared.path);
      if (!await file.exists()) continue;
      // Read whole into memory below: a recording of hundreds of megabytes
      // would take the app down before the form could say it is too large.
      // Anything up to [readCap] still reaches the form, which explains the
      // 10 MB limit itself.
      if (await file.length() > readCap) {
        debugPrint('Shared file skipped: larger than the read cap');
        continue;
      }
      // A photo is made small here, before the form's 10 MB check sees
      // it: two phone photos of a cookbook page would otherwise be refused.
      read.add(
        await RecipeImageShrinker.shrink(
          IngestionFile(
            name: shared.path.split(Platform.pathSeparator).last,
            bytes: await file.readAsBytes(),
            mimeType: mimeType,
          ),
        ),
      );
    }
    if (read.isEmpty) return null;
    return IngestionLaunch(channel: RecipeIngestionChannel.file, files: read);
  }

  /// The bulk import a share maps to, or null when it is one recipe (or
  /// nothing the bulk import reads):
  ///
  /// * text with two or more links — one row per link, the text kept as
  ///   the fallback for the single form;
  /// * a WhatsApp chat export — the `.txt` (Android shares it as a text
  ///   file, so it arrives typed as text with a file path) or the `.zip`
  ///   around it (iPhone) — its links and recipe-looking messages, with
  ///   who sent them left out.
  @visibleForTesting
  static Future<BulkImportLaunch?> bulkLaunchFor(
    List<SharedMediaFile> files,
  ) async {
    final first = files.first;
    final path = first.path.trim();
    final isText =
        first.type == SharedMediaType.text || first.type == SharedMediaType.url;
    if (isText && !_isLocalFile(path)) {
      final candidates = BulkImportParser.fromSharedText(path);
      if (candidates == null) return null;
      return BulkImportLaunch(candidates: candidates, fallbackText: path);
    }
    for (final shared in files) {
      final name = shared.path.split(Platform.pathSeparator).last;
      final mime = shared.mimeType?.toLowerCase() ?? '';
      final isExport =
          ChatExportReader.isExportName(name) ||
          mime == 'application/zip' ||
          mime == 'text/plain';
      if (!isExport) continue;
      final file = File(shared.path);
      if (!await file.exists() || await file.length() > readCap) continue;
      final text = ChatExportReader.textOf(await file.readAsBytes());
      if (text == null) continue;
      return BulkImportLaunch(
        candidates: BulkImportParser.fromChat(text),
        fromChat: true,
      );
    }
    return null;
  }

  /// A shared "text" that is really a file on disk: Android hands a shared
  /// `.txt` over with its path in the text slot.
  static bool _isLocalFile(String path) =>
      path.startsWith('/') &&
      !path.contains('\n') &&
      ChatExportReader.isExportName(path) &&
      File(path).existsSync();

  /// An ingestion form that is open right now and will take the next share
  /// itself — adding the files to the ones it already holds — so the app
  /// must not open a second screen over it. Set by the form while mounted.
  bool get hasOpenForm => _openForms > 0;
  int _openForms = 0;
  void formOpened() => _openForms++;
  void formClosed() => _openForms--;

  /// The share sheet's type when it is one the model reads, else the one
  /// the extension implies; null when the file is neither audio nor a PDF
  /// — nor, while the photo channel is on, a picture the model reads.
  static String? _mimeTypeOf(SharedMediaFile file) {
    final declared = file.mimeType?.toLowerCase();
    if (declared != null &&
        (declared == 'application/pdf' || declared.startsWith('audio/'))) {
      return declared;
    }
    final images = FeaturesFlags.ingestPhoto.isEnabled;
    if (images && declared != null && declared.startsWith('image/')) {
      final image = IngestionFile.readableImageType(declared);
      if (image != null) return image;
    }
    return IngestionFile.mimeTypeFor(file.path, images: images);
  }

  /// Marks [latest] as handled.
  void clear() => latest.value = null;

  /// Marks [latestBulk] as handled.
  void clearBulk() => latestBulk.value = null;

  @visibleForTesting
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _bound = false;
  }
}
