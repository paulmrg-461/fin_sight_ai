import 'package:material_ui/material_ui.dart';

import '../../../../core/currency/presentation/widgets/money_text.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../domain/entities/transaction_entity.dart';

/// Transaction list with client-side category filtering.
class TransactionList extends StatefulWidget {
  const TransactionList({
    super.key,
    required this.transactions,
    required this.onDelete,
    required this.onEdit,
  });

  final List<TransactionEntity> transactions;
  final ValueChanged<TransactionEntity> onDelete;
  final ValueChanged<TransactionEntity> onEdit;

  @override
  State<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  String? _category;

  @override
  void didUpdateWidget(TransactionList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final categories = _categories;
    if (_category != null && !categories.contains(_category)) {
      _category = null;
    }
  }

  List<String> get _categories {
    final categories =
        widget.transactions
            .map((transaction) => transaction.category)
            .toSet()
            .toList()
          ..sort();
    return categories;
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categories;
    final visible = _category == null
        ? widget.transactions
        : widget.transactions
              .where((transaction) => transaction.category == _category)
              .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (categories.length > 1)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                FilterChip(
                  label: Text(context.l10n.all),
                  selected: _category == null,
                  onSelected: (_) => setState(() => _category = null),
                ),
                const SizedBox(width: 8),
                for (final category in categories) ...[
                  FilterChip(
                    label: Text(category),
                    selected: _category == category,
                    onSelected: (_) => setState(() => _category = category),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Text(
                    context.l10n.noTransactionsCategory,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 96),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final transaction = visible[index];
                    return _TransactionTile(
                      transaction: transaction,
                      onDelete: () => widget.onDelete(transaction),
                      onEdit: () => widget.onEdit(transaction),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.onDelete,
    required this.onEdit,
  });

  final TransactionEntity transaction;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIncome = transaction.isIncome;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: isIncome
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.errorContainer,
          child: Icon(
            isIncome ? Icons.south_west : Icons.north_east,
            color: isIncome
                ? theme.colorScheme.onPrimaryContainer
                : theme.colorScheme.onErrorContainer,
          ),
        ),
        title: Text(
          transaction.description.isEmpty
              ? transaction.category
              : transaction.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${transaction.category} • '
          '${formatDisplayDate(transaction.date)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MoneyText(
              transaction.signedAmount,
              signed: true,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isIncome ? AppColors.success : AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              onPressed: onEdit,
              tooltip: context.l10n.editTransaction,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: onDelete,
              tooltip: context.l10n.deleteTransaction,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}
