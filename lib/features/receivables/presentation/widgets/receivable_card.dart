import 'package:material_ui/material_ui.dart';

import '../../../../core/currency/presentation/widgets/money_text.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/widgets/app_progress_bar.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../domain/entities/receivable_entity.dart';

/// Summary card for a person who owes the user money.
class ReceivableCard extends StatelessWidget {
  const ReceivableCard({
    super.key,
    required this.receivable,
    required this.onTap,
    required this.onPay,
    required this.onDelete,
  });

  final ReceivableEntity receivable;
  final VoidCallback onTap;
  final VoidCallback onPay;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = receivable.debtorName.trim().isEmpty
        ? '?'
        : receivable.debtorName.trim().characters.first.toUpperCase();

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      initial,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          receivable.debtorName,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          receivable.dueDate == null
                              ? context.l10n.lentOn(
                                  formatDisplayDate(receivable.dateLent),
                                )
                              : context.l10n.dueOn(
                                  formatDisplayDate(receivable.dueDate!),
                                ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(
                      receivable.isPaid
                          ? context.l10n.receivablePaid
                          : context.l10n.active,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  MoneyText(
                    receivable.remainingAmount,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    ' ${context.l10n.remainingAmount} '
                    '${context.l10n.ofLabel} ',
                    style: theme.textTheme.bodyMedium,
                  ),
                  MoneyText(
                    receivable.totalAmount,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AppProgressBar(
                value: receivable.progress,
                color: theme.colorScheme.tertiary,
                semanticsLabel: context.l10n.receivableProgress,
                semanticsValue: '${(receivable.progress * 100).round()}%',
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${context.l10n.received}: ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
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
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    key: ValueKey('receivable-pay-${receivable.id}'),
                    onPressed: receivable.isPaid ? null : onPay,
                    icon: const Icon(Icons.payments_outlined),
                    label: Text(context.l10n.addPayment),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                  IconButton(
                    key: ValueKey('receivable-delete-${receivable.id}'),
                    onPressed: onDelete,
                    tooltip: context.l10n.deleteReceivable,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
