import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/main_shell.dart';
import '../../../../core/l10n/failure_text.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../core/widgets/app_layout.dart';
import '../../../../core/widgets/app_states.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/services/transaction_csv.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';
import '../widgets/transaction_form.dart';
import '../widgets/transaction_list.dart';

/// Main transactions screen: add, search, filter, list, and delete.
class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refreshSearchHint);
    final state = context.read<TransactionBloc>().state;
    final query = switch (state) {
      TransactionLoaded(:final query) => query,
      TransactionEmpty(:final query) => query,
      _ => '',
    };
    if (query.isNotEmpty) {
      _searchController.text = query;
    }
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refreshSearchHint)
      ..dispose();
    super.dispose();
  }

  void _refreshSearchHint() => setState(() {});

  void _search(String query) {
    context.read<TransactionBloc>().add(SearchTransactions(query));
  }

  void _clearSearch() {
    _searchController.clear();
    _search('');
  }

  void _clearFilters() {
    _searchController.clear();
    context.read<TransactionBloc>().add(const LoadTransactions());
  }

  Future<void> _openForm(BuildContext context, {TransactionEntity? initial}) {
    final bloc = context.read<TransactionBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: TransactionForm(initial: initial),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TransactionEntity transaction,
  ) async {
    final l10n = context.l10n;
    final bloc = context.read<TransactionBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteTransactionQuestion),
        content: Text(l10n.deleteTransactionBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    bloc.add(DeleteTransaction(transaction.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.transactionDeleted),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () {
            bloc.add(
              AddTransaction(
                id: transaction.id,
                amount: transaction.amount,
                type: transaction.type,
                category: transaction.category,
                description: transaction.description,
                date: transaction.date,
                walletId: transaction.walletId,
                receiptImagePath: transaction.receiptImagePath,
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final bloc = context.read<TransactionBloc>();
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      helpText: context.l10n.filterByDate,
    );
    if (range == null) {
      return;
    }
    bloc.add(
      FilterByDateRange(
        start: startOfDay(range.start),
        end: endOfDay(range.end),
      ),
    );
  }

  Future<void> _copyCsv(
    BuildContext context,
    List<TransactionEntity> transactions,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(
      ClipboardData(text: TransactionCsv.build(transactions)),
    );
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.csvCopied(transactions.length))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppMenuButton(),
        title: Text(context.l10n.transactions),
        actions: [
          BlocBuilder<TransactionBloc, TransactionState>(
            builder: (context, state) {
              final transactions = state is TransactionLoaded
                  ? state.transactions
                  : null;
              return IconButton(
                onPressed: transactions == null
                    ? null
                    : () => _copyCsv(context, transactions),
                tooltip: context.l10n.copyCsv,
                icon: const Icon(Icons.content_copy_rounded),
              );
            },
          ),
          IconButton(
            onPressed: () => _pickDateRange(context),
            tooltip: context.l10n.filterByDate,
            icon: const Icon(Icons.date_range_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.add),
      ),
      body: AppContent(
        padding: EdgeInsets.zero,
        child: BlocBuilder<TransactionBloc, TransactionState>(
          builder: (context, state) {
            final showSearch =
                state is TransactionLoaded || state is TransactionEmpty;
            return Column(
              children: [
                if (showSearch) _searchField(context, state),
                Expanded(
                  child: switch (state) {
                    TransactionInitial() ||
                    TransactionLoading() => const _LoadingView(),
                    TransactionFailure(:final message) => AppErrorState(
                      message: context.failureText(message),
                      onRetry: () => context.read<TransactionBloc>().add(
                        const LoadTransactions(),
                      ),
                    ),
                    TransactionEmpty(:final start, :final end, :final query) =>
                      _EmptyView(
                        hasDateFilter: start != null && end != null,
                        hasQuery: query.trim().isNotEmpty,
                        onAdd: () => _openForm(context),
                        onClearFilter: _clearFilters,
                        onClearSearch: _clearSearch,
                      ),
                    TransactionLoaded(
                      :final transactions,
                      :final start,
                      :final end,
                    ) =>
                      Column(
                        children: [
                          if (start != null && end != null)
                            _DateFilterBanner(
                              start: start,
                              end: end,
                              onClear: _clearFilters,
                            ),
                          Expanded(
                            child: TransactionList(
                              transactions: transactions,
                              onDelete: (transaction) =>
                                  _confirmDelete(context, transaction),
                              onEdit: (transaction) =>
                                  _openForm(context, initial: transaction),
                            ),
                          ),
                        ],
                      ),
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _searchField(BuildContext context, TransactionState state) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onChanged: _search,
        decoration: InputDecoration(
          hintText: context.l10n.searchTransactions,
          prefixIcon: const Icon(Icons.search_rounded),
          isDense: true,
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerLow,
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  onPressed: _clearSearch,
                  tooltip: context.l10n.clearSearch,
                  icon: const Icon(Icons.close_rounded),
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        semanticsLabel: context.l10n.loadingTransactions,
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({
    required this.hasDateFilter,
    required this.hasQuery,
    required this.onAdd,
    required this.onClearFilter,
    required this.onClearSearch,
  });

  final bool hasDateFilter;
  final bool hasQuery;
  final VoidCallback onAdd;
  final VoidCallback onClearFilter;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppContent(
        maxWidth: 620,
        child: AppEmptyState(
          icon: Icons.receipt_long_rounded,
          title: hasQuery
              ? context.l10n.noMatchingTransactions
              : hasDateFilter
              ? context.l10n.noTransactionsInRange
              : context.l10n.noTransactionsYet,
          message: hasQuery
              ? context.l10n.noMatchingTransactionsBody
              : hasDateFilter
              ? context.l10n.noTransactionsRangeBody
              : context.l10n.noTransactionsBody,
          actionLabel: hasQuery
              ? context.l10n.clearSearch
              : hasDateFilter
              ? context.l10n.clearFilter
              : context.l10n.addTransaction,
          actionIcon: hasQuery
              ? Icons.search_off_rounded
              : hasDateFilter
              ? Icons.filter_alt_off_rounded
              : Icons.add_rounded,
          onAction: hasQuery
              ? onClearSearch
              : hasDateFilter
              ? onClearFilter
              : onAdd,
        ),
      ),
    );
  }
}

class _DateFilterBanner extends StatelessWidget {
  const _DateFilterBanner({
    required this.start,
    required this.end,
    required this.onClear,
  });

  final DateTime start;
  final DateTime end;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(
              Icons.date_range_outlined,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${formatDisplayDate(start)} – ${formatDisplayDate(end)}',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded, size: 18),
              label: Text(context.l10n.clearFilter),
            ),
          ],
        ),
      ),
    );
  }
}
