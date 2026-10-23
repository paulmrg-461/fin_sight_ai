import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/currency/presentation/widgets/money_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../domain/entities/debt_entity.dart';
import '../bloc/debt_bloc.dart';
import '../bloc/debt_event.dart';
import '../bloc/debt_state.dart';
import '../widgets/payment_history_list.dart';

/// Debt details, payment history, and payoff projection.
class DebtDetailScreen extends StatefulWidget {
  const DebtDetailScreen({super.key, required this.debtId});

  final String debtId;

  @override
  State<DebtDetailScreen> createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends State<DebtDetailScreen> {
  final _paymentController = TextEditingController();
  final _payoffController = TextEditingController();

  @override
  void dispose() {
    _paymentController.dispose();
    _payoffController.dispose();
    super.dispose();
  }

  Future<void> _makePayment() async {
    _paymentController.clear();
    final bloc = context.read<DebtBloc>();
    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Make a payment'),
        content: TextField(
          controller: _paymentController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Payment amount',
            prefixText: '\$ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(_paymentController.text.trim());
              if (value == null || !value.isFinite || value <= 0) {
                return;
              }
              Navigator.of(dialogContext).pop(value);
            },
            child: const Text('Pay'),
          ),
        ],
      ),
    );

    if (amount != null) {
      bloc.add(MakePayment(debtId: widget.debtId, amount: amount));
    }
  }

  void _calculatePayoff() {
    final value = double.tryParse(_payoffController.text.trim());
    if (value == null || !value.isFinite || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid monthly payment.')),
      );
      return;
    }
    context.read<DebtBloc>().add(
      CalculatePayoff(debtId: widget.debtId, monthlyPayment: value),
    );
  }

  Future<void> _deleteDebt() async {
    final bloc = context.read<DebtBloc>();
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete debt?'),
        content: const Text('This removes the debt and its payment history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      bloc.add(DeleteDebt(widget.debtId));
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt details'),
        actions: [
          IconButton(
            onPressed: _deleteDebt,
            tooltip: 'Delete debt',
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: BlocBuilder<DebtBloc, DebtState>(
        builder: (context, state) {
          if (state is DebtLoading) {
            return const Center(
              child: CircularProgressIndicator(semanticsLabel: 'Updating debt'),
            );
          }
          if (state is DebtFailure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(state.message, textAlign: TextAlign.center),
              ),
            );
          }

          final debts = state is DebtLoaded
              ? state.debts
              : const <DebtEntity>[];
          final debt = _findDebt(debts, widget.debtId);
          if (debt == null) {
            return const Center(child: Text('Debt not found.'));
          }
          final payoff = state is DebtLoaded && state.payoff?.debtId == debt.id
              ? state.payoff
              : null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCard(debt: debt),
              const SizedBox(height: 16),
              Text(
                'Payoff calculator',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _payoffController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Monthly payment',
                        prefixText: '\$ ',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _calculatePayoff,
                    child: const Text('Calculate'),
                  ),
                ],
              ),
              if (payoff != null) ...[
                const SizedBox(height: 8),
                Text(
                  payoff.expectedDate == null
                      ? 'This payment does not cover the monthly interest.'
                      : 'Projected payoff: '
                            '${formatDisplayDate(payoff.expectedDate!)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Payment history',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              PaymentHistoryList(payments: debt.paymentHistory),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _makePayment,
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Make a payment'),
              ),
            ],
          );
        },
      ),
    );
  }

  DebtEntity? _findDebt(List<DebtEntity> debts, String id) {
    for (final debt in debts) {
      if (debt.id == id) {
        return debt;
      }
    }
    return null;
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.debt});

  final DebtEntity debt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                    debt.creditorName,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                Chip(label: Text(debt.isPaid ? 'Paid' : 'Active')),
              ],
            ),
            const SizedBox(height: 12),
            MoneyText(
              debt.remainingAmount,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: debt.isPaid
                    ? AppColors.success
                    : theme.colorScheme.primary,
              ),
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('of ', style: theme.textTheme.bodyMedium),
                MoneyText(debt.totalAmount, style: theme.textTheme.bodyMedium),
                Text(' total', style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: debt.progress,
                minHeight: 8,
                semanticsLabel: 'Debt repayment progress',
                semanticsValue: '${(debt.progress * 100).round()}%',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${debt.interestRate.toStringAsFixed(2)}% APR • Minimum ',
                  style: theme.textTheme.bodySmall,
                ),
                MoneyText(
                  debt.minimumPayment,
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  '/mo • Due ${formatDisplayDate(debt.dueDate)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
