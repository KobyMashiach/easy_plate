import 'dart:io';

import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../services/image_storage_service.dart';
import '../../sync/recipe_image_store.dart';

/// Shows a stored photo, falling back to a tinted medallion with [fallbackIcon]
/// when the item has no image yet (or the file has gone missing).
///
/// When the file is not on this device but [remotePath] says where it lives,
/// it is fetched once into the local image directory and read from disk from
/// then on — so a shared or restored recipe costs one download, not one per
/// build, and works offline afterwards.
class ClayImage extends StatefulWidget {
  final String? fileName;

  /// Firebase Storage path of the same photo, for a recipe that came from
  /// another account or another device. Null for one taken here.
  final String? remotePath;

  final IconData fallbackIcon;
  final double radius;
  final double? fallbackIconSize;
  final BoxFit fit;

  /// Null reads as the theme's primaryFixed.
  final Color? tint;

  const ClayImage({
    super.key,
    required this.fileName,
    this.remotePath,
    this.fallbackIcon = Icons.restaurant_menu_rounded,
    this.radius = AppRadius.std,
    this.fallbackIconSize,
    this.fit = BoxFit.cover,
    this.tint,
  });

  @override
  State<ClayImage> createState() => _ClayImageState();
}

class _ClayImageState extends State<ClayImage> {
  String? _path;

  /// The disk is being asked about a name not met yet. Drawn as the bare
  /// tint, not the "no photo" medallion: a photo that is on disk must not
  /// flash as missing while the check (or the startup listing) is out.
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(ClayImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileName != widget.fileName ||
        oldWidget.remotePath != widget.remotePath) {
      _resolve();
    }
  }

  /// Assigns [_path] directly rather than through `setState`: both callers are
  /// already inside a build cycle. Only the download's completion, which lands
  /// later, has to ask for a rebuild.
  void _resolve() {
    _path = ImageStorageService().pathFor(widget.fileName);
    _checking = false;
    if (_path != null) return;

    final fileName = widget.fileName;
    final remote = widget.remotePath;
    if (fileName == null) return;

    // Off the build path: a name not met yet is checked on disk first (the
    // tint holds meanwhile), then, with a remote copy, fetched when it is
    // not there — the medallion shows for the length of a download.
    _checking = true;
    ImageStorageService().resolve(fileName).then((local) {
      // The widget may be long gone by the time a slow connection answers, and
      // the photo may have been swapped out from under it in the meantime.
      if (!mounted || widget.fileName != fileName) return;
      if (local != null || remote == null) {
        setState(() {
          _checking = false;
          _path = local;
        });
        return;
      }
      setState(() => _checking = false);
      RecipeImageStore().ensureCached(fileName, remote).then((path) {
        if (!mounted || path == null || widget.fileName != fileName) return;
        setState(() => _path = path);
      });
    });
  }

  Widget _fallback(BorderRadius borderRadius, {bool icon = true}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: widget.tint ?? AppColors.primaryFixed,
        borderRadius: borderRadius,
      ),
      child: icon
          ? Center(
              child: Icon(
                widget.fallbackIcon,
                size: widget.fallbackIconSize,
                color: AppColors.primary,
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(widget.radius);
    final path = _path;

    if (path == null) return _fallback(borderRadius, icon: !_checking);

    // Photos are stored up to 1600px wide; a card thumbnail is a tenth of
    // that. Decoding at the drawn width keeps a grid of them to a fraction
    // of the memory, and a fraction of the decode time per scroll.
    final ratio = MediaQuery.devicePixelRatioOf(context);
    return ClipRRect(
      borderRadius: borderRadius,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final cacheWidth = width.isFinite && width > 0
              ? (width * ratio).ceil()
              : null;
          return Image.file(
            File(path),
            fit: widget.fit,
            width: double.infinity,
            height: double.infinity,
            cacheWidth: cacheWidth,
            // A file can vanish between the existence check and the decode.
            errorBuilder: (context, error, stack) => _fallback(borderRadius),
          );
        },
      ),
    );
  }
}
