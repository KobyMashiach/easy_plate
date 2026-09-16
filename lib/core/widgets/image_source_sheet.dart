import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../features/recipe_ingestion/domain/repositories/recipe_ingestion_repository.dart';
import '../../features/recipe_ingestion/domain/usecases/generate_image_usecase.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import '../services/image_storage_service.dart';
import '../utils/i18n/strings.g.dart';
import 'app_dialog.dart';
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
///
/// [aiPrompt] adds a "create with AI" row that asks the image model for a
/// picture and stores it like a picked one. Left null where a generated
/// image makes no sense — a profile photo. [aiPromptPicker] instead lets the
/// user shape the prompt first (a book cover's theme and subject); it
/// returns null when they back out.
Future<ImagePickResult?> showImageSourceSheet(
  BuildContext context, {
  required bool hasImage,
  String? aiPrompt,
  Future<String?> Function(BuildContext context)? aiPromptPicker,
}) {
  assert(
    aiPrompt == null || aiPromptPicker == null,
    'one way to get a prompt, not two',
  );
  return showModalBottomSheet<ImagePickResult>(
    context: context,
    builder: (sheetContext) => _ImageSourceSheet(
      hasImage: hasImage,
      aiPrompt: aiPrompt,
      aiPromptPicker: aiPromptPicker,
    ),
  );
}

class _ImageSourceSheet extends StatefulWidget {
  final bool hasImage;
  final String? aiPrompt;
  final Future<String?> Function(BuildContext context)? aiPromptPicker;

  const _ImageSourceSheet({
    required this.hasImage,
    required this.aiPrompt,
    required this.aiPromptPicker,
  });

  bool get offersAi => aiPrompt != null || aiPromptPicker != null;

  @override
  State<_ImageSourceSheet> createState() => _ImageSourceSheetState();
}

class _ImageSourceSheetState extends State<_ImageSourceSheet> {
  static const _uuid = Uuid();
  bool _generating = false;
  bool _failed = false;

  Future<void> _pick(ImageSource source) async {
    // The picker's own UI covers the wait for it; the copy to disk after it
    // returns is ours to show.
    final fileName = await AppDialog.busy(
      context,
      () => ImageStorageService().pickAndStore(source),
    );
    if (!mounted) return;
    Navigator.of(
      context,
    ).pop(fileName == null ? null : ImagePickResult.picked(fileName));
  }

  Future<void> _generate() async {
    final prompt = widget.aiPrompt ?? await widget.aiPromptPicker!(context);
    if (prompt == null || !mounted) return;
    setState(() {
      _generating = true;
      _failed = false;
    });
    try {
      final bytes =
          await GenerateImageUseCase(context.read<RecipeIngestionRepository>())(
            prompt,
          ).timeout(const Duration(seconds: 60));
      final fileName = '${_uuid.v4()}.jpg';
      final stored = await ImageStorageService().storeBytes(fileName, bytes);
      if (!mounted) return;
      if (stored == null) throw StateError('image not stored');
      Navigator.of(context).pop(ImagePickResult.picked(fileName));
    } catch (e) {
      debugPrint('AI image failed: $e');
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // While the picture is on its way the sheet stays put: a tap outside or
    // a back gesture would drop an image that was already paid for.
    return PopScope(
      canPop: !_generating,
      child: SafeArea(
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
                widget.hasImage ? t.image.change : t.image.add,
                style: AppTextStyles.headlineMd,
              ),
              const SizedBox(height: AppSpacing.gutter),
              if (_generating)
                // The whole sheet becomes the progress state: the other rows
                // would only race the picture that is already on its way.
                ClayCard(
                  radius: AppRadius.md,
                  padding: const EdgeInsets.all(AppSpacing.gutter),
                  color: AppColors.primaryFixed,
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          t.image.generating,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.onPrimaryFixed,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                _SourceTile(
                  icon: Icons.photo_library_rounded,
                  label: t.image.gallery,
                  onTap: () => _pick(ImageSource.gallery),
                ),
                const SizedBox(height: AppSpacing.base),
                _SourceTile(
                  icon: Icons.photo_camera_rounded,
                  label: t.image.camera,
                  onTap: () => _pick(ImageSource.camera),
                ),
                if (widget.offersAi) ...[
                  const SizedBox(height: AppSpacing.base),
                  _SourceTile(
                    icon: Icons.auto_awesome_rounded,
                    label: t.image.generate,
                    highlighted: true,
                    onTap: _generate,
                  ),
                  if (_failed) ...[
                    const SizedBox(height: AppSpacing.base),
                    Text(
                      t.image.generateFailed,
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ],
                if (widget.hasImage) ...[
                  const SizedBox(height: AppSpacing.base),
                  _SourceTile(
                    icon: Icons.delete_outline_rounded,
                    label: t.image.remove,
                    isDestructive: true,
                    onTap: () => Navigator.of(
                      context,
                    ).pop(const ImagePickResult.removed()),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  /// The AI row stands out from the two ordinary sources.
  final bool highlighted;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : AppColors.primary;

    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.gutter),
      color: highlighted ? AppColors.primaryFixed : null,
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
