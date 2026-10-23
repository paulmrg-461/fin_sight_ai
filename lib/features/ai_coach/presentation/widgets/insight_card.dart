import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../domain/entities/financial_insight_entity.dart';

/// Displays one AI insight, styled by its type.
class InsightCard extends StatelessWidget {
  const InsightCard({super.key, required this.insight});

  final FinancialInsightEntity insight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color, label) = switch (insight.type) {
      InsightType.suggestion => (
        Icons.lightbulb_outline,
        AppColors.emerald,
        'Suggestion',
      ),
      InsightType.alert => (
        Icons.warning_amber_outlined,
        AppColors.danger,
        'Alert',
      ),
      InsightType.analysis => (
        Icons.insights_outlined,
        theme.colorScheme.secondary,
        'Analysis',
      ),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        formatDisplayDate(insight.timestamp),
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(insight.content, style: theme.textTheme.bodyMedium),
                  if (insight.relatedTransactionId != null) ...[
                    const SizedBox(height: 8),
                    Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.link, size: 16),
                      label: Text(
                        'Transaction ${insight.relatedTransactionId}',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
