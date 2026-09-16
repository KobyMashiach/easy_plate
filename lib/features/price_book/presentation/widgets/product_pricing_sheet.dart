import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../domain/entities/price_record_entity.dart';
import '../../domain/entities/product_pricing_entity.dart';
import '../../domain/entities/receipt_entity.dart';
import '../../domain/repositories/price_book_repository.dart';
import '../../domain/usecases/price_book_usecases.dart';
import 'add_price_dialog.dart';
import 'price_widgets.dart';

/// One product's whole story and the choice of which price counts: every
/// record (store, date, price), then latest / average / one store / chosen
/// receipts. The choice is what the grocery list and the estimates follow.
/// Resolves true when anything changed.
Future<bool> showProductPricingSheet(
  BuildContext context, {
  required PriceRecordEntity product,
}) async {
  final repository = context.read<PriceBookRepository>();
  final changed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) =>
        _ProductPricingSheet(product: product, repository: repository),
  );
  return changed ?? false;
}

class _ProductPricingSheet extends StatefulWidget {
  final PriceRecordEntity product;
  final PriceBookRepository repository;

  const _ProductPricingSheet({required this.product, required this.repository});

  @override
  State<_ProductPricingSheet> createState() => _ProductPricingSheetState();
}

class _ProductPricingSheetState extends State<_ProductPricingSheet> {
  List<PriceRecordEntity> _records = const [];
  Map<String, ReceiptEntity> _receipts = const {};
  late ProductPricingEntity _policy;
  bool _loading = true;
  bool _changed = false;

  String get _key => ProductPricingEntity.keyFor(
    widget.product.normalizedName,
    widget.product.unit,
  );

  @override
  void initState() {
    super.initState();
    _policy = ProductPricingEntity(key: _key, mode: PricingMode.latest);
    _load();
  }

