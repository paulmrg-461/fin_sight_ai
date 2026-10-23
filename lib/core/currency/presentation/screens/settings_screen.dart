import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../app_currency.dart';
import '../bloc/currency_bloc.dart';
import '../bloc/currency_event.dart';
import '../bloc/currency_state.dart';

/// App preferences, including the active currency.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocBuilder<CurrencyBloc, CurrencyState>(
        builder: (context, state) {
          final currency = state is CurrencyLoaded
              ? state.currency
              : AppCurrency.cop;
          final theme = Theme.of(context);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Currency', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Changing the currency updates labels and formatting. '
                'Amounts are not converted with exchange rates.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              SegmentedButton<AppCurrency>(
                segments: [
                  for (final option in AppCurrency.values)
                    ButtonSegment(value: option, label: Text(option.code)),
                ],
                selected: {currency},
                onSelectionChanged: (selection) {
                  context.read<CurrencyBloc>().add(
                    ChangeCurrency(selection.first),
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(currency.label, style: theme.textTheme.bodyMedium),
              if (state is CurrencyFailure) ...[
                const SizedBox(height: 12),
                Text(
                  state.message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
