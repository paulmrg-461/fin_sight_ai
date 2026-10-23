import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../app_currency.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/locale/presentation/bloc/locale_bloc.dart';
import '../../../../core/locale/presentation/bloc/locale_event.dart';
import '../../../../core/locale/presentation/bloc/locale_state.dart';
import '../bloc/currency_bloc.dart';
import '../bloc/currency_event.dart';
import '../bloc/currency_state.dart';

/// App preferences: currency and language.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: BlocBuilder<CurrencyBloc, CurrencyState>(
        builder: (context, currencyState) {
          final currency = currencyState is CurrencyLoaded
              ? currencyState.currency
              : AppCurrency.cop;
          final theme = Theme.of(context);

          return BlocBuilder<LocaleBloc, LocaleState>(
            builder: (context, localeState) {
              final locale = localeState is LocaleLoaded
                  ? localeState.locale
                  : null;
              final localeValue = locale?.languageCode ?? 'system';

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(l10n.currency, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    l10n.currencyDescription,
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
                  Text(
                    currency == AppCurrency.cop
                        ? l10n.copCurrencyLabel
                        : l10n.usdCurrencyLabel,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (currencyState is CurrencyFailure) ...[
                    const SizedBox(height: 12),
                    Text(
                      currencyState.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Text(l10n.language, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    l10n.languageDescription,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'system',
                        label: Text(l10n.systemLanguage),
                      ),
                      ButtonSegment(value: 'en', label: Text(l10n.english)),
                      ButtonSegment(value: 'es', label: Text(l10n.spanish)),
                    ],
                    selected: {localeValue},
                    onSelectionChanged: (selection) {
                      final value = selection.first;
                      context.read<LocaleBloc>().add(
                        ChangeLocale(value == 'system' ? null : Locale(value)),
                      );
                    },
                  ),
                  if (localeState is LocaleFailure) ...[
                    const SizedBox(height: 12),
                    Text(
                      localeState.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}
