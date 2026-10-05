import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../features/recipe_ingestion/domain/entities/ingestion_file.dart';
import '../constants/app_enums.dart';

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
    try {
      final launch = await launchFor(files);
      if (launch != null) latest.value = launch;
    } catch (e) {
      debugPrint('Shared content unreadable: $e');
    }
  }

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
      read.add(
        IngestionFile(
          name: shared.path.split(Platform.pathSeparator).last,
          bytes: await file.readAsBytes(),
          mimeType: mimeType,
        ),
      );
    }
    if (read.isEmpty) return null;
    return IngestionLaunch(channel: RecipeIngestionChannel.file, files: read);
  }

  /// An ingestion form that is open right now and will take the next share
  /// itself — adding the files to the ones it already holds — so the app
  /// must not open a second screen over it. Set by the form while mounted.
  bool get hasOpenForm => _openForms > 0;
  int _openForms = 0;
  void formOpened() => _openForms++;
  void formClosed() => _openForms--;

  /// The share sheet's type when it is one the model reads, else the one
  /// the extension implies; null when the file is neither audio nor a PDF.
  static String? _mimeTypeOf(SharedMediaFile file) {
    final declared = file.mimeType?.toLowerCase();
    if (declared != null &&
        (declared == 'application/pdf' || declared.startsWith('audio/'))) {
      return declared;
    }
    return IngestionFile.mimeTypeFor(file.path);
  }

  /// Marks [latest] as handled.
  void clear() => latest.value = null;

  @visibleForTesting
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _bound = false;
  }
}
