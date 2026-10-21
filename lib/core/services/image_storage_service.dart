import 'dart:async';
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

  /// Finds (or creates) the directory. Cheap on purpose: it runs before the
  /// first frame, and the listing — whose cost grows with every photo — is
  /// left to [listDirectory] once the app is on screen. Until the listing
  /// lands, a name [pathFor] has not met is checked on its own, which
  /// [resolve] (and so `ClayImage`) waits for.
  Future<void> init() async {
    if (_directory != null) return;
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/$_folderName');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    _directory = directory;
  }

  Future<void>? _listing;

  /// Lists the directory once, so the photos already on disk resolve from
  /// memory without one check each. Called after the first frame.
  Future<void> listDirectory() => _listing ??= _list();

  Future<void> _list() async {
    try {
      await init();
      await for (final entry in _directory!.list()) {
        if (entry is! File) continue;
        final name = entry.uri.pathSegments.last;
        // A delete through this service while the listing ran: the entry
        // was read before the file went, and must not come back.
        if (!_absent.contains(name)) _present.add(name);
      }
    } catch (e) {
      debugPrint('Image directory listing failed: $e');
    }
  }

  /// Disk checks under way for names neither set knows yet, by name.
  final _checks = <String, Future<bool>>{};

  /// Absolute path for a stored image, or null when there is none (or the file
  /// has since been removed from disk).
  ///
  /// Never touches the disk: it is called from inside `build`. A name this
  /// session has not met (rare once [listDirectory] has run) reads as absent
  /// for now while one check runs in the background; [resolve] waits for
  /// that answer.
  String? pathFor(String? fileName) {
    if (fileName == null || _directory == null || !isSafeName(fileName)) {
      return null;
    }
    final path = '${_directory!.path}/$fileName';
    if (_present.contains(fileName)) return path;
    if (_absent.contains(fileName)) return null;
    unawaited(_check(fileName));
    return null;
  }

  /// [pathFor], with the disk asked for a name that has not been checked
  /// yet. For the paths that may wait: a download, an upload, a delete.
  Future<String?> resolve(String? fileName) async {
    final known = pathFor(fileName);
    if (known != null ||
        fileName == null ||
        _directory == null ||
        !isSafeName(fileName)) {
      return known;
    }
    final pending = _checks[fileName];
    if (pending == null) return null;
    return await pending ? pathFor(fileName) : null;
  }

  /// One stat per unseen name, remembered either way — unless a write or a
  /// delete through this service settled the name while the stat ran.
  Future<bool> _check(String fileName) =>
      _checks[fileName] ??= File('${_directory!.path}/$fileName')
          .exists()
          .catchError((_) => false)
          .then((exists) {
            _checks.remove(fileName);
            if (!_present.contains(fileName) && !_absent.contains(fileName)) {
              (exists ? _present : _absent).add(fileName);
            }
            return _present.contains(fileName);
          });

  /// Whether [fileName] is a plain name inside the image directory.
  ///
  /// The name of a shared or community recipe's photo is written by another
  /// account, and it is joined onto this directory to read, download into
  /// and delete: `../recipesbox_<uid>.hive` would have let a collaborator
  /// overwrite (or delete) any file in the app's documents — the Hive boxes
  /// among them — with a Storage object of their choosing. Names this app
  /// mints are a uuid with an extension, so anything with a separator, a
  /// leading dot or a control character is refused outright.
  static bool isSafeName(String fileName) {
    if (fileName.isEmpty || fileName.length > 200) return false;
    if (fileName.startsWith('.')) return false;
    // Control characters, '/' and '\\'.
    for (final unit in fileName.codeUnits) {
      if (unit < 0x20 || unit == 0x2F || unit == 0x5C) {
        return false;
      }
    }
    return true;
  }

  /// Tests only: the directory [init] would find, with nothing known yet.
  @visibleForTesting
  void useDirectoryForTest(Directory directory) {
    _directory = directory;
    _listing = null;
    _present.clear();
    _absent.clear();
    _checks.clear();
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

      final rawExtension = picked.name.contains('.')
          ? picked.name.split('.').last
          : 'jpg';
      // The picker's file name is not ours: only a plain, short extension
      // rides along, so the stored name always passes [isSafeName].
      final extension = RegExp(r'^[A-Za-z0-9]{1,8}$').hasMatch(rawExtension)
          ? rawExtension
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
    if (!isSafeName(fileName)) {
      debugPrint('Image cache write refused: unsafe file name');
      return null;
    }
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
    final path = await resolve(fileName);
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
