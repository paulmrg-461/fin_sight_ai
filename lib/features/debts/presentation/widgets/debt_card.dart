import 'package:material_ui/material_ui.dart';

import '../../../../core/currency/presentation/widgets/money_text.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../domain/entities/debt_entity.dart';

/// Summary card with repayment progress.
class DebtCard extends StatelessWidget {
  const DebtCard({super.key, required this.debt, required this.onTap});

  final DebtEntity debt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                  Expanded(
                    child: Text(
                      debt.creditorName,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Chip(
                    label: Text(debt.isPaid ? 'Paid' : 'Active'),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  MoneyText(
                    debt.remainingAmount,
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(' remaining of ', style: theme.textTheme.bodyMedium),
                  MoneyText(
                    debt.totalAmount,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: debt.progress,
                  minHeight: 8,
                  semanticsLabel: 'Debt repayment progress',
                  semanticsValue: '${(debt.progress * 100).round()}%',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${debt.interestRate.toStringAsFixed(2)}% APR • '
                'Due ${formatDisplayDate(debt.dueDate)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
