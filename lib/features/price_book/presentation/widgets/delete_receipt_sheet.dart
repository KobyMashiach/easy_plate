import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';

/// What to delete: the receipt alone (its prices stay in the book) or the
/// receipt with every price read from it. Resolves null when dismissed.
Future<bool?> showDeleteReceiptSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
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
            Text(t.receipt.deleteReceipt, style: AppTextStyles.headlineMd),
            const SizedBox(height: AppSpacing.gutter),
            ClayCard(
              radius: AppRadius.md,
              padding: const EdgeInsets.all(AppSpacing.gutter),
              onTap: () => Navigator.of(sheetContext).pop(true),
              child: Row(
                children: [
                  Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.receipt.deleteReceiptOnly,
                          style: AppTextStyles.bodyMd,
                        ),
                        Text(
                          t.receipt.deleteReceiptOnlyHint,
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            ClayCard(
              radius: AppRadius.md,
              padding: const EdgeInsets.all(AppSpacing.gutter),
              onTap: () => Navigator.of(sheetContext).pop(false),
              child: Row(
                children: [
                  Icon(Icons.delete_sweep_rounded, color: AppColors.error),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      t.receipt.deleteReceiptAndPrices,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
