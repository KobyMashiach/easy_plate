import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../domain/entities/dashboard_entities.dart';

/// Edits the price table in place. Returns the new table, or null when the
/// administrator backs out. Models seen in the traffic but missing from the
/// table are offered with the fallback price so they can be pinned.
Future<AiPricing?> showPricingSheet(
  BuildContext context, {
  required AiPricing pricing,
  required Iterable<String> seenModels,
}) {
  final keys = <String>{...pricing.models.keys, ...seenModels}.toList()..sort();
  return showModalBottomSheet<AiPricing>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: _PricingSheet(pricing: pricing, keys: keys),
    ),
  );
}

class _PricingSheet extends StatefulWidget {
  final AiPricing pricing;
  final List<String> keys;

  const _PricingSheet({required this.pricing, required this.keys});

  @override
  State<_PricingSheet> createState() => _PricingSheetState();
}

class _PricingSheetState extends State<_PricingSheet> {
  late final Map<String, List<TextEditingController>> _fields = {
    for (final key in widget.keys)
      key: [
        for (final v in [
          widget.pricing.priceFor(key).inputPerMillion,
          widget.pricing.priceFor(key).outputPerMillion,
          widget.pricing.priceFor(key).cachedPerMillion,
          widget.pricing.priceFor(key).imageOutputRate,
        ])
          TextEditingController(text: _trim(v)),
      ],
  };
  late final _search = TextEditingController(
    text: _trim(widget.pricing.searchPerThousand),
  );

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  @override
  void dispose() {
    for (final list in _fields.values) {
      for (final c in list) {
        c.dispose();
      }
    }
    _search.dispose();
    super.dispose();
  }

  double _num(TextEditingController c, double fallback) =>
      double.tryParse(c.text.trim().replaceAll(',', '.')) ?? fallback;

  void _save() {
    final models = <String, ModelPrice>{};
    _fields.forEach((key, c) {
      final was = widget.pricing.priceFor(key);
      models[key] = ModelPrice(
        inputPerMillion: _num(c[0], was.inputPerMillion),
        outputPerMillion: _num(c[1], was.outputPerMillion),
        cachedPerMillion: _num(c[2], was.cachedPerMillion),
        imageOutputPerMillion: key.contains('image')
            ? _num(c[3], was.imageOutputRate)
            : null,
      );
    });
    Navigator.of(context).pop(
      AiPricing(
        models: models,
        fallback: models['gemini-3_8-flash'] ?? widget.pricing.fallback,
        usdToIls: widget.pricing.usdToIls,
        rateUpdatedAt: widget.pricing.rateUpdatedAt,
        searchPerThousand: _num(_search, widget.pricing.searchPerThousand),
      ),
    );
  }

  Widget _field(TextEditingController c, String label) => Expanded(
    child: TextField(
      controller: c,
      style: AppTextStyles.bodyMd,
      textDirection: TextDirection.ltr,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, isDense: true),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final s = t.adminDashboard;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.marginMobile,
          AppSpacing.md,
          AppSpacing.marginMobile,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.editPricing, style: AppTextStyles.headlineMd),
            const SizedBox(height: AppSpacing.xs),
            Text(
              s.pricingHint,
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            for (final key in widget.keys) ...[
              const SizedBox(height: AppSpacing.gutter),
              Text(
                AiPricing.displayName(key),
                textDirection: TextDirection.ltr,
                style: AppTextStyles.labelMd,
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  _field(_fields[key]![0], s.priceInput),
                  const SizedBox(width: AppSpacing.base),
                  _field(_fields[key]![1], s.priceOutput),
                  const SizedBox(width: AppSpacing.base),
                  _field(_fields[key]![2], s.priceCached),
                  if (key.contains('image')) ...[
                    const SizedBox(width: AppSpacing.base),
                    _field(_fields[key]![3], s.priceImageOutput),
                  ],
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.gutter),
            Row(children: [_field(_search, s.searchPrice)]),
            const SizedBox(height: AppSpacing.md),
            ClayButton(
              label: t.common.save,
              icon: Icons.save_rounded,
              expanded: true,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
