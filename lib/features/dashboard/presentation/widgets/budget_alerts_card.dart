import 'package:material_ui/material_ui.dart';

import '../../../../core/currency/presentation/widgets/money_text.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_progress_bar.dart';
import '../../../budgets/domain/entities/budget_entity.dart';

/// Categories already near or over their monthly limit.
class BudgetAlertsCard extends StatelessWidget {
  const BudgetAlertsCard({
    super.key,
    required this.progress,
    required this.onTap,
  });

  static const double threshold = 0.8;

  final List<BudgetProgress> progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final alerts =
        progress
            .where(
              (item) =>
                  item.budget.monthlyLimit > 0 &&
                  item.spent / item.budget.monthlyLimit >= threshold,
            )
            .toList()
          ..sort((a, b) {
            final ra = a.spent / a.budget.monthlyLimit;
            final rb = b.spent / b.budget.monthlyLimit;
            return rb.compareTo(ra);
          });
    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }

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
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.budgetAlerts,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final item in alerts.take(3)) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.budget.category,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      l10n.budgetAlertPercent(
                        ((item.spent / item.budget.monthlyLimit) * 100).round(),
                      ),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: item.spent > item.budget.monthlyLimit
                            ? AppColors.danger
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                AppProgressBar(
                  value: item.budget.monthlyLimit <= 0
                      ? 0
                      : item.spent / item.budget.monthlyLimit,
                  height: 6,
                  color: item.spent > item.budget.monthlyLimit
                      ? AppColors.danger
                      : theme.colorScheme.primary,
                  semanticsLabel: item.budget.category,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    MoneyText(item.spent, style: theme.textTheme.labelSmall),
                    Text(' / ', style: theme.textTheme.labelSmall),
                    MoneyText(
                      item.budget.monthlyLimit,
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
