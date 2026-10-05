import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Owns the user's picked photos on disk.
///
/// Entities store only the *file name*, never a full path: an app container's
/// absolute path changes between installs and OS upgrades on iOS, so a stored
/// absolute path would silently stop resolving. The directory is cached at
/// startup so [pathFor] can stay synchronous for use inside `build`.
class ImageStorageService {
  static final ImageStorageService _instance = ImageStorageService._internal();
  factory ImageStorageService() => _instance;
  ImageStorageService._internal();

  static const _uuid = Uuid();
  static const _folderName = 'recipe_images';

  Directory? _directory;
  final _picker = ImagePicker();

  /// The files known to be in the directory, and the names known not to
  /// be. [pathFor] is asked by every card on every build, from inside
  /// `build`; a synchronous stat of the disk for each was the one piece of
  /// I/O left on the UI thread while a grid scrolled. Every write and
  /// delete goes through this service, so the sets stay true.
  final _present = <String>{};
  final _absent = <String>{};

  Future<void> init() async {
    if (_directory != null) return;
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/$_folderName');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    await for (final entry in directory.list()) {
      if (entry is File) _present.add(entry.uri.pathSegments.last);
    }
    _directory = directory;
  }

  /// Absolute path for a stored image, or null when there is none (or the file
  /// has since been removed from disk).
  String? pathFor(String? fileName) {
    if (fileName == null || _directory == null) return null;
    final path = '${_directory!.path}/$fileName';
    if (_present.contains(fileName)) return path;
    if (_absent.contains(fileName)) return null;
    // A name this session has not met: one stat, remembered either way.
    if (File(path).existsSync()) {
      _present.add(fileName);
      return path;
    }
    _absent.add(fileName);
    return null;
  }

  void _remember(String fileName) {
    _present.add(fileName);
    _absent.remove(fileName);
  }

  /// Opens the picker and copies the chosen photo into app storage.
  /// Returns the stored file name, or null if the user backed out.
  Future<String?> pickAndStore(ImageSource source) async {
    try {
      await init();
      final picked = await _picker.pickImage(
        source: source,
        // Recipe photos are decoration, not archival — cap them so the app
        // directory doesn't fill up with multi-megabyte originals.
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked == null) return null;

      final extension = picked.name.contains('.')
          ? picked.name.split('.').last
          : 'jpg';
      final fileName = '${_uuid.v4()}.$extension';
      await File(picked.path).copy('${_directory!.path}/$fileName');
      _remember(fileName);
      return fileName;
    } catch (e) {
      debugPrint('Image pick error: $e');
      return null;
    }
  }

  /// Writes [bytes] into the image directory under [fileName].
  ///
  /// Fills the cache from a copy fetched over the network, so a photo that
  /// arrived with a shared recipe — or came back with a restored one — becomes
  /// indistinguishable from one taken on this phone: [pathFor] resolves it
  /// from then on, offline included, and it is never downloaded twice.
  Future<String?> storeBytes(String fileName, Uint8List bytes) async {
    try {
      await init();
      final file = File('${_directory!.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      _remember(fileName);
      return file.path;
    } catch (e) {
      debugPrint('Image cache write error: $e');
      return null;
    }
  }

  Future<void> delete(String? fileName) async {
    final path = pathFor(fileName);
    if (path == null) return;
    _present.remove(fileName);
    _absent.add(fileName!);
    try {
      await File(path).delete();
    } catch (e) {
      debugPrint('Image delete error: $e');
    }
  }
}
