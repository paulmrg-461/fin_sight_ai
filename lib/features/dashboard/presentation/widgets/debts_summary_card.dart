import 'package:material_ui/material_ui.dart';

import '../../../../core/currency/presentation/widgets/money_text.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../debts/domain/entities/debt_entity.dart';

/// Compact overview of the debts that still have a balance.
class DebtsSummaryCard extends StatelessWidget {
  const DebtsSummaryCard({super.key, required this.debts, required this.onTap});

  final List<DebtEntity> debts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final active = debts.where((debt) => !debt.isPaid).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    if (active.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = active.fold<double>(
      0,
      (sum, debt) => sum + debt.remainingAmount,
    );
    final next = active.first;

    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_balance_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.currentDebts,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Chip(label: Text(l10n.activeDebts(active.length))),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.totalDebt,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  MoneyText(
                    total,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${next.creditorName} · '
                      '${l10n.dueOn(formatDisplayDate(next.dueDate))}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  MoneyText(
                    next.minimumPayment,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
