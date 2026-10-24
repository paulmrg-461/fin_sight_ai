import 'package:material_ui/material_ui.dart';

import '../../../../core/currency/presentation/widgets/money_text.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../domain/entities/receivable_entity.dart';

/// Chronological list of payments received for a receivable.
class ReceivablePaymentHistoryList extends StatelessWidget {
  const ReceivablePaymentHistoryList({super.key, required this.payments});

  final List<ReceivablePayment> payments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (payments.isEmpty) {
      return Text(
        context.l10n.noPaymentsReceived,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final ordered = [...payments]..sort((a, b) => b.paidAt.compareTo(a.paidAt));

    return Column(
      children: [
        for (final payment in ordered)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.check_circle_outline,
              color: theme.colorScheme.primary,
            ),
            title: MoneyText(payment.amount),
            subtitle: Text(
              payment.note == null || payment.note!.isEmpty
                  ? formatDisplayDate(payment.paidAt)
                  : '${formatDisplayDate(payment.paidAt)} • ${payment.note}',
            ),
          ),
      ],
    );
  }
}
