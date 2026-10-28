import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/currency/presentation/widgets/money_text.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../core/widgets/app_progress_bar.dart';
import '../../domain/entities/debt_entity.dart';
import '../../domain/services/debt_payment_plan.dart';
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
        title: Text(context.l10n.makePayment),
        content: TextField(
          controller: _paymentController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: context.l10n.paymentAmount,
            prefixText: '\$ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(_paymentController.text.trim());
              if (value == null || !value.isFinite || value <= 0) {
                return;
              }
              Navigator.of(dialogContext).pop(value);
            },
            child: Text(context.l10n.pay),
          ),
        ],
      ),
    );

    if (amount != null) {
      bloc.add(MakePayment(debtId: widget.debtId, amount: amount));
    }
  }

  void _calculatePayoff(DebtEntity debt) {
    final input = double.tryParse(_payoffController.text.trim());
    final value = input == null || !input.isFinite || input <= 0
        ? debt.minimumPayment
        : input;
    if (!value.isFinite || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.enterValidMonthlyPayment)),
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
        title: Text(context.l10n.deleteDebtQuestion),
        content: Text(context.l10n.deleteDebtBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.delete),
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
        title: Text(context.l10n.debtDetails),
        actions: [
          IconButton(
            onPressed: _deleteDebt,
            tooltip: context.l10n.deleteDebt,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: BlocBuilder<DebtBloc, DebtState>(
        builder: (context, state) {
          if (state is DebtLoading) {
            return Center(
              child: CircularProgressIndicator(
                semanticsLabel: context.l10n.updatingDebt,
              ),
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
            return Center(child: Text(context.l10n.debtNotFound));
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
                context.l10n.payoffCalculator,
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
                      decoration: InputDecoration(
                        labelText: context.l10n.monthlyPayment,
                        prefixText: '\$ ',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => _calculatePayoff(debt),
                    child: Text(context.l10n.calculate),
                  ),
                ],
              ),
              if (payoff != null) ...[
                const SizedBox(height: 8),
                Text(
                  payoff.expectedDate == null
                      ? context.l10n.paymentNotCoverInterest
                      : context.l10n.projectedPayoff(
                          formatDisplayDate(payoff.expectedDate!),
                        ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (payoff.plan != null) ...[
                  if (payoff.interestSaved > 0 || payoff.monthsSaved > 0) ...[
                    const SizedBox(height: 12),
                    _PayoffImpact(
                      interestSaved: payoff.interestSaved,
                      monthsSaved: payoff.monthsSaved,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _PaymentPlanCard(plan: payoff.plan!),
                ],
              ],
              const SizedBox(height: 24),
              Text(
                context.l10n.paymentHistory,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              PaymentHistoryList(payments: debt.paymentHistory),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _makePayment,
                icon: const Icon(Icons.payments_outlined),
                label: Text(context.l10n.makePayment),
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

class _PayoffImpact extends StatelessWidget {
  const _PayoffImpact({required this.interestSaved, required this.monthsSaved});

  final double interestSaved;
  final int monthsSaved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Card(
      margin: EdgeInsets.zero,
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              Icons.savings_outlined,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.interestSavedLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  MoneyText(
                    interestSaved,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  l10n.monthsEarlierLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  '$monthsSaved',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
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

class _PaymentPlanCard extends StatelessWidget {
  const _PaymentPlanCard({required this.plan});

  final DebtPaymentPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.paymentPlan,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Chip(label: Text(l10n.paymentsCount(plan.months))),
              ],
            ),
            const SizedBox(height: 8),
            _PlanTotal(label: l10n.totalInterest, amount: plan.totalInterest),
            _PlanTotal(label: l10n.totalPaidLabel, amount: plan.totalPaid),
            const Divider(height: 20),
            for (final installment in plan.installments)
              _InstallmentRow(installment: installment),
          ],
        ),
      ),
    );
  }
}

class _PlanTotal extends StatelessWidget {
  const _PlanTotal({required this.label, required this.amount});

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          MoneyText(
            amount,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InstallmentRow extends StatelessWidget {
  const _InstallmentRow({required this.installment});

  final DebtInstallment installment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${installment.period}',
              style: theme.textTheme.labelMedium,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatDisplayDate(installment.date),
                  style: theme.textTheme.bodyMedium,
                ),
                Row(
                  children: [
                    Text(
                      '${l10n.principalLabel} ',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    MoneyText(
                      installment.principal,
                      style: theme.textTheme.labelSmall,
                    ),
                    Text(
                      ' · ${l10n.interestLabel} ',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    MoneyText(
                      installment.interest,
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MoneyText(
                installment.payment,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${l10n.remainingBalance}: ',
                    style: theme.textTheme.labelSmall,
                  ),
                  MoneyText(
                    installment.remaining,
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
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
                Chip(
                  label: Text(
                    debt.isPaid ? context.l10n.paid : context.l10n.active,
                  ),
                ),
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
                Text(
                  '${context.l10n.ofLabel} ',
                  style: theme.textTheme.bodyMedium,
                ),
                MoneyText(debt.totalAmount, style: theme.textTheme.bodyMedium),
                Text(
                  ' ${context.l10n.total}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppProgressBar(
              value: debt.progress,
              semanticsLabel: context.l10n.debtRepaymentProgress,
              semanticsValue: '${(debt.progress * 100).round()}%',
            ),
            const SizedBox(height: 12),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${debt.interestRate.toStringAsFixed(2)}% APR • '
                  '${context.l10n.minimum} ',
                  style: theme.textTheme.bodySmall,
                ),
                MoneyText(
                  debt.minimumPayment,
                  style: theme.textTheme.bodySmall,
                ),
                Text(
                  '/mo • ${context.l10n.dueOn(formatDisplayDate(debt.dueDate))}',
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
