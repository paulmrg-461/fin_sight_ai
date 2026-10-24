import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/currency/presentation/widgets/money_text.dart';
import '../../../../core/l10n/l10n.dart';
import '../../domain/entities/dashboard_entities.dart';

/// Pie chart and legend for expense categories.
class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({super.key, required this.breakdown});

  final List<CategoryBreakdown> breakdown;

  static const List<Color> _palette = [
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFFEF4444),
    Color(0xFF06B6D4),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = breakdown.fold<double>(
      0,
      (sum, category) => sum + category.amount,
    );

    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.spendingByCategory,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (breakdown.isEmpty)
              Text(
                context.l10n.noExpensesPeriod,
                style: theme.textTheme.bodyMedium,
              )
            else ...[
              SizedBox(
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(enabled: false),
                        sectionsSpace: 3,
                        centerSpaceRadius: 58,
                        sections: [
                          for (var index = 0; index < breakdown.length; index++)
                            PieChartSectionData(
                              value: breakdown[index].amount,
                              color: _palette[index % _palette.length],
                              radius: 48,
                              title: '',
                            ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.l10n.expenses,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        MoneyText(
                          total,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  for (var index = 0; index < breakdown.length; index++)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _palette[index % _palette.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${breakdown[index].category} '
                          '${breakdown[index].percentage.round()}%',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
