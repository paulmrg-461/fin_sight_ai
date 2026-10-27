import 'package:material_ui/material_ui.dart';

import '../../../../core/currency/presentation/widgets/money_text.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../savings/domain/entities/savings_goal_entity.dart';

class SavingsSummaryCard extends StatelessWidget {
  const SavingsSummaryCard({
    super.key,
    required this.goals,
    required this.onTap,
  });

  final List<SavingsGoalEntity> goals;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    if (goals.isEmpty) {
      return const SizedBox.shrink();
    }

    final saved = goals.fold<double>(0, (sum, goal) => sum + goal.savedAmount);
    final target = goals.fold<double>(
      0,
      (sum, goal) => sum + goal.targetAmount,
    );
    final next =
        goals
            .where((goal) => goal.targetDate != null && !goal.isComplete)
            .toList(growable: false)
          ..sort((a, b) => a.targetDate!.compareTo(b.targetDate!));

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
                    Icons.savings_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.savingsGoals,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Chip(label: Text(l10n.savingsGoalsCount(goals.length))),
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
                      l10n.totalSaved,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  MoneyText(
                    saved,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(' / ', style: theme.textTheme.bodySmall),
                  MoneyText(target, style: theme.textTheme.bodySmall),
                ],
              ),
              if (next.isNotEmpty) ...[
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
                        '${next.first.name} · '
                        '${formatDisplayDate(next.first.targetDate!)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
