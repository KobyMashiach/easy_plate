import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/image_storage_service.dart';
import '../../../../core/utils/routing/routing.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/clay/clay.dart';
import '../../domain/entities/price_record_entity.dart';
import '../../domain/entities/receipt_entity.dart';
import '../../domain/repositories/price_book_repository.dart';
import '../../domain/usecases/price_book_usecases.dart';
import '../widgets/add_price_dialog.dart';
import '../widgets/delete_receipt_sheet.dart';
import '../widgets/price_widgets.dart';

/// One saved receipt: its header and every price read from it. A line can
/// be corrected (which records a fresh price) or the whole receipt deleted.
class ReceiptDetailsPage extends StatefulWidget {
  final ReceiptEntity receipt;

  const ReceiptDetailsPage({super.key, required this.receipt});

  @override
  State<ReceiptDetailsPage> createState() => _ReceiptDetailsPageState();
}

class _ReceiptDetailsPageState extends State<ReceiptDetailsPage> {
  List<PriceRecordEntity> _lines = const [];
  late String? _store = widget.receipt.store;

  Future<void> _renameStore() async {
    final name = await AppDialog.prompt(
      context,
      title: t.receipt.renameStore,
      hint: t.receipt.storeName,
      initial: _store,
      icon: Icons.storefront_rounded,
    );
    if (name == null || !mounted) return;
    await context.read<PriceBookRepository>().renameReceiptStore(
      widget.receipt.id,
      name,
    );
    if (!mounted) return;
    setState(() => _store = name);
    _load();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await GetPriceRecordsUseCase(
      context.read<PriceBookRepository>(),
    )();
    if (!mounted) return;
    setState(
      () =>
          _lines = all.where((r) => r.receiptId == widget.receipt.id).toList(),
    );
  }

  Future<void> _delete() async {
    final keepRecords = await showDeleteReceiptSheet(context);
    if (keepRecords == null || !mounted) return;
    await context.read<PriceBookRepository>().deleteReceipt(
      widget.receipt.id,
      keepRecords: keepRecords,
    );
    for (final f in widget.receipt.imageFileNames) {
      await ImageStorageService().delete(f);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.receipt;
    return ClayScaffold(
      appBar: ClayTopAppBar(
        title: t.receipt.receipts,
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingTap: () => Navigator.of(context).maybePop(),
        trailingIcon: Icons.delete_outline_rounded,
        onTrailingTap: _delete,
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
            title: _store ?? '—',
            subtitle:
                '${DateFormat.yMd().format(r.purchasedAt)} · ${priceLabel(r.total, currency: r.currency)}',
            trailing: ClayIconButton(
              icon: Icons.edit_rounded,
              size: 44,
              tooltip: t.receipt.renameStore,
              onTap: _renameStore,
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
          if (r.hasImages) ...[
            ClayButton(
              label: t.receipt.viewImage,
              icon: Icons.image_rounded,
              expanded: true,
              onPressed: () =>
                  context.pushNamed(Routing.receiptImages, extra: r),
            ),
            const SizedBox(height: AppSpacing.gutter),
          ],
          ClayCard(
            radius: AppRadius.md,
            padding: const EdgeInsets.all(AppSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClaySectionHeader(title: t.receipt.captured, underline: true),
                const SizedBox(height: AppSpacing.sm),
                for (final line in _lines)
                  InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    onTap: () async {
                      if (await showAddPriceDialog(
                        context,
                        name: line.name,
                        price: line.unitPrice,
                        unit: line.unit,
                      )) {
                        _load();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.base,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(line.name, style: AppTextStyles.bodyMd),
                                if (line.printedName != line.name)
                                  Text(
                                    t.receipt.printedAs(name: line.printedName),
                                    style: AppTextStyles.labelSm.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '${line.quantity == line.quantity.roundToDouble() ? line.quantity.round() : line.quantity} × ${priceLabel(line.unitPrice)} ${priceUnitLabel(line.unit)}',
                            style: AppTextStyles.labelMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
