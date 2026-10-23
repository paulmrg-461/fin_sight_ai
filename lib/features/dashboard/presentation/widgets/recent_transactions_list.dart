import 'package:material_ui/material_ui.dart';

import '../../../../core/currency/presentation/widgets/money_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';

/// Compact list of the latest transactions in the selected period.
class RecentTransactionsList extends StatelessWidget {
  const RecentTransactionsList({super.key, required this.transactions});

  final List<TransactionEntity> transactions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Recent activity',
                style: theme.textTheme.titleMedium,
              ),
            ),
            for (final transaction in transactions)
              ListTile(
                dense: true,
                leading: Icon(
                  transaction.isIncome ? Icons.south_west : Icons.north_east,
                  color: transaction.isIncome
                      ? AppColors.emerald
                      : AppColors.danger,
                ),
                title: Text(
                  transaction.description.isEmpty
                      ? transaction.category
                      : transaction.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${transaction.category} • '
                  '${formatDisplayDate(transaction.date)}',
                ),
                trailing: MoneyText(
                  transaction.signedAmount,
                  signed: true,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: transaction.isIncome
                        ? AppColors.emerald
                        : AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
