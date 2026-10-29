import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/main_shell.dart';
import '../../../../core/currency/presentation/widgets/money_text.dart';
import '../../../../core/l10n/failure_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../core/widgets/app_layout.dart';
import '../../../../core/widgets/app_states.dart';
import '../../domain/entities/scheduled_payment_entity.dart';
import '../../domain/services/expected_income_calculator.dart';
import '../bloc/scheduled_payment_bloc.dart';
import '../bloc/scheduled_payment_event.dart';
import '../bloc/scheduled_payment_state.dart';
import '../widgets/committed_cashflow_card.dart';
import '../widgets/scheduled_payment_card.dart';
import '../widgets/scheduled_payment_form.dart';

/// Recurring expenses and their next due dates.
class ScheduledPaymentScreen extends StatelessWidget {
  const ScheduledPaymentScreen({super.key});

  Future<void> _openForm(
    BuildContext context, {
    ScheduledPaymentEntity? initial,
  }) {
    final bloc = context.read<ScheduledPaymentBloc>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: ScheduledPaymentForm(initial: initial),
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    ScheduledPaymentEntity payment,
  ) async {
    final l10n = context.l10n;
    final bloc = context.read<ScheduledPaymentBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteScheduledPaymentQuestion),
        content: Text(l10n.deleteScheduledPaymentBody),
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
      bloc.add(DeleteScheduledPayment(payment.id));
    }
  }

  List<Widget> _paymentRows(
    BuildContext context,
    List<ScheduledPaymentEntity> payments,
  ) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekEnd = today.add(const Duration(days: 7));

    DateTime day(DateTime value) =>
        DateTime(value.year, value.month, value.day);

    final active = payments.where((payment) => payment.isActive).toList()
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
    final paused = payments.where((payment) => !payment.isActive).toList()
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));

    final overdue = active
        .where((payment) => day(payment.nextDueDate).isBefore(today))
        .toList();
    final dueToday = active
        .where((payment) => day(payment.nextDueDate) == today)
        .toList();
    final thisWeek = active.where((payment) {
      final due = day(payment.nextDueDate);
      return due.isAfter(today) && due.isBefore(weekEnd);
    }).toList();
    final upcoming = active.where((payment) {
      final due = day(payment.nextDueDate);
      return due.isAfter(today) && !due.isBefore(weekEnd);
    }).toList();

    Widget card(ScheduledPaymentEntity payment) => ScheduledPaymentCard(
      payment: payment,
      onPayNow: () => context.read<ScheduledPaymentBloc>().add(
        PayScheduledPayment(payment.id),
      ),
      onEdit: () => _openForm(context, initial: payment),
      onToggleActive: () => context.read<ScheduledPaymentBloc>().add(
        SetScheduledPaymentActive(id: payment.id, isActive: !payment.isActive),
      ),
      onDelete: () => _delete(context, payment),
    );

    List<Widget> group(
      String label,
      List<ScheduledPaymentEntity> rows, {
      Color? color,
    }) {
      if (rows.isEmpty) {
        return const [];
      }
      return [
        _ScheduledGroupHeader(label: label, count: rows.length, color: color),
        for (final payment in rows) card(payment),
      ];
    }

    return [
      ...group(l10n.scheduledOverdue, overdue, color: AppColors.danger),
      ...group(l10n.today, dueToday),
      ...group(l10n.scheduledThisWeek, thisWeek),
      ...group(l10n.scheduledUpcoming, upcoming),
      ...group(l10n.scheduledPaused, paused),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        leading: const AppMenuButton(),
        title: Text(l10n.scheduledPayments),
        actions: [
          IconButton(
            icon: const Icon(Icons.label_outline),
            tooltip: l10n.manageCategories,
            onPressed: () => context.pushNamed(AppRoutes.categoriesName),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.addScheduledPayment),
      ),
      body: BlocBuilder<ScheduledPaymentBloc, ScheduledPaymentState>(
        builder: (context, state) {
          final incomeSummary = state is ScheduledPaymentLoaded
              ? ExpectedIncomeCalculator.calculate(state.payments)
              : null;
          return switch (state) {
            ScheduledPaymentInitial() || ScheduledPaymentLoading() =>
              const Center(child: CircularProgressIndicator()),
            ScheduledPaymentFailure(:final message) => AppErrorState(
              message: context.failureText(message),
              onRetry: () => context.read<ScheduledPaymentBloc>().add(
                const LoadScheduledPayments(),
              ),
            ),
            ScheduledPaymentEmpty(
              :final autoCreated,
              :final error,
              :final committed30,
              :final committed90,
            ) =>
              AppContent(
                padding: EdgeInsets.zero,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  children: [
                    if (autoCreated > 0) ...[
                      _AutoCreatedBanner(count: autoCreated),
                      const SizedBox(height: 12),
                    ],
                    if (error != null) ...[
                      _ErrorBanner(message: context.failureText(error)),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      l10n.scheduledPaymentsDescription,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    CommittedCashflowCard(
                      thirtyDays: committed30,
                      ninetyDays: committed90,
                    ),
                    AppEmptyState(
                      icon: Icons.event_repeat_rounded,
                      title: l10n.noScheduledPayments,
                      message: l10n.noScheduledPaymentsBody,
                      actionLabel: l10n.addFirstScheduledPayment,
                      onAction: () => _openForm(context),
                    ),
                  ],
                ),
              ),
            ScheduledPaymentLoaded(
              :final payments,
              :final autoCreated,
              :final error,
              :final committed30,
              :final committed90,
            ) =>
              AppContent(
                padding: EdgeInsets.zero,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  children: [
                    Text(
                      l10n.scheduledPaymentsDescription,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    if (incomeSummary != null && incomeSummary.isNotEmpty) ...[
                      _ExpectedIncomeCard(summary: incomeSummary),
                      const SizedBox(height: 12),
                    ],
                    if (autoCreated > 0) ...[
                      _AutoCreatedBanner(count: autoCreated),
                      const SizedBox(height: 12),
                    ],
                    if (error != null) ...[
                      _ErrorBanner(message: context.failureText(error)),
                      const SizedBox(height: 12),
                    ],
                    CommittedCashflowCard(
                      thirtyDays: committed30,
                      ninetyDays: committed90,
                    ),
                    ..._paymentRows(context, payments),
                  ],
                ),
              ),
          };
        },
      ),
    );
  }
}

class _ExpectedIncomeCard extends StatelessWidget {
  const _ExpectedIncomeCard({required this.summary});

  final Summary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final nextIncomeDate = summary.nextIncomeDate;

    return BrandGradientCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.incomeSchedule,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      l10n.expectedMonthlyIncome,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          MoneyText(
            summary.monthlyAmount,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
            ),
          ),
          if (nextIncomeDate != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.event_outlined,
                  size: 16,
                  color: Colors.white70,
                ),
                const SizedBox(width: 5),
                Text(
                  l10n.nextIncome(formatDisplayDate(nextIncomeDate)),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AutoCreatedBanner extends StatelessWidget {
  const _AutoCreatedBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.autoCreatedPayments(count),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduledGroupHeader extends StatelessWidget {
  const _ScheduledGroupHeader({
    required this.label,
    required this.count,
    this.color,
  });

  final String label;
  final int count;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
