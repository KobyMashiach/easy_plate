import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../domain/share_code_entity.dart';

/// The camera, until a share QR is in frame. Pops with the eight-letter
/// code; anything else in the picture is ignored.
class ScanShareCodePage extends StatefulWidget {
  const ScanShareCodePage({super.key});

  @override
  State<ScanShareCodePage> createState() => _ScanShareCodePageState();
}

class _ScanShareCodePageState extends State<ScanShareCodePage> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final barcode in capture.barcodes) {
      final code = ShareCodeEntity.parse(barcode.rawValue ?? '');
      if (code == null) continue;
      _done = true;
      Navigator.of(context).pop(code);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClayScaffold(
      appBar: ClayTopAppBar(
        title: t.shareCode.scanQr,
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingTap: () => Navigator.of(context).maybePop(),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // A window the size of a code, so the eye knows where to aim.
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.xl,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                t.shareCode.scanHint,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
