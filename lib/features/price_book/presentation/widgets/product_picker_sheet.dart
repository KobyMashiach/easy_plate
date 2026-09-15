import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../domain/entities/price_record_entity.dart';
import '../../domain/repositories/price_book_repository.dart';
import 'add_price_dialog.dart';
import 'price_widgets.dart';

/// Every product the price book knows, latest price each, searchable.
/// Resolves with the picked record, or null.
Future<PriceRecordEntity?> showProductPickerSheet(BuildContext context) {
  final repository = context.read<PriceBookRepository>();
  return showModalBottomSheet<PriceRecordEntity>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ProductPicker(repository: repository),
  );
}

/// One line per product and unit: the most recent record.
List<PriceRecordEntity> latestPerProduct(Iterable<PriceRecordEntity> records) {
  final latest = <String, PriceRecordEntity>{};
  for (final r in records) {
    final key = '${r.normalizedName}|${r.unit.name}';
    if (!latest.containsKey(key) ||
        r.purchasedAt.isAfter(latest[key]!.purchasedAt)) {
      latest[key] = r;
    }
  }
  return latest.values.toList()..sort((a, b) => a.name.compareTo(b.name));
}

class _ProductPicker extends StatefulWidget {
  final PriceBookRepository repository;

  const _ProductPicker({required this.repository});

  @override
  State<_ProductPicker> createState() => _ProductPickerState();
}

class _ProductPickerState extends State<_ProductPicker> {
  List<PriceRecordEntity> _products = const [];
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    widget.repository.getRecords().then((records) {
      if (!mounted) return;
      setState(() {
        _products = latestPerProduct(records);
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final shown = _products
        .where((p) => _query.isEmpty || p.name.contains(_query))
        .toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.marginMobile,
          0,
          AppSpacing.marginMobile,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.marginMobile,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.receipt.pickerTitle, style: AppTextStyles.headlineMd),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              autofocus: true,
              style: AppTextStyles.bodyMd,
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: InputDecoration(
                hintText: t.receipt.search,
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.45,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : shown.isEmpty
                  ? ClayEmptyState(
                      icon: Icons.sell_rounded,
                      message: t.receipt.noPrices,
                    )
                  : ListView.separated(
                      itemCount: shown.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.base),
                      itemBuilder: (context, i) {
                        final r = shown[i];
                        return ClayCard(
                          radius: AppRadius.md,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.gutter,
                            vertical: AppSpacing.sm,
                          ),
                          onTap: () => Navigator.of(context).pop(r),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  r.name,
                                  style: AppTextStyles.bodyMd,
                                ),
                              ),
                              Text(
                                '${priceLabel(r.unitPrice, currency: r.currency)} ${priceUnitLabel(r.unit)}',
                                style: AppTextStyles.labelMd.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w800,
                                  fontVariations: const [
                                    FontVariation('wght', 800),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
