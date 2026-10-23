import 'package:material_ui/material_ui.dart';

import '../../../../core/currency/presentation/widgets/money_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/dashboard_entities.dart';

/// Four KPI cards summarizing the selected period.
class SummaryCards extends StatelessWidget {
  const SummaryCards({super.key, required this.summary});

  final DashboardSummaryEntity summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        _SummaryCard(
          label: 'Income',
          value: MoneyText(summary.totalIncome),
          icon: Icons.south_west,
          color: AppColors.emerald,
        ),
        _SummaryCard(
          label: 'Expenses',
          value: MoneyText(summary.totalExpenses),
          icon: Icons.north_east,
          color: AppColors.danger,
        ),
        _SummaryCard(
          label: 'Balance',
          value: MoneyText(summary.balance),
          icon: Icons.account_balance_wallet_outlined,
          color: theme.colorScheme.primary,
        ),
        _SummaryCard(
          label: 'Savings rate',
          value: Text('${summary.savingsRate.toStringAsFixed(1)}%'),
          icon: Icons.savings_outlined,
          color: theme.colorScheme.tertiary,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final Widget value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            DefaultTextStyle(
              style:
                  theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ) ??
                  const TextStyle(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              child: value,
            ),
          ],
        ),
      ),
    );
  }
}
