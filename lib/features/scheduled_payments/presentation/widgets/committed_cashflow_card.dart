import 'package:material_ui/material_ui.dart';

import '../../../../core/currency/presentation/widgets/money_text.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../domain/entities/committed_cashflow.dart';

/// Compact 30/90-day committed-cashflow preview.
class CommittedCashflowCard extends StatefulWidget {
  const CommittedCashflowCard({
    super.key,
    required this.thirtyDays,
    required this.ninetyDays,
  });

  final CommittedCashflow? thirtyDays;
  final CommittedCashflow? ninetyDays;

  @override
  State<CommittedCashflowCard> createState() => _CommittedCashflowCardState();
}

class _CommittedCashflowCardState extends State<CommittedCashflowCard> {
  static const int _previewCount = 3;

  int _days = 30;

  @override
  Widget build(BuildContext context) {
    final thirty = widget.thirtyDays;
    final ninety = widget.ninetyDays;
    if (thirty == null && ninety == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final l10n = context.l10n;
    final data = _days == 30 ? thirty : ninety;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lock_clock_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.committedCashflow,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: [
                    ButtonSegment(value: 30, label: Text(l10n.committedDays30)),
                    ButtonSegment(value: 90, label: Text(l10n.committedDays90)),
                  ],
                  selected: {_days},
                  onSelectionChanged: (selection) {
                    setState(() => _days = selection.first);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (data == null || data.isEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.noCommittedPayments,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.noCommittedPaymentsBody,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.committedTotal,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  MoneyText(
                    data.total,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final payment in data.take(_previewCount))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          payment.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatDisplayDate(payment.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      MoneyText(
                        payment.amount,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
