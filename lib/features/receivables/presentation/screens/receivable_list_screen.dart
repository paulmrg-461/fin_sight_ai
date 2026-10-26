import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/currency/presentation/widgets/money_text.dart';
import '../../../../core/l10n/failure_text.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/widgets/app_layout.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_states.dart';
import '../../domain/entities/receivable_entity.dart';
import '../bloc/receivable_bloc.dart';
import '../bloc/receivable_event.dart';
import '../bloc/receivable_state.dart';
import '../widgets/payment_dialog.dart';
import '../widgets/receivable_card.dart';
import 'add_receivable_screen.dart';
import 'receivable_detail_screen.dart';

/// Lists money lent, remaining balances, and repayment progress.
class ReceivableListScreen extends StatefulWidget {
  const ReceivableListScreen({super.key});

  @override
  State<ReceivableListScreen> createState() => _ReceivableListScreenState();
}

class _ReceivableListScreenState extends State<ReceivableListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ReceivableBloc>().add(const LoadReceivables());
  }

  Future<void> _refresh() async {
    context.read<ReceivableBloc>().add(const LoadReceivables());
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  void _openAddReceivable(BuildContext context) {
    final bloc = context.read<ReceivableBloc>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            BlocProvider.value(value: bloc, child: const AddReceivableScreen()),
      ),
    );
  }

  void _openDetail(BuildContext context, ReceivableEntity receivable) {
    final bloc = context.read<ReceivableBloc>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: ReceivableDetailScreen(receivableId: receivable.id),
        ),
      ),
    );
  }

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.receivablesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('receivable-add'),
        onPressed: () => _openAddReceivable(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.addReceivable),
      ),
      body: BlocBuilder<ReceivableBloc, ReceivableState>(
        builder: (context, state) {
          return switch (state) {
            ReceivableInitial() || ReceivableLoading() => Center(
              child: CircularProgressIndicator(
                semanticsLabel: context.l10n.loadingReceivables,
              ),
            ),
            ReceivableFailure(:final message) => AppErrorState(
              message: context.failureText(message),
              onRetry: () =>
                  context.read<ReceivableBloc>().add(const LoadReceivables()),
            ),
            ReceivableEmpty() => AppContent(
              padding: EdgeInsets.zero,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  AppEmptyState(
                    icon: Icons.handshake_outlined,
                    title: context.l10n.noReceivables,
                    message: context.l10n.noReceivablesBody,
                    actionLabel: context.l10n.addReceivable,
                    onAction: () => _openAddReceivable(context),
                  ),
                ],
              ),
            ),
            ReceivableLoaded(:final receivables) => AppContent(
              padding: EdgeInsets.zero,
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  children: [
                    _ReceivablesHero(
                      total: state.totalOutstanding,
                      activeCount: state.activeCount,
                    ),
                    const SizedBox(height: 20),
                    AppSectionHeader(
                      title: context.l10n.receivablesTitle,
                      subtitle: context.l10n.owedToMeBody,
                    ),
                    for (final receivable in receivables) ...[
                      ReceivableCard(
                        receivable: receivable,
                        onTap: () => _openDetail(context, receivable),
                        onPay: () => _recordPayment(context, receivable),
                        onDelete: () => _deleteReceivable(context, receivable),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ),
          };
        },
      ),
    );
  }
}

class _ReceivablesHero extends StatelessWidget {
  const _ReceivablesHero({required this.total, required this.activeCount});

  final double total;
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onHero = theme.colorScheme.onPrimary.withValues(alpha: 0.8);
    return BrandGradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.handshake_outlined, color: onHero, size: 20),
              const SizedBox(width: 8),
              Text(
                context.l10n.owedToMe,
                style: theme.textTheme.labelLarge?.copyWith(color: onHero),
              ),
            ],
          ),
          const SizedBox(height: 8),
          MoneyText(
            total,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.peopleOweYou(activeCount),
            style: theme.textTheme.bodyMedium?.copyWith(color: onHero),
          ),
        ],
      ),
    );
  }
}
