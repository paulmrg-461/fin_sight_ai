import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/currency/presentation/widgets/money_text.dart';
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
              : Builder(
                  builder: (context) {
                    final entries = _entries(context, visible);
                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 96),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        if (entry is _DateEntry) {
                          return _DateHeader(entry: entry);
                        }
                        final transaction =
                            (entry as _TransactionEntry).transaction;
                        return _TransactionTile(
                          transaction: transaction,
                          onDelete: () => widget.onDelete(transaction),
                          onEdit: () => widget.onEdit(transaction),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

sealed class _Entry {
  const _Entry();
}

class _DateEntry extends _Entry {
  const _DateEntry({required this.date, required this.net});

  final DateTime date;
  final double net;
}

class _TransactionEntry extends _Entry {
  const _TransactionEntry(this.transaction);

  final TransactionEntity transaction;
}

List<_Entry> _entries(
  BuildContext context,
  List<TransactionEntity> transactions,
) {
  final sorted = [...transactions]..sort((a, b) => b.date.compareTo(a.date));
  final groups = <DateTime, List<TransactionEntity>>{};
  for (final transaction in sorted) {
    final day = DateTime(
      transaction.date.year,
      transaction.date.month,
      transaction.date.day,
    );
    groups.putIfAbsent(day, () => []).add(transaction);
  }

  final entries = <_Entry>[];
  for (final group in groups.entries) {
    final net = group.value.fold<double>(
      0,
      (sum, transaction) => sum + transaction.signedAmount,
    );
    entries.add(_DateEntry(date: group.key, net: net));
    for (final transaction in group.value) {
      entries.add(_TransactionEntry(transaction));
    }
  }
  return entries;
}

String _dayLabel(BuildContext context, DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  if (date == today) {
    return context.l10n.today;
  }
  if (date == yesterday) {
    return context.l10n.yesterday;
  }
  return formatDisplayDate(date);
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.entry});

  final _DateEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positive = entry.net >= 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        children: [
          Text(
            _dayLabel(context, entry.date).toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Divider(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 10),
          MoneyText(
            entry.net,
            signed: true,
            style: theme.textTheme.labelSmall?.copyWith(
              color: positive ? AppColors.emerald : AppColors.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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
