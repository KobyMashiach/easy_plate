import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../../recipe_ingestion/data/datasources/recipe_ai_datasource.dart'
    show ReceiptPage;
import '../pages/receipt_camera_page.dart';

/// Where the receipt comes from: the camera (as many shots as it takes — a
/// long receipt is several overlapping photos), the gallery, or a PDF.
/// Returns the pages to scan, or null when the user backs out.
Future<List<ReceiptPage>?> showReceiptSourceSheet(BuildContext context) {
  return showModalBottomSheet<List<ReceiptPage>>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _ReceiptSourceSheet(),
  );
}

class _ReceiptSourceSheet extends StatefulWidget {
  const _ReceiptSourceSheet();

  @override
  State<_ReceiptSourceSheet> createState() => _ReceiptSourceSheetState();
}

class _ReceiptSourceSheetState extends State<_ReceiptSourceSheet> {
  static final _picker = ImagePicker();
  final _pages = <ReceiptPage>[];
  bool _busy = false;

  /// Set false the first time our viewfinder reports it cannot open, so the
  /// next attempt goes straight to the system camera.
  bool get _cameraAvailable => ReceiptCameraPage.lastOpenSucceeded;

  // Receipts are text: 1600px at quality 80 keeps every digit legible and
  // stays well under a megabyte, so a five-photo receipt still fits one
  // request.
  Future<ReceiptPage?> _photo(XFile? file) async {
    if (file == null) return null;
    return ReceiptPage(bytes: await file.readAsBytes(), mimeType: 'image/jpeg');
  }

  /// Our own viewfinder with auto-capture; the system camera only when it
  /// cannot run (no permission, no camera).
  Future<void> _shoot() async {
    setState(() => _busy = true);
    try {
      final bytes = await ReceiptCameraPage.open(context);
      if (!mounted) return;
      ReceiptPage? page;
      if (bytes != null) {
        page = ReceiptPage(bytes: bytes, mimeType: 'image/jpeg');
      } else if (!_cameraAvailable) {
        page = await _photo(
          await _picker.pickImage(
            source: ImageSource.camera,
            maxWidth: 1600,
            maxHeight: 2400,
            imageQuality: 80,
          ),
        );
      }
      if (page != null && mounted) setState(() => _pages.add(page!));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _gallery() async {
    setState(() => _busy = true);
    try {
      final files = await _picker.pickMultiImage(
        maxWidth: 1600,
        maxHeight: 2400,
        imageQuality: 80,
      );
      for (final file in files) {
        final page = await _photo(file);
        if (page != null) _pages.add(page);
      }
      if (mounted && _pages.isNotEmpty) setState(() {});
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pdf() async {
    setState(() => _busy = true);
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      final path = files.isEmpty ? null : files.first.path;
      if (path == null) return;
      final bytes = await File(path).readAsBytes();
      if (!mounted) return;
      // A PDF is the whole receipt: it goes on its own.
      Navigator.of(
        context,
      ).pop([ReceiptPage(bytes: bytes, mimeType: 'application/pdf')]);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
            Text(t.receipt.title, style: AppTextStyles.headlineMd),
            const SizedBox(height: AppSpacing.xs),
            Text(
              t.receipt.subtitle,
              style: AppTextStyles.labelMd.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.gutter),
            if (_pages.isEmpty) ...[
              _Tile(
                icon: Icons.photo_camera_rounded,
                label: t.receipt.camera,
                hint: t.receipt.cameraHint,
                onTap: _busy ? null : _shoot,
              ),
              const SizedBox(height: AppSpacing.base),
              _Tile(
                icon: Icons.photo_library_rounded,
                label: t.receipt.gallery,
                onTap: _busy ? null : _gallery,
              ),
              const SizedBox(height: AppSpacing.base),
              _Tile(
                icon: Icons.picture_as_pdf_rounded,
                label: t.receipt.pdf,
                onTap: _busy ? null : _pdf,
              ),
            ] else ...[
              // Photos taken so far, then "one more" or "scan".
              Row(
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: AppSpacing.base,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Image.memory(
                          _pages[i].bytes,
                          width: 48,
                          height: 64,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      t.receipt.pagesCount(count: _pages.length),
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.gutter),
              _Tile(
                icon: Icons.add_a_photo_rounded,
                label: t.receipt.addPhoto,
                hint: t.receipt.cameraHint,
                onTap: _busy ? null : _shoot,
              ),
              const SizedBox(height: AppSpacing.gutter),
              ClayButton(
                label: t.receipt.scan,
                icon: Icons.document_scanner_rounded,
                expanded: true,
                onPressed: _busy
                    ? null
                    : () => Navigator.of(context).pop(List.of(_pages)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? hint;
  final VoidCallback? onTap;

  const _Tile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.gutter),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                if (hint != null)
                  Text(
                    hint!,
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
