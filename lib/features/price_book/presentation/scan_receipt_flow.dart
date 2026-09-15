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
  final scanning = AppDialog.progress(
    message: t.receipt.scanning,
  ).show(context);
  try {
    final scan = await ScanReceiptUseCase(context.read())(
      pages,
    ).timeout(const Duration(seconds: 120));
    if (!context.mounted) return null;
    Navigator.of(context, rootNavigator: true).pop();
    await scanning;
    if (!context.mounted) return null;
    return context.pushNamed<int>(
      Routing.receiptReview,
      extra: ReceiptReviewArgs(scan: scan, pages: pages),
    );
  } catch (e) {
    debugPrint('Receipt scan failed: $e');
    if (!context.mounted) return null;
    Navigator.of(context, rootNavigator: true).pop();
    await scanning;
    if (context.mounted) {
      AppDialog.error(message: t.receipt.scanFailed).show(context);
    }
    return null;
  }
}
