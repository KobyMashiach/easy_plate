import 'dart:io';

import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../services/image_storage_service.dart';

/// Shows a stored photo, falling back to a tinted medallion with [fallbackIcon]
/// when the item has no image yet (or the file has gone missing).
class ClayImage extends StatelessWidget {
  final String? fileName;
  final IconData fallbackIcon;
  final double radius;
  final double? fallbackIconSize;
  final BoxFit fit;
  final Color tint;

  const ClayImage({
    super.key,
    required this.fileName,
    this.fallbackIcon = Icons.restaurant_menu_rounded,
    this.radius = AppRadius.std,
    this.fallbackIconSize,
    this.fit = BoxFit.cover,
    this.tint = AppColors.primaryFixed,
  });

  @override
  Widget build(BuildContext context) {
    final path = ImageStorageService().pathFor(fileName);
    final borderRadius = BorderRadius.circular(radius);

    if (path == null) {
      return DecoratedBox(
        decoration: BoxDecoration(color: tint, borderRadius: borderRadius),
        child: Center(
          child: Icon(
            fallbackIcon,
            size: fallbackIconSize,
            color: AppColors.primary,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.file(
        File(path),
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        // A file can vanish between the existsSync check and the decode.
        errorBuilder: (context, error, stack) => DecoratedBox(
          decoration: BoxDecoration(color: tint, borderRadius: borderRadius),
          child: Center(
            child: Icon(
              fallbackIcon,
              size: fallbackIconSize,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
