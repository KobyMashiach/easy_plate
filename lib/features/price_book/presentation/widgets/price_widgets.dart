import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../domain/price_estimator.dart';

/// A purchase date as the app's language writes it — "1.11.2026" in
/// Hebrew, "01/11/2026" in French. A bare `DateFormat.yMd()` uses intl's
/// en_US default whatever the language, so a Hebrew receipt from the 1st of
/// November read as January the 11th.
String purchaseDateLabel(DateTime date) =>
    DateFormat.yMd(LocaleSettings.currentLocale.languageCode).format(date);

/// "₪7.20" — two decimals, the shekel in front whatever the locale, since
/// every receipt in the app is Israeli so far.
String priceLabel(double amount, {String currency = 'ILS'}) =>
    '${currencySymbol(currency)}${amount.toStringAsFixed(2)}';

/// The mark a price is written with: ₪ unless the receipt said otherwise.
/// The scan returns any ISO 4217 code (a Russian or British receipt), so a
/// currency without a sign here is written as its code — never as ₪, which
/// would pass roubles off as shekels.
String currencySymbol(String currency) =>
    switch (currency.trim().toUpperCase()) {
      '' || 'ILS' => '₪',
      'USD' => r'$',
      'EUR' => '€',
      'GBP' => '£',
      'RUB' => '₽',
      final code => '$code ',
    };

/// The price beside a grocery line: the figure with a small mark of where
/// it came from, or a muted "no data".
class PriceChip extends StatelessWidget {
  final PriceEstimate estimate;
  final double multiplier;

  const PriceChip({super.key, required this.estimate, this.multiplier = 1});

  @override
  Widget build(BuildContext context) {
    final price = estimate.unitPrice;
    if (price == null) {
      return Text(
        t.receipt.noData,
        style: AppTextStyles.labelSm.copyWith(color: AppColors.outlineVariant),
      );
    }
    final community = estimate.basis == PriceBasis.community;
    return Tooltip(
      message: community ? t.receipt.fromCommunity : t.receipt.fromReceipt,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            community ? Icons.groups_rounded : Icons.receipt_long_rounded,
            size: 13,
            color: AppColors.outline,
          ),
          const SizedBox(width: 3),
          Text(
            priceLabel(price * multiplier, currency: estimate.currency),
            style: AppTextStyles.labelMd.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w800,
              fontVariations: const [FontVariation('wght', 800)],
            ),
          ),
        ],
      ),
    );
  }
}

/// The list's estimated cost, with the honesty line under it.
class GroceryCostCard extends StatelessWidget {
  final GroceryCostSummary summary;
  final VoidCallback onScanReceipt;

  const GroceryCostCard({
    super.key,
    required this.summary,
    required this.onScanReceipt,
  });

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.gutter),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.warmAccent.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.payments_rounded, color: AppColors.warmAccent),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.receipt.estimatedTotal,
                  style: AppTextStyles.labelMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                Text(
                  summary.hasAny
                      ? priceLabel(
                          summary.knownTotal,
                          currency: summary.currency,
                        )
                      : t.receipt.noData,
                  style: AppTextStyles.headlineMd.copyWith(
                    fontWeight: FontWeight.w800,
                    fontVariations: const [FontVariation('wght', 800)],
                  ),
                ),
                Text(
                  summary.unpricedItems > 0
                      ? '${t.receipt.estimated} · ${t.receipt.unpriced(count: summary.unpricedItems)}'
                      : t.receipt.estimated,
                  style: AppTextStyles.labelSm.copyWith(
                    color: AppColors.outline,
                  ),
                ),
              ],
            ),
          ),
          ClayIconButton(
            icon: Icons.document_scanner_rounded,
            filled: true,
            size: 44,
            tooltip: t.receipt.title,
            onTap: onScanReceipt,
          ),
        ],
      ),
    );
  }
}
