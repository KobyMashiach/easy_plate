import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/services/image_storage_service.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../domain/entities/receipt_entity.dart';

/// The receipt as it was photographed: every page, top to bottom, each
/// zoomable. A PDF receipt shows a note instead — the app has no PDF
/// renderer, and the lines it read are on the details page anyway.
class ReceiptImagesPage extends StatelessWidget {
  final ReceiptEntity receipt;

  const ReceiptImagesPage({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    final paths = [
      for (final name in receipt.imageFileNames)
        if (!name.endsWith('.pdf')) ?ImageStorageService().pathFor(name),
    ];
    final note = receipt.isPdf
        ? t.receipt.pdfFile
        : paths.isEmpty
        ? t.receipt.noImage
        : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: note != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          note,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : InteractiveViewer(
                      minScale: 1,
                      maxScale: 5,
                      child: ListView(
                        padding: EdgeInsets.only(
                          top: MediaQuery.paddingOf(context).top + 64,
                          bottom: AppSpacing.lg,
                        ),
                        children: [
                          for (final path in paths)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.base,
                              ),
                              child: Image.file(
                                File(path),
                                fit: BoxFit.fitWidth,
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
            PositionedDirectional(
              top: MediaQuery.paddingOf(context).top + AppSpacing.base,
              end: AppSpacing.gutter,
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
