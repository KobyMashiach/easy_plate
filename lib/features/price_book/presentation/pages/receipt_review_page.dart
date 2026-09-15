import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/image_storage_service.dart';
import '../../../recipe_ingestion/data/datasources/recipe_ai_datasource.dart'
    show ReceiptPage;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../domain/entities/receipt_scan_entity.dart';
import '../../domain/repositories/price_book_repository.dart';
import '../../domain/usecases/price_book_usecases.dart';
import '../widgets/price_widgets.dart';
import '../widgets/add_price_dialog.dart' show priceUnitLabel;
import '../../domain/entities/price_unit.dart';
import '../../domain/entities/price_record_entity.dart';
import '../../domain/entities/product_pricing_entity.dart';
import '../../domain/product_name.dart';
import '../../../../core/widgets/landscape_hint.dart';

/// What the scan read, line by line, before anything is kept: names and
/// prices are editable, unreadable lines are listed so the user can add
/// them by hand, and sharing with the community is a switch that is off
/// until they turn it on. Pops with the number of prices saved.
/// What the review is opened with: the reading, and the pages it was read
/// from so they can be kept with the receipt.
class ReceiptReviewArgs {
  final ReceiptScanEntity scan;
  final List<ReceiptPage> pages;

  const ReceiptReviewArgs({required this.scan, this.pages = const []});
}

class ReceiptReviewPage extends StatefulWidget {
  final ReceiptScanEntity scan;
  final List<ReceiptPage> pages;

  const ReceiptReviewPage({
    super.key,
    required this.scan,
    this.pages = const [],
  });

  @override
  State<ReceiptReviewPage> createState() => _ReceiptReviewPageState();
}

/// What to do when the product is already in the book.
enum _Keep { newPrice, oldPrice, average }

class _LineControllers {
  _Keep keep = _Keep.newPrice;
  final TextEditingController name;
  final TextEditingController price;
  final TextEditingController quantity;
  final String printedName;
  PriceUnit unit;

  _LineControllers(ReceiptLineEntity line)
    : printedName = line.printedName,
      unit = line.unit,
      name = TextEditingController(text: line.name),
      price = TextEditingController(text: line.unitPrice.toStringAsFixed(2)),
      quantity = TextEditingController(
        text: line.quantity == line.quantity.roundToDouble()
            ? line.quantity.round().toString()
            : line.quantity.toString(),
      );

  ReceiptLineEntity? toLine() {
    final n = name.text.trim();
    final p = double.tryParse(price.text.trim().replaceAll(',', '.'));
    if (n.isEmpty || p == null || p <= 0) return null;
    final q = double.tryParse(quantity.text.trim().replaceAll(',', '.')) ?? 1;
    return ReceiptLineEntity(
      name: n,
      printedName: printedName.isEmpty ? n : printedName,
      quantity: q <= 0 ? 1 : q,
      unitPrice: p,
      unit: unit,
    );
  }

  void dispose() {
    name.dispose();
    price.dispose();
    quantity.dispose();
  }
}

class _ReceiptReviewPageState extends State<ReceiptReviewPage> {
  static const _uuid = Uuid();

  /// The book's products, so a line can say "already known at ₪X".
  List<PriceRecordEntity> _existing = const [];

  @override
  void initState() {
    super.initState();
    context.read<PriceBookRepository>().getRecords().then((records) {
      if (mounted) setState(() => _existing = records);
    });
  }

  /// The latest known record for a line's product, if any.
  PriceRecordEntity? _knownFor(_LineControllers line) {
    final key = normalizeProductName(line.name.text);
    PriceRecordEntity? best;
    for (final r in _existing) {
      if (r.normalizedName != key || r.unit != line.unit) continue;
      if (best == null || r.purchasedAt.isAfter(best.purchasedAt)) best = r;
    }
    return best;
  }

  late final List<_LineControllers> _lines = [
    for (final line in widget.scan.items) _LineControllers(line),
  ];
  List<String> get _unreadable => widget.scan.unreadable;
  // On by default: sharing is names and prices only, and the community
  // figures are only as good as what people put in.
  bool _share = true;
  bool _saving = false;

