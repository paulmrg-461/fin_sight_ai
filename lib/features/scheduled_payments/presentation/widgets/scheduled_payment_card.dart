import 'package:material_ui/material_ui.dart';

import '../../../../core/currency/presentation/widgets/money_text.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../domain/entities/scheduled_payment_entity.dart';

/// Summary card for one scheduled payment.
class ScheduledPaymentCard extends StatelessWidget {
  const ScheduledPaymentCard({
    super.key,
    required this.payment,
    required this.onPayNow,
    required this.onToggleActive,
    required this.onDelete,
  });

  final ScheduledPaymentEntity payment;
  final VoidCallback onPayNow;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final today = DateTime.now();
    final dueToday = _sameDay(payment.nextDueDate, today);
    final paidToday =
        payment.lastPaidAt != null && _sameDay(payment.lastPaidAt!, today);
    final overdue = payment.nextDueDate.isBefore(
      DateTime(today.year, today.month, today.day),
    );

    final statusColor = !payment.isActive
        ? theme.colorScheme.onSurfaceVariant
        : overdue
        ? theme.colorScheme.error
        : dueToday
        ? theme.colorScheme.tertiary
        : theme.colorScheme.onSurfaceVariant;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: payment.isActive
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    payment.isActive
                        ? Icons.event_repeat
                        : Icons.pause_circle_outline,
                    color: payment.isActive
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(payment.name, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (payment.isIncome) ...[
                            _StatusChip(
                              label: l10n.income,
                              color: theme.colorScheme.primaryContainer,
                              textColor: theme.colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Text(
                              '${payment.category} • '
                              '${payment.frequency == PaymentFrequency.monthly ? l10n.monthly : l10n.yearly}',
                              style: theme.textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                MoneyText(
                  payment.amount,
                  signed: payment.isIncome,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: payment.isIncome ? theme.colorScheme.primary : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.event_outlined, size: 16, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  l10n.dueOn(formatDisplayDate(payment.nextDueDate)),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: statusColor,
                  ),
                ),
                if (payment.isActive && overdue) ...[
                  const SizedBox(width: 8),
                  _StatusChip(
                    label: l10n.overdue,
                    color: theme.colorScheme.errorContainer,
                    textColor: theme.colorScheme.onErrorContainer,
                  ),
                ] else if (payment.isActive && dueToday) ...[
                  const SizedBox(width: 8),
                  _StatusChip(
                    label: l10n.dueToday,
                    color: theme.colorScheme.tertiaryContainer,
                    textColor: theme.colorScheme.onTertiaryContainer,
                  ),
                ] else if (!payment.isActive) ...[
                  const SizedBox(width: 8),
                  _StatusChip(
                    label: l10n.paused,
                    color: theme.colorScheme.surfaceContainerHighest,
                    textColor: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
                const Spacer(),
                PopupMenuButton<String>(
                  tooltip: l10n.scheduledPayments,
                  onSelected: (action) {
                    switch (action) {
                      case 'toggle':
                        onToggleActive();
                      case 'delete':
                        onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(
                        payment.isActive
                            ? l10n.pausePayment
                            : l10n.resumePayment,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(l10n.deleteScheduledPayment),
                    ),
                  ],
                ),
              ],
            ),
            if (payment.isActive && !paidToday) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: onPayNow,
                  icon: const Icon(Icons.payments_outlined, size: 18),
                  label: Text(l10n.payNow),
                ),
              ),
            ] else if (paidToday) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Chip(
                  avatar: Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  label: Text(l10n.paidToday),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: textColor),
      ),
    );
  }
}
