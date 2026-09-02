import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/i18n/strings.g.dart';
import '../../../../core/widgets/error_retry_view.dart';
import '../../../../core/widgets/measurement_unit_label.dart';
import '../../domain/entities/grocery_list_entity.dart';
import '../bloc/grocery_list_bloc.dart';
import '../widgets/item_breakdown_sheet.dart';

class GroceryListPage extends StatelessWidget {
  const GroceryListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GroceryListBloc.fromContext(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.groceryList.title),
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: t.groceryList.aggregated,
                onPressed: () =>
                  context.read<GroceryListBloc>().add(const GroceryListEvent.regenerate()),
              ),
            ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            heroTag: 'groceryListFab',
            onPressed: () => _showAddItemDialog(context),
            child: const Icon(Icons.add),
          ),
        ),
        body: BlocBuilder<GroceryListBloc, GroceryListState>(
          builder: (context, state) {
            return switch (state) {
              GroceryListLoading() => const Center(child: CircularProgressIndicator()),
              GroceryListLoaded(list: final list) => _ListBody(list: list),
              GroceryListError(error: final error) => ErrorRetryView(
                  error: error,
                  onRetry: () => context.read<GroceryListBloc>().add(const GroceryListEvent.init()),
                ),
            };
          },
        ),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final bloc = context.read<GroceryListBloc>();
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.groceryList.addItem),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                bloc.add(.addAdHocItem(controller.text.trim()));
              }
              Navigator.of(dialogContext).pop();
            },
            child: Text(t.common.add),
          ),
        ],
      ),
    );
  }
}

class _ListBody extends StatelessWidget {
  final GroceryListEntity list;

  const _ListBody({required this.list});

  @override
  Widget build(BuildContext context) {
    if (list.items.isEmpty) {
      return Center(child: Text(t.groceryList.empty));
    }
    final bloc = context.read<GroceryListBloc>();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: list.items.length,
      itemBuilder: (context, index) {
        final item = list.items[index];
        final unit = measurementUnitLabel(item.unit);
        final amountLabel = item.isAdHoc ? '' : '${item.totalAmount} $unit'.trim();
        return Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => bloc.add(.removeItem(item.id)),
          background: Container(
            color: Colors.red.shade300,
            alignment: AlignmentDirectional.centerEnd,
            padding: const EdgeInsetsDirectional.only(end: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: CheckboxListTile(
            value: item.isChecked,
            onChanged: (_) => bloc.add(.toggleItem(item.id)),
            title: Text(
              item.name,
              style: AppTextStyles.body.copyWith(
                decoration: item.isChecked ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: amountLabel.isEmpty ? null : Text(amountLabel, style: AppTextStyles.caption),
            secondary: item.sources.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.unfold_more),
                    onPressed: () => showItemBreakdownSheet(
                      context,
                      item,
                      onAdjustSource: (sourceIndex, amount) =>
                          bloc.add(.adjustSource(item.id, sourceIndex, amount)),
                      onAddBuffer: (amount) => bloc.add(.addBuffer(item.id, amount)),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
