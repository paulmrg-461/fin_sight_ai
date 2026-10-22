import 'package:material_ui/material_ui.dart';

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
        'No payments recorded yet.',
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
            title: Text('\$${payment.amount.toStringAsFixed(2)}'),
            subtitle: Text(formatDisplayDate(payment.paidAt)),
          ),
      ],
    );
  }
}
