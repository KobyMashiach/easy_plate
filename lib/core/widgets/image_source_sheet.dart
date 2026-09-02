import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import '../services/image_storage_service.dart';
import '../utils/i18n/strings.g.dart';
import 'clay/clay.dart';

/// Outcome of the photo sheet: a newly stored file name, or an explicit removal.
class ImagePickResult {
  final String? fileName;
  final bool removed;

  const ImagePickResult.picked(this.fileName) : removed = false;
  const ImagePickResult.removed() : fileName = null, removed = true;
}

/// Asks where the photo should come from, stores whatever is picked, and
/// returns the result. Null means the user backed out without changing
/// anything.
Future<ImagePickResult?> showImageSourceSheet(
  BuildContext context, {
  required bool hasImage,
}) {
  return showModalBottomSheet<ImagePickResult>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.marginMobile,
          0,
          AppSpacing.marginMobile,
          AppSpacing.marginMobile,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasImage ? t.image.change : t.image.add,
              style: AppTextStyles.headlineMd,
            ),
            const SizedBox(height: AppSpacing.gutter),
            _SourceTile(
              icon: Icons.photo_library_rounded,
              label: t.image.gallery,
              onTap: () async {
                final fileName =
                    await ImageStorageService().pickAndStore(ImageSource.gallery);
                if (!sheetContext.mounted) return;
                Navigator.of(sheetContext).pop(
                  fileName == null ? null : ImagePickResult.picked(fileName),
                );
              },
            ),
            const SizedBox(height: AppSpacing.base),
            _SourceTile(
              icon: Icons.photo_camera_rounded,
              label: t.image.camera,
              onTap: () async {
                final fileName =
                    await ImageStorageService().pickAndStore(ImageSource.camera);
                if (!sheetContext.mounted) return;
                Navigator.of(sheetContext).pop(
                  fileName == null ? null : ImagePickResult.picked(fileName),
                );
              },
            ),
            if (hasImage) ...[
              const SizedBox(height: AppSpacing.base),
              _SourceTile(
                icon: Icons.delete_outline_rounded,
                label: t.image.remove,
                isDestructive: true,
                onTap: () =>
                    Navigator.of(sheetContext).pop(const ImagePickResult.removed()),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.primary;

    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.gutter),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: AppTextStyles.bodyMd.copyWith(color: color)),
        ],
      ),
    );
  }
}
