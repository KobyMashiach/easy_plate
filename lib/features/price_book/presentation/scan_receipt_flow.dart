import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/i18n/strings.g.dart';
import '../../../core/utils/routing/routing.dart';
import '../../../core/widgets/app_dialog.dart';
import '../domain/usecases/scan_receipt_usecase.dart';
import 'pages/receipt_review_page.dart';
import 'widgets/receipt_source_sheet.dart';

/// Photographs or loads a receipt, reads it, opens the review. Resolves to
/// the number of prices saved (null when nothing was), so the caller can
/// refresh whatever it shows.
Future<int?> scanReceiptFlow(BuildContext context) async {
  final pages = await showReceiptSourceSheet(context);
  if (pages == null || pages.isEmpty || !context.mounted) return null;
  // The card is removed by identity (AppDialog.busy), not by popping the
  // root navigator's top: during a scan of up to two minutes a deep link
  // or another dialog may have landed above it, and that one would have
  // been closed instead, leaving the spinner up.
  final scanReceipt = ScanReceiptUseCase(context.read());
  try {
    final scan = await AppDialog.busy(
      context,
      () => scanReceipt(pages).timeout(const Duration(seconds: 120)),
      message: t.receipt.scanning,
    );
    if (!context.mounted) return null;
    return context.pushNamed<int>(
      Routing.receiptReview,
      extra: ReceiptReviewArgs(scan: scan, pages: pages),
    );
  } catch (e) {
    debugPrint('Receipt scan failed: $e');
    if (context.mounted) {
      AppDialog.error(message: t.receipt.scanFailed).show(context);
    }
    return null;
  }
}
