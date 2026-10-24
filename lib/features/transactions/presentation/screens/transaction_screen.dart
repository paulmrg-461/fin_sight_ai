import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/main_shell.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../core/widgets/app_layout.dart';
import '../../../../core/widgets/app_states.dart';
import '../bloc/transaction_bloc.dart';
import '../bloc/transaction_event.dart';
import '../bloc/transaction_state.dart';
import '../widgets/transaction_form.dart';
import '../widgets/transaction_list.dart';

/// Main transactions screen: add, list, filter, and delete.
class TransactionScreen extends StatelessWidget {
  const TransactionScreen({super.key});

  Future<void> _openForm(BuildContext context) {
    final bloc = context.read<TransactionBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          BlocProvider.value(value: bloc, child: const TransactionForm()),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppMenuButton(),
        title: Text(context.l10n.transactions),
        actions: [
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
            return switch (state) {
              TransactionInitial() ||
              TransactionLoading() => const _LoadingView(),
              TransactionFailure(:final message) => AppErrorState(
                message: message,
                onRetry: () => context.read<TransactionBloc>().add(
                  const LoadTransactions(),
                ),
              ),
              TransactionEmpty(:final start, :final end) => _EmptyView(
                hasDateFilter: start != null && end != null,
                onAdd: () => _openForm(context),
                onClearFilter: () => context.read<TransactionBloc>().add(
                  const LoadTransactions(),
                ),
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
                        onClear: () => context.read<TransactionBloc>().add(
                          const LoadTransactions(),
                        ),
                      ),
                    Expanded(
                      child: TransactionList(
                        transactions: transactions,
                        onDelete: (id) => context.read<TransactionBloc>().add(
                          DeleteTransaction(id),
                        ),
                      ),
                    ),
                  ],
                ),
            };
          },
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
    required this.onAdd,
    required this.onClearFilter,
  });

  final bool hasDateFilter;
  final VoidCallback onAdd;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppContent(
        maxWidth: 620,
        child: AppEmptyState(
          icon: Icons.receipt_long_rounded,
          title: hasDateFilter
              ? context.l10n.noTransactionsInRange
              : context.l10n.noTransactionsYet,
          message: hasDateFilter
              ? context.l10n.noTransactionsRangeBody
              : context.l10n.noTransactionsBody,
          actionLabel: hasDateFilter
              ? context.l10n.clearFilter
              : context.l10n.addTransaction,
          actionIcon: hasDateFilter
              ? Icons.filter_alt_off_rounded
              : Icons.add_rounded,
          onAction: hasDateFilter ? onClearFilter : onAdd,
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