  Future<void> _load() async {
    final all = await widget.repository.getRecords();
    final receipts = await widget.repository.getReceipts();
    final pricing = await widget.repository.getPricing();
    if (!mounted) return;
    setState(() {
      _records =
          all
              .where(
                (r) =>
                    r.normalizedName == widget.product.normalizedName &&
                    r.unit == widget.product.unit,
              )
              .toList()
            ..sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));
      _receipts = {for (final r in receipts) r.id: r};
      _policy = pricing[_key] ?? _policy;
      _loading = false;
    });
  }

  List<String> get _stores =>
      {for (final r in _records) ?r.store}.toList()..sort();

  Future<void> _save(ProductPricingEntity policy) async {
    setState(() => _policy = policy);
    if (policy.mode == PricingMode.latest) {
      await widget.repository.deletePricing(_key);
    } else {
      await widget.repository.savePricing(policy);
    }
    _changed = true;
  }

  Future<void> _deleteProduct() async {
    final ok = await AppDialog.warning(
      title: t.receipt.deleteProduct,
      message: t.receipt.deleteProductBody,
      confirmLabel: t.common.delete,
      cancelLabel: t.common.cancel,
      destructive: true,
    ).show(context);
    if (ok != true || !mounted) return;
    await AppDialog.busy(context, () async {
      for (final r in _records) {
        await DeletePriceRecordUseCase(widget.repository)(r.id);
      }
      await widget.repository.deletePricing(_key);
    });
    if (mounted) Navigator.of(context).pop(true);
  }

  String _receiptLabel(String receiptId) {
    if (receiptId == PriceRecordEntity.manualReceiptId) {
      return t.receipt.manualSource;
    }
    final r = _receipts[receiptId];
    if (r == null) {
      return DateFormat.yMd().format(
        _records.firstWhere((x) => x.receiptId == receiptId).purchasedAt,
      );
    }
    return '${r.store ?? t.receipt.noStore} · ${DateFormat.yMd().format(r.purchasedAt)}';
  }

  @override
  Widget build(BuildContext context) {
    final inUse =
        _policy.resolve(_records) ??
        (_records.isEmpty ? null : _records.first.unitPrice);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.marginMobile,
          0,
          AppSpacing.marginMobile,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.marginMobile,
        ),
        child: _loading
            ? const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.product.name,
                            style: AppTextStyles.headlineMd,
                          ),
                        ),
                        IconButton(
                          tooltip: t.receipt.addPrice,
                          icon: Icon(
                            Icons.add_circle_outline_rounded,
                            color: AppColors.primary,
                          ),
                          onPressed: () async {
                            final saved = await showAddPriceDialog(
                              context,
                              name: widget.product.name,
                              unit: widget.product.unit,
                            );
                            if (saved) {
                              _changed = true;
                              await _load();
                            }
                          },
                        ),
                        IconButton(
                          tooltip: t.receipt.deleteProduct,
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.error,
                          ),
                          onPressed: _deleteProduct,
                        ),
                      ],
                    ),
                    if (inUse != null)
                      Text(
                        t.receipt.pricingActive(
                          price:
                              '${priceLabel(inUse)} ${priceUnitLabel(widget.product.unit)}',
                        ),
                        style: AppTextStyles.labelMd.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.gutter),
                    ClaySectionHeader(title: t.receipt.pricingTitle),
                    const SizedBox(height: AppSpacing.base),
                    Wrap(
                      spacing: AppSpacing.base,
                      runSpacing: AppSpacing.base,
                      children: [
                        _ModeChip(
                          label: t.receipt.pricingLatest,
                          selected: _policy.mode == PricingMode.latest,
                          onTap: () => _save(
                            ProductPricingEntity(
                              key: _key,
                              mode: PricingMode.latest,
                            ),
                          ),
                        ),
                        _ModeChip(
                          label: t.receipt.pricingAverage,
                          selected: _policy.mode == PricingMode.average,
                          onTap: () => _save(
                            ProductPricingEntity(
                              key: _key,
                              mode: PricingMode.average,
                            ),
                          ),
                        ),
                        _ModeChip(
                          label: t.receipt.pricingStore,
                          selected: _policy.mode == PricingMode.store,
                          onTap: _stores.isEmpty
                              ? null
                              : () => _save(
                                  ProductPricingEntity(
                                    key: _key,
                                    mode: PricingMode.store,
                                    store: _policy.store ?? _stores.first,
                                  ),
                                ),
                        ),
                        _ModeChip(
                          label: t.receipt.pricingReceipts,
                          selected: _policy.mode == PricingMode.receipts,
                          onTap: () => _save(
                            ProductPricingEntity(
                              key: _key,
                              mode: PricingMode.receipts,
                              receiptIds: _policy.receiptIds.isEmpty
                                  ? [_records.first.receiptId]
                                  : _policy.receiptIds,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_policy.mode == PricingMode.store) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.base,
                        runSpacing: AppSpacing.base,
                        children: [
                          for (final store in _stores)
                            _ModeChip(
                              label: store,
                              selected: _policy.store == store,
                              onTap: () => _save(
                                ProductPricingEntity(
                                  key: _key,
                                  mode: PricingMode.store,
                                  store: store,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.gutter),
                    ClaySectionHeader(title: t.receipt.history),
                    const SizedBox(height: AppSpacing.base),
                    for (final r in _records)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        child: Row(
                          children: [
                            if (_policy.mode == PricingMode.receipts)
                              Checkbox(
                                value: _policy.receiptIds.contains(r.receiptId),
                                onChanged: (v) {
                                  final ids = {..._policy.receiptIds};
                                  if (v == true) {
                                    ids.add(r.receiptId);
                                  } else {
                                    ids.remove(r.receiptId);
                                  }
                                  if (ids.isEmpty) return;
                                  _save(
                                    ProductPricingEntity(
                                      key: _key,
                                      mode: PricingMode.receipts,
                                      receiptIds: ids.toList(),
                                    ),
                                  );
                                },
                              ),
                            Expanded(
                              child: Text(
                                _receiptLabel(r.receiptId),
                                style: AppTextStyles.labelMd.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Text(
                              priceLabel(r.unitPrice, currency: r.currency),
                              style: AppTextStyles.labelMd.copyWith(
                                fontWeight: FontWeight.w800,
                                fontVariations: const [
                                  FontVariation('wght', 800),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: AppSpacing.gutter),
                    ClayButton(
                      label: MaterialLocalizations.of(context).closeButtonLabel,
                      expanded: true,
                      onPressed: () => Navigator.of(context).pop(_changed),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.base,
        ),
        decoration: ShapeDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceContainerLow,
          shape: StadiumBorder(
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.outlineVariant,
            ),
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMd.copyWith(
            color: selected
                ? AppColors.onPrimary
                : disabled
                ? AppColors.outlineVariant
                : AppColors.tertiary,
          ),
        ),
      ),
    );
  }
}