  @override
  void dispose() {
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  List<ReceiptLineEntity> get _validLines =>
      _lines.map((l) => l.toLine()).nonNulls.toList();

  double get _itemsTotal => _validLines.fold(0, (s, l) => s + l.lineTotal);

  void _addLine() {
    setState(() {
      _lines.add(
        _LineControllers(
          const ReceiptLineEntity(name: '', quantity: 1, unitPrice: 0),
        )..price.text = '',
      );
    });
  }

  Future<void> _save() async {
    final lines = _validLines;
    if (lines.isEmpty) {
      AppDialog.info(message: t.receipt.nothingToSave).notify(context);
      return;
    }
    setState(() => _saving = true);
    try {
      final repository = context.read<PriceBookRepository>();
      // The pages go to disk first, so the receipt never points at files
      // that were not written.
      final fileNames = <String>[];
      for (var i = 0; i < widget.pages.length; i++) {
        final page = widget.pages[i];
        final name = 'receipt_${_uuid.v4()}_$i.${page.isPdf ? 'pdf' : 'jpg'}';
        if (await ImageStorageService().storeBytes(name, page.bytes) != null) {
          fileNames.add(name);
        }
      }
      final records = await SaveReceiptUseCase(repository)(
        widget.scan.copyWith(items: lines),
        imageFileNames: fileNames,
      );
      // "Keep the old price" / "average" are pricing choices, not
      // omissions: the new price is recorded like any other, and the
      // product's policy decides which one the list uses.
      for (final line in _lines) {
        final known = _knownFor(line);
        if (known == null || line.keep == _Keep.newPrice) continue;
        final key = ProductPricingEntity.keyFor(
          known.normalizedName,
          known.unit,
        );
        await repository.savePricing(
          line.keep == _Keep.average
              ? ProductPricingEntity(key: key, mode: PricingMode.average)
              : ProductPricingEntity(
                  key: key,
                  mode: PricingMode.receipts,
                  receiptIds: [known.receiptId],
                ),
        );
      }
      var shared = false;
      if (_share) {
        try {
          await SharePricesUseCase(repository)(records);
          shared = true;
        } catch (e) {
          debugPrint('Sharing prices failed: $e');
        }
      }
      if (!mounted) return;
      AppDialog.success(
        message: shared
            ? t.receipt.savedShared(count: records.length)
            : t.receipt.saved(count: records.length),
      ).notify(context);
      Navigator.of(context).pop(records.length);
    } catch (e) {
      debugPrint('Saving receipt failed: $e');
      if (mounted) AppDialog.error(message: t.common.error).show(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scan = widget.scan;
    final date = scan.purchasedAt;
    return ClayScaffold(
      appBar: ClayTopAppBar(
        title: t.receipt.title,
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingTap: () => Navigator.of(context).maybePop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.marginMobile,
          AppSpacing.md,
          AppSpacing.marginMobile,
          AppSpacing.xl,
        ),
        children: [
          ClayPageHeader(
            title: t.receipt.reviewTitle,
            subtitle: t.receipt.reviewSubtitle,
          ),
          const SizedBox(height: AppSpacing.sm),
          const LandscapeHint(),
          const SizedBox(height: AppSpacing.gutter),
          // Store, date, totals — the receipt's own header, for a sanity
          // check against the lines below it.
          ClayCard(
            radius: AppRadius.md,
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Column(
              children: [
                _HeaderRow(
                  icon: Icons.storefront_rounded,
                  label: t.receipt.store,
                  value: scan.store ?? '—',
                ),
                _HeaderRow(
                  icon: Icons.event_rounded,
                  label: t.receipt.date,
                  value: date == null ? '—' : DateFormat.yMd().format(date),
                ),
                _HeaderRow(
                  icon: Icons.receipt_long_rounded,
                  label: t.receipt.receiptTotal,
                  value: scan.total == null
                      ? '—'
                      : priceLabel(scan.total!, currency: scan.currency),
                ),
                _HeaderRow(
                  icon: Icons.calculate_rounded,
                  label: t.receipt.itemsTotal,
                  value: priceLabel(_itemsTotal, currency: scan.currency),
                  emphasised: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
          ClayCard(
            radius: AppRadius.md,
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ClaySectionHeader(
                        title: t.receipt.captured,
                        underline: true,
                      ),
                    ),
                    Text(
                      t.receipt.capturedCount(count: _lines.length),
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                for (var i = 0; i < _lines.length; i++)
                  _LineEditor(
                    key: ObjectKey(_lines[i]),
                    controllers: _lines[i],
                    known: _knownFor(_lines[i]),
                    onChanged: () => setState(() {}),
                    onRemove: () =>
                        setState(() => _lines.removeAt(i).dispose()),
                  ),
                const SizedBox(height: AppSpacing.base),
                ClayButton(
                  label: t.receipt.addLine,
                  icon: Icons.add_rounded,
                  onPressed: () => _addLine(),
                ),
              ],
            ),
          ),
          if (_unreadable.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.gutter),
            ClayCard(
              radius: AppRadius.md,
              padding: const EdgeInsets.all(AppSpacing.gutter),
              color: AppColors.surfaceContainerLow,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClaySectionHeader(title: t.receipt.unreadable),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    t.receipt.unreadableHint,
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final line in _unreadable)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.help_outline_rounded,
                            size: 16,
                            color: AppColors.outline,
                          ),
                          const SizedBox(width: AppSpacing.base),
                          Expanded(
                            child: Text(
                              line,
                              style: AppTextStyles.labelMd.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.gutter),
          ClayCard(
            radius: AppRadius.md,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.gutter,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.receipt.shareToggle, style: AppTextStyles.bodyMd),
                      Text(
                        t.receipt.shareHint,
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _share,
                  onChanged: (v) => setState(() => _share = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ClayButton(
            label: t.receipt.save,
            icon: Icons.save_rounded,
            expanded: true,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool emphasised;

  const _HeaderRow({
    required this.icon,
    required this.label,
    required this.value,
    this.emphasised = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.outline),
          const SizedBox(width: AppSpacing.base),
          Expanded(child: Text(label, style: AppTextStyles.labelMd)),
          Text(
            value,
            style: (emphasised ? AppTextStyles.bodyLg : AppTextStyles.labelMd)
                .copyWith(
                  fontWeight: FontWeight.w800,
                  fontVariations: const [FontVariation('wght', 800)],
                ),
          ),
        ],
      ),
    );
  }
}

class _LineEditor extends StatelessWidget {
  final _LineControllers controllers;
  final PriceRecordEntity? known;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _LineEditor({
    super.key,
    required this.controllers,
    required this.known,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final numberStyle = AppTextStyles.labelMd.copyWith(fontSize: 15);
    const dense = EdgeInsets.symmetric(horizontal: 10, vertical: AppSpacing.sm);
    // Two rows, not one: on a phone a single row starved whichever field
    // sat at the end. The name gets the width; the numbers share the next
    // line with the unit.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controllers.name,
                  style: AppTextStyles.bodyMd,
                  onChanged: (_) => onChanged(),
                  decoration: InputDecoration(
                    hintText: t.receipt.itemName,
                    isDense: true,
                    contentPadding: dense,
                  ),
                ),
              ),
              IconButton(
                tooltip: t.receipt.removeLine,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.outline,
                ),
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          Row(
            children: [
              // Tapping cycles unit → kg → litre: what the price is per.
              GestureDetector(
                onTap: () {
                  controllers.unit = controllers.unit.next;
                  onChanged();
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.base,
                  ),
                  decoration: ShapeDecoration(
                    color: controllers.unit == PriceUnit.unit
                        ? AppColors.surfaceContainerLow
                        : AppColors.primaryFixed,
                    shape: StadiumBorder(
                      side: BorderSide(color: AppColors.outlineVariant),
                    ),
                  ),
                  child: Text(
                    priceUnitLabel(controllers.unit),
                    style: AppTextStyles.labelMd.copyWith(
                      color: AppColors.onPrimaryFixedVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: controllers.quantity,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  style: numberStyle,
                  onChanged: (_) => onChanged(),
                  decoration: InputDecoration(
                    labelText: t.receipt.quantity,
                    isDense: true,
                    contentPadding: dense,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.base),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: controllers.price,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  style: numberStyle,
                  onChanged: (_) => onChanged(),
                  decoration: InputDecoration(
                    labelText: t.receipt.price,
                    prefixText: '₪ ',
                    isDense: true,
                    contentPadding: dense,
                  ),
                ),
              ),
            ],
          ),
          if (known case final known?) ...[
            const SizedBox(height: AppSpacing.base),
            // Already in the book: say so, and let the user pick which price
            // the list should follow from now on.
            Wrap(
              spacing: AppSpacing.base,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base,
                    vertical: 2,
                  ),
                  decoration: ShapeDecoration(
                    color: AppColors.warmAccent.withValues(alpha: 0.18),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    t.receipt.existingPrice(
                      price: priceLabel(
                        known.unitPrice,
                        currency: known.currency,
                      ),
                    ),
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onWarmAccent,
                    ),
                  ),
                ),
                for (final (keep, label) in [
                  (_Keep.newPrice, t.receipt.keepNew),
                  (_Keep.oldPrice, t.receipt.keepOld),
                  (_Keep.average, t.receipt.keepAverage),
                ])
                  GestureDetector(
                    onTap: () {
                      controllers.keep = keep;
                      onChanged();
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.base,
                        vertical: 2,
                      ),
                      decoration: ShapeDecoration(
                        color: controllers.keep == keep
                            ? AppColors.primary
                            : AppColors.surfaceContainerLow,
                        shape: StadiumBorder(
                          side: BorderSide(
                            color: controllers.keep == keep
                                ? AppColors.primary
                                : AppColors.outlineVariant,
                          ),
                        ),
                      ),
                      child: Text(
                        label,
                        style: AppTextStyles.labelSm.copyWith(
                          color: controllers.keep == keep
                              ? AppColors.onPrimary
                              : AppColors.tertiary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (controllers.printedName != controllers.name.text) ...[
            const SizedBox(height: AppSpacing.xs),
            // The receipt's own words, so a generic name can be checked
            // against what was actually bought.
            Text(
              t.receipt.printedAs(name: controllers.printedName),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
