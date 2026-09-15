import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/utils/routing/routing.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../domain/entities/price_record_entity.dart';
import '../../domain/entities/receipt_entity.dart';
import '../../domain/repositories/price_book_repository.dart';
import '../../domain/usecases/price_book_usecases.dart';
import '../scan_receipt_flow.dart';
import '../widgets/add_price_dialog.dart';
import '../widgets/delete_receipt_sheet.dart';
import '../widgets/product_pricing_sheet.dart';
import '../widgets/price_widgets.dart';
import '../../domain/entities/price_unit.dart';
import '../../../../core/services/image_storage_service.dart';

enum _ReceiptSort { date, store, total }

enum _PriceSort { name, date, price }

/// Everything the receipts taught the app: the receipts themselves, and
/// the latest price of every product, each sortable. Scanning and typing a
/// price start from here too.
class PriceBookPage extends StatefulWidget {
  const PriceBookPage({super.key});

  @override
  State<PriceBookPage> createState() => _PriceBookPageState();
}

class _PriceBookPageState extends State<PriceBookPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  List<ReceiptEntity> _receipts = const [];
  List<PriceRecordEntity> _records = const [];
  _ReceiptSort _receiptSort = _ReceiptSort.date;
  _PriceSort _priceSort = _PriceSort.name;
  String _query = '';
  bool _loading = true;
  bool _filtersOpen = false;
  String? _storeFilter;
  int? _periodDays;
  PriceUnit? _unitFilter;
  bool? _manualFilter;

  PriceBookRepository get _repository => context.read<PriceBookRepository>();

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final receipts = await GetReceiptsUseCase(_repository)();
    final records = await GetPriceRecordsUseCase(_repository)();
    if (!mounted) return;
    setState(() {
      _receipts = receipts;
      _records = records;
      _loading = false;
    });
  }

  List<String> get _stores =>
      {for (final r in _receipts) ?r.store}.toList()..sort();

  bool _inPeriod(DateTime at) =>
      _periodDays == null ||
      DateTime.now().difference(at).inDays <= _periodDays!;

  List<ReceiptEntity> get _sortedReceipts {
    final list = _receipts
        .where((r) => _storeFilter == null || r.store == _storeFilter)
        .where((r) => _inPeriod(r.purchasedAt))
        .toList();
    switch (_receiptSort) {
      case _ReceiptSort.date:
        list.sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));
      case _ReceiptSort.store:
        list.sort((a, b) => (a.store ?? '').compareTo(b.store ?? ''));
      case _ReceiptSort.total:
        list.sort((a, b) => b.total.compareTo(a.total));
    }
    return list;
  }

  /// One line per product: its most recent record.
  List<PriceRecordEntity> get _latestPrices {
    final latest = <String, PriceRecordEntity>{};
    for (final r in _records) {
      final key = '${r.normalizedName}|${r.unit.name}';
      if (!latest.containsKey(key) ||
          r.purchasedAt.isAfter(latest[key]!.purchasedAt)) {
        latest[key] = r;
      }
    }
    final list = latest.values
        .where((r) => _query.isEmpty || r.name.contains(_query))
        .where((r) => _unitFilter == null || r.unit == _unitFilter)
        .where(
          (r) =>
              _manualFilter == null ||
              (r.receiptId == PriceRecordEntity.manualReceiptId) ==
                  _manualFilter,
        )
        .toList();
    switch (_priceSort) {
      case _PriceSort.name:
        list.sort((a, b) => a.name.compareTo(b.name));
      case _PriceSort.date:
        list.sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));
      case _PriceSort.price:
        list.sort((a, b) => b.unitPrice.compareTo(a.unitPrice));
    }
    return list;
  }

  /// Every record of this product and unit, so it leaves the list for good.
  Future<void> _deleteProduct(PriceRecordEntity product) async {
    final ok = await AppDialog.warning(
      title: t.receipt.deleteProduct,
      message: t.receipt.deleteProductBody,
      confirmLabel: t.common.delete,
      cancelLabel: t.common.cancel,
      destructive: true,
    ).show(context);
    if (ok != true) return;
    final doomed = _records
        .where(
          (r) =>
              r.normalizedName == product.normalizedName &&
              r.unit == product.unit,
        )
        .toList();
    for (final r in doomed) {
      await DeletePriceRecordUseCase(_repository)(r.id);
    }
    await _load();
  }

  Future<void> _deleteReceipt(ReceiptEntity receipt) async {
    final keepRecords = await showDeleteReceiptSheet(context);
    if (keepRecords == null) return;
    await _repository.deleteReceipt(receipt.id, keepRecords: keepRecords);
    for (final f in receipt.imageFileNames) {
      await ImageStorageService().delete(f);
    }
    await _load();
  }

  Future<void> _deleteAll() async {
    final ok = await AppDialog.warning(
      title: t.receipt.deleteAll,
      message: t.receipt.deleteAllBody,
      confirmLabel: t.common.delete,
      cancelLabel: t.common.cancel,
      destructive: true,
    ).show(context);
    if (ok != true) return;
    await _repository.deleteAllRecords();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final receiptsTab = _tabs.index == 0;
    return ClayScaffold(
      appBar: ClayTopAppBar(
        title: t.receipt.priceBook,
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingTap: () => Navigator.of(context).maybePop(),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.marginMobile,
              AppSpacing.md,
              AppSpacing.marginMobile,
              0,
            ),
            child: ClayPageHeader(
              title: t.receipt.priceBook,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!receiptsTab && _records.isNotEmpty) ...[
                    ClayIconButton(
                      icon: Icons.delete_sweep_rounded,
                      size: 48,
                      tooltip: t.receipt.deleteAll,
                      onTap: _deleteAll,
                    ),
                    const SizedBox(width: AppSpacing.base),
                  ],
                  ClayIconButton(
                    icon: Icons.sell_rounded,
                    size: 48,
                    tooltip: t.receipt.addPrice,
                    onTap: () async {
                      if (await showAddPriceDialog(context)) _load();
                    },
                  ),
                  const SizedBox(width: AppSpacing.base),
                  ClayIconButton(
                    icon: Icons.document_scanner_rounded,
                    filled: true,
                    size: 48,
                    tooltip: t.receipt.title,
                    onTap: () async {
                      final saved = await scanReceiptFlow(context);
                      if (saved != null) _load();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.marginMobile,
            ),
            child: ClaySegmentedControl(
              segments: [
                ClaySegment(
                  label: t.receipt.receipts,
                  icon: Icons.receipt_long_rounded,
                ),
                ClaySegment(label: t.receipt.prices, icon: Icons.sell_rounded),
              ],
              selectedIndex: _tabs.index,
              onSelected: (i) => _tabs.animateTo(i),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.marginMobile,
            ),
            child: receiptsTab
                ? Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _SortRow<_ReceiptSort>(
                              values: _ReceiptSort.values,
                              selected: _receiptSort,
                              label: (s) => switch (s) {
                                _ReceiptSort.date => t.receipt.sortDate,
                                _ReceiptSort.store => t.receipt.sortStore,
                                _ReceiptSort.total => t.receipt.sortTotal,
                              },
                              onSelect: (s) => setState(() => _receiptSort = s),
                            ),
                          ),
                          _FilterButton(
                            active: _storeFilter != null || _periodDays != null,
                            open: _filtersOpen,
                            onTap: () =>
                                setState(() => _filtersOpen = !_filtersOpen),
                          ),
                        ],
                      ),
                      if (_filtersOpen) ...[
                        const SizedBox(height: AppSpacing.base),
                        _ChipRow<String?>(
                          values: [null, ..._stores],
                          selected: _storeFilter,
                          label: (s) => s ?? t.receipt.filterAll,
                          onSelect: (s) => setState(() => _storeFilter = s),
                        ),
                        const SizedBox(height: AppSpacing.base),
                        _ChipRow<int?>(
                          values: const [null, 30, 90],
                          selected: _periodDays,
                          label: (d) => switch (d) {
                            null => t.receipt.periodAll,
                            30 => t.receipt.period30,
                            _ => t.receipt.period90,
                          },
                          onSelect: (d) => setState(() => _periodDays = d),
                        ),
                      ],
                    ],
                  )
                : Column(
                    children: [
                      TextField(
                        style: AppTextStyles.bodyMd,
                        onChanged: (v) => setState(() => _query = v.trim()),
                        decoration: InputDecoration(
                          hintText: t.receipt.search,
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 20,
                          ),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.base),
                      Row(
                        children: [
                          Expanded(
                            child: _SortRow<_PriceSort>(
                              values: _PriceSort.values,
                              selected: _priceSort,
                              label: (s) => switch (s) {
                                _PriceSort.name => t.receipt.sortName,
                                _PriceSort.date => t.receipt.sortDate,
                                _PriceSort.price => t.receipt.price,
                              },
                              onSelect: (s) => setState(() => _priceSort = s),
                            ),
                          ),
                          _FilterButton(
                            active:
                                _unitFilter != null || _manualFilter != null,
                            open: _filtersOpen,
                            onTap: () =>
                                setState(() => _filtersOpen = !_filtersOpen),
                          ),
                        ],
                      ),
                      if (_filtersOpen) ...[
                        const SizedBox(height: AppSpacing.base),
                        _ChipRow<PriceUnit?>(
                          values: const [null, ...PriceUnit.values],
                          selected: _unitFilter,
                          label: (u) => u == null
                              ? t.receipt.filterAll
                              : priceUnitLabel(u),
                          onSelect: (u) => setState(() => _unitFilter = u),
                        ),
                        const SizedBox(height: AppSpacing.base),
                        _ChipRow<bool?>(
                          values: const [null, false, true],
                          selected: _manualFilter,
                          label: (m) => switch (m) {
                            null => t.receipt.filterAll,
                            false => t.receipt.sourceReceipt,
                            true => t.receipt.sourceManual,
                          },
                          onSelect: (m) => setState(() => _manualFilter = m),
                        ),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabs,
                    children: [_receiptsList(), _pricesList()],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _receiptsList() {
    final receipts = _sortedReceipts;
    if (receipts.isEmpty) {
      return ClayEmptyState(
        icon: Icons.receipt_long_rounded,
        message: t.receipt.noReceipts,
      );
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        0,
        AppSpacing.marginMobile,
        ClayNavDock.bottomPadding(context),
      ),
      itemCount: receipts.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final r = receipts[i];
        return ClayCard(
          radius: AppRadius.md,
          padding: const EdgeInsets.all(AppSpacing.gutter),
          onTap: () async {
            await context.pushNamed(Routing.receiptDetails, extra: r);
            _load();
          },
          onLongPress: () => _deleteReceipt(r),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.onPrimaryFixedVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.store ?? '—', style: AppTextStyles.bodyLg),
                    Text(
                      '${DateFormat.yMd().format(r.purchasedAt)} · ${t.receipt.itemsInReceipt(count: r.itemCount)}',
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                priceLabel(r.total, currency: r.currency),
                style: AppTextStyles.bodyLg.copyWith(
                  fontWeight: FontWeight.w800,
                  fontVariations: const [FontVariation('wght', 800)],
                ),
              ),
              if (r.hasImages)
                IconButton(
                  tooltip: t.receipt.viewImage,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.image_rounded, color: AppColors.primary),
                  onPressed: () =>
                      context.pushNamed(Routing.receiptImages, extra: r),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _pricesList() {
    final prices = _latestPrices;
    if (prices.isEmpty) {
      return ClayEmptyState(
        icon: Icons.sell_rounded,
        message: t.receipt.noPrices,
      );
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.marginMobile,
        0,
        AppSpacing.marginMobile,
        ClayNavDock.bottomPadding(context),
      ),
      itemCount: prices.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.base),
      itemBuilder: (context, i) {
        final r = prices[i];
        return ClayCard(
          radius: AppRadius.md,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter,
            vertical: AppSpacing.sm,
          ),
          onTap: () async {
            if (await showProductPricingSheet(context, product: r)) _load();
          },
          onLongPress: () => _deleteProduct(r),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name, style: AppTextStyles.bodyMd),
                    Text(
                      r.receiptId == PriceRecordEntity.manualReceiptId
                          ? '${t.receipt.manualSource} · ${DateFormat.yMd().format(r.purchasedAt)}'
                          : '${r.store ?? t.receipt.lastPaid} · ${DateFormat.yMd().format(r.purchasedAt)}',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    priceLabel(r.unitPrice, currency: r.currency),
                    style: AppTextStyles.bodyLg.copyWith(
                      fontWeight: FontWeight.w800,
                      fontVariations: const [FontVariation('wght', 800)],
                    ),
                  ),
                  Text(
                    priceUnitLabel(r.unit),
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SortRow<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelect;

  const _SortRow({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          t.receipt.sortBy,
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: AppSpacing.base),
        for (final v in values) ...[
          GestureDetector(
            onTap: () => onSelect(v),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs + 2,
              ),
              decoration: ShapeDecoration(
                color: v == selected
                    ? AppColors.primaryFixed
                    : AppColors.surfaceContainerLow,
                shape: StadiumBorder(
                  side: BorderSide(
                    color: v == selected
                        ? AppColors.primary
                        : AppColors.outlineVariant,
                  ),
                ),
              ),
              child: Text(
                label(v),
                style: AppTextStyles.labelSm.copyWith(
                  color: v == selected
                      ? AppColors.onPrimaryFixedVariant
                      : AppColors.tertiary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.base),
        ],
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  final bool active;
  final bool open;
  final VoidCallback onTap;

  const _FilterButton({
    required this.active,
    required this.open,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: t.receipt.filter,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        backgroundColor: open || active
            ? AppColors.primaryFixed
            : AppColors.surfaceContainerLow,
        foregroundColor: active ? AppColors.primary : AppColors.tertiary,
      ),
      icon: Icon(
        active ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
        size: 20,
      ),
      onPressed: onTap,
    );
  }
}

/// A scrolling row of choice chips; the selected one is tinted.
class _ChipRow<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelect;

  const _ChipRow({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final v in values) ...[
            GestureDetector(
              onTap: () => onSelect(v),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs + 2,
                ),
                decoration: ShapeDecoration(
                  color: v == selected
                      ? AppColors.primaryFixed
                      : AppColors.surfaceContainerLow,
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: v == selected
                          ? AppColors.primary
                          : AppColors.outlineVariant,
                    ),
                  ),
                ),
                child: Text(
                  label(v),
                  style: AppTextStyles.labelSm.copyWith(
                    color: v == selected
                        ? AppColors.onPrimaryFixedVariant
                        : AppColors.tertiary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.base),
          ],
        ],
      ),
    );
  }
}
