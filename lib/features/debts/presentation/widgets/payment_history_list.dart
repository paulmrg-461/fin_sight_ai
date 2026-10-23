import 'package:material_ui/material_ui.dart';

import '../../../../core/currency/presentation/widgets/money_text.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../domain/entities/debt_entity.dart';

/// Chronological list of payments applied to a debt.
class PaymentHistoryList extends StatelessWidget {
  const PaymentHistoryList({super.key, required this.payments});

  final List<PaymentRecord> payments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (payments.isEmpty) {
      return Text(
        context.l10n.noPaymentsYet,
        style: theme.textTheme.bodyMedium,
      );
    }

    final ordered = [...payments]..sort((a, b) => b.paidAt.compareTo(a.paidAt));

    return Column(
      children: [
        for (final payment in ordered)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.check_circle_outline),
            title: MoneyText(payment.amount),
            subtitle: Text(formatDisplayDate(payment.paidAt)),
          ),
      ],
    );
  }
}
