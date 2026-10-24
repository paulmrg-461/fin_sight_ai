import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/currency/presentation/widgets/money_text.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../core/widgets/app_layout.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_states.dart';
import '../../domain/entities/receivable_entity.dart';
import '../bloc/receivable_bloc.dart';
import '../bloc/receivable_event.dart';
import '../bloc/receivable_state.dart';
import '../widgets/payment_dialog.dart';
import '../widgets/payment_history_list.dart';

/// Receivable details, dates, notes, and payment history.
class ReceivableDetailScreen extends StatelessWidget {
  const ReceivableDetailScreen({super.key, required this.receivableId});

  final String receivableId;

  Future<void> _recordPayment(
    BuildContext context,
    ReceivableEntity receivable,
  ) async {
    final request = await showReceivablePaymentDialog(
      context,
      remainingAmount: receivable.remainingAmount,
    );
    if (request == null || !context.mounted) {
      return;
    }
    context.read<ReceivableBloc>().add(
      RecordReceivablePayment(
        receivableId: receivable.id,
        amount: request.amount,
        note: request.note,
      ),
    );
  }

  Future<void> _deleteReceivable(
    BuildContext context,
    ReceivableEntity receivable,
  ) async {
    final l10n = context.l10n;
    final bloc = context.read<ReceivableBloc>();
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteReceivableQuestion),
        content: Text(l10n.deleteReceivableBody),
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
    if (confirmed == true) {
      bloc.add(DeleteReceivable(receivable.id));
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.receivableDetails),
        actions: [
          BlocBuilder<ReceivableBloc, ReceivableState>(
            builder: (context, state) {
              final receivable = _findReceivable(state, receivableId);
              if (receivable == null) {
                return const SizedBox.shrink();
              }
              return IconButton(
                onPressed: () => _deleteReceivable(context, receivable),
                tooltip: l10n.deleteReceivable,
                icon: const Icon(Icons.delete_outline),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<ReceivableBloc, ReceivableState>(
        builder: (context, state) {
          if (state is ReceivableInitial || state is ReceivableLoading) {
            return Center(
              child: CircularProgressIndicator(
                semanticsLabel: l10n.updatingReceivable,
              ),
            );
          }
          if (state is ReceivableFailure) {
            return AppErrorState(
              message: state.message,
              onRetry: () =>
                  context.read<ReceivableBloc>().add(const LoadReceivables()),
            );
          }

          final receivable = _findReceivable(state, receivableId);
          if (receivable == null) {
            return Center(child: Text(l10n.receivableNotFound));
          }

          return AppContent(
            padding: EdgeInsets.zero,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _ReceivableSummary(receivable: receivable),
                const SizedBox(height: 20),
                AppSectionHeader(title: l10n.paymentHistory),
                ReceivablePaymentHistoryList(
                  payments: receivable.paymentHistory,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const ValueKey('receivable-detail-pay'),
                  onPressed: receivable.isPaid
                      ? null
                      : () => _recordPayment(context, receivable),
                  icon: const Icon(Icons.payments_outlined),
                  label: Text(l10n.addPayment),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: const ValueKey('receivable-detail-delete'),
                  onPressed: () => _deleteReceivable(context, receivable),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.deleteReceivable),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  ReceivableEntity? _findReceivable(ReceivableState state, String id) {
    if (state is! ReceivableLoaded) {
      return null;
    }
    for (final receivable in state.receivables) {
      if (receivable.id == id) {
        return receivable;
      }
    }
    return null;
  }
}

class _ReceivableSummary extends StatelessWidget {
  const _ReceivableSummary({required this.receivable});

  final ReceivableEntity receivable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusLabel = receivable.isPaid
        ? context.l10n.receivablePaid
        : context.l10n.active;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    receivable.debtorName,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                Chip(label: Text(statusLabel)),
              ],
            ),
            const SizedBox(height: 12),
            MoneyText(
              receivable.remainingAmount,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: receivable.isPaid
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${context.l10n.remainingAmount} '
                  '${context.l10n.ofLabel} ',
                  style: theme.textTheme.bodyMedium,
                ),
                MoneyText(
                  receivable.totalAmount,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: receivable.progress,
                minHeight: 8,
                semanticsLabel: context.l10n.receivableProgress,
                semanticsValue: '${(receivable.progress * 100).round()}%',
              ),
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: context.l10n.dateLent,
              value: formatDisplayDate(receivable.dateLent),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.event_available_outlined,
              label: context.l10n.dueDate,
              value: receivable.dueDate == null
                  ? context.l10n.noDueDate
                  : formatDisplayDate(receivable.dueDate!),
            ),
            if (receivable.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.notes_outlined,
                label: context.l10n.notes,
                value: receivable.notes,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${context.l10n.received}: ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                MoneyText(
                  receivable.paidAmount,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}
