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
  final Color tint;

  const ClayImage({
    super.key,
    required this.fileName,
    this.remotePath,
    this.fallbackIcon = Icons.restaurant_menu_rounded,
    this.radius = AppRadius.std,
    this.fallbackIconSize,
    this.fit = BoxFit.cover,
    this.tint = AppColors.primaryFixed,
  });

  @override
  State<ClayImage> createState() => _ClayImageState();
}

class _ClayImageState extends State<ClayImage> {
  String? _path;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(ClayImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileName != widget.fileName || oldWidget.remotePath != widget.remotePath) {
      _resolve();
    }
  }

  /// Assigns [_path] directly rather than through `setState`: both callers are
  /// already inside a build cycle. Only the download's completion, which lands
  /// later, has to ask for a rebuild.
  void _resolve() {
    _path = ImageStorageService().pathFor(widget.fileName);
    if (_path != null) return;

    final fileName = widget.fileName;
    final remote = widget.remotePath;
    if (fileName == null || remote == null) return;

    RecipeImageStore().ensureCached(fileName, remote).then((path) {
      // The widget may be long gone by the time a slow connection answers, and
      // the photo may have been swapped out from under it in the meantime.
      if (!mounted || path == null || widget.fileName != fileName) return;
      setState(() => _path = path);
    });
  }

  Widget _fallback(BorderRadius borderRadius) {
    return DecoratedBox(
      decoration: BoxDecoration(color: widget.tint, borderRadius: borderRadius),
      child: Center(
        child: Icon(
          widget.fallbackIcon,
          size: widget.fallbackIconSize,
          color: AppColors.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(widget.radius);
    final path = _path;

    if (path == null) return _fallback(borderRadius);

    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.file(
        File(path),
        fit: widget.fit,
        width: double.infinity,
        height: double.infinity,
        // A file can vanish between the existsSync check and the decode.
        errorBuilder: (context, error, stack) => _fallback(borderRadius),
      ),
    );
  }
}
