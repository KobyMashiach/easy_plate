import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../services/image_storage_service.dart';

/// The remote half of a recipe photo.
///
/// An entity carries only a *file name*, and that name means something solely
/// inside this device's image directory — so a photo never travelled anywhere.
/// Not to a second device, not to the account a recipe was shared with, not to
/// the community feed. Each of those looked like three separate bugs; all three
/// were this one missing piece.
///
/// So the file is uploaded once and the recipe records its Storage *path*
/// rather than a download URL. A download URL carries an access token that
/// makes the object readable by anyone holding the link, whatever the rules
/// say; a path is resolved through the SDK, so `storage.rules` actually decides
/// who may read it.
///
/// Downloads land back in the same local directory under the same file name,
/// which is what makes this a cache rather than a fetch: the photo is pulled
/// once and every later build reads it off the disk.
class RecipeImageStore {
  static final RecipeImageStore _instance = RecipeImageStore._internal();
  factory RecipeImageStore() => _instance;
  RecipeImageStore._internal();

  static const folder = 'recipe_images';

  /// Photos are capped at 1600px and 85% quality when picked, which lands far
  /// under this. The ceiling is here so a tampered object cannot be pulled into
  /// memory unbounded.
  static const maxBytes = 10 * 1024 * 1024;

  /// Resolved on first use, not at construction — the singleton is built
  /// wherever it is first touched, which may be before Firebase is up in a test.
  late final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Downloads in progress, by file name. The recipe list and the details
  /// screen ask for the same photo in the same frame, and without this each
  /// would start its own download of it.
  final Map<String, Future<String?>> _inFlight = {};

  /// Photos are namespaced by their owner so one account cannot overwrite
  /// another's, which is also what the storage rule matches on.
  static String pathFor(String uid, String fileName) => '$folder/$uid/$fileName';

  /// Uploads the local file behind [fileName] and returns its Storage path, or
  /// null when there is nothing on disk to send or the upload failed.
  ///
  /// Callers treat null as "not uploaded yet" and try again on the next save,
  /// rather than recording a path that resolves to nothing.
  Future<String?> upload(String fileName, {required String uid}) async {
    final local = ImageStorageService().pathFor(fileName);
    if (local == null) return null;

    final path = pathFor(uid, fileName);
    try {
      await _storage.ref(path).putFile(File(local));
      return path;
    } catch (e) {
      debugPrint('Recipe image upload failed for $path: $e');
      return null;
    }
  }

  /// The local path for [fileName], downloading it from [storagePath] first if
  /// this device does not have it yet.
  Future<String?> ensureCached(String fileName, String storagePath) {
    final existing = ImageStorageService().pathFor(fileName);
    if (existing != null) return Future.value(existing);

    final running = _inFlight[fileName];
    if (running != null) return running;

    final future = _download(fileName, storagePath);
    _inFlight[fileName] = future;
    // Cleared once it settles, so a download that failed on a dead connection
    // is retried the next time the photo is asked for rather than being
    // remembered as impossible for the rest of the session.
    future.whenComplete(() => _inFlight.remove(fileName));
    return future;
  }

  Future<String?> _download(String fileName, String storagePath) async {
    try {
      final bytes = await _storage.ref(storagePath).getData(maxBytes);
      if (bytes == null) return null;
      return ImageStorageService().storeBytes(fileName, bytes);
    } catch (e) {
      debugPrint('Recipe image download failed for $storagePath: $e');
      return null;
    }
  }

  /// Deletes an uploaded photo, when it is this account's to delete.
  ///
  /// The ownership check is not just belt-and-braces: a recipe saved from the
  /// community keeps the *author's* Storage path, so deleting that copy would
  /// otherwise try to strip the picture off the original post for everyone. The
  /// rules would refuse it, but failing silently on every such delete is worse
  /// than not asking.
  Future<void> remove(String? storagePath, {required String? uid}) async {
    if (!ownsPath(storagePath, uid)) return;

    try {
      await _storage.ref(storagePath!).delete();
    } catch (e) {
      // An object that is already gone is the expected failure here, and there
      // is nothing for the user to do about any of them.
      debugPrint('Recipe image delete failed for $storagePath: $e');
    }
  }

  /// Whether [storagePath] is an object [uid] may delete. Pure, so the guard
  /// that keeps a saved community recipe from trying to strip the picture off
  /// someone else's post can be pinned without a Storage.
  static bool ownsPath(String? storagePath, String? uid) {
    if (storagePath == null || uid == null || uid.isEmpty) return false;
    return storagePath.startsWith('$folder/$uid/');
  }

  /// Tests share the singleton, and an entry left behind would be handed to the
  /// next test as a finished download.
  @visibleForTesting
  void resetForTest() => _inFlight.clear();
}
