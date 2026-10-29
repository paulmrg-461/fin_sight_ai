import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app_currency.dart';
import '../../../../app/branding/app_logo.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/locale/presentation/bloc/locale_bloc.dart';
import '../../../../core/locale/presentation/bloc/locale_event.dart';
import '../../../../core/locale/presentation/bloc/locale_state.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/widgets/app_layout.dart';
import '../../../../features/security/presentation/bloc/security_cubit.dart';
import '../../../../features/security/presentation/bloc/security_state.dart';
import '../bloc/currency_bloc.dart';
import '../bloc/currency_event.dart';
import '../bloc/currency_state.dart';

/// App preferences: currency, language, categories, and brand footer.
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

          return BlocBuilder<LocaleBloc, LocaleState>(
            builder: (context, localeState) {
              final locale = localeState is LocaleLoaded
                  ? localeState.locale
                  : null;
              final localeValue = locale?.languageCode ?? 'system';

              return AppContent(
                maxWidth: 760,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    _SettingsLabel(text: l10n.preferences),
                    _SettingsSection(
                      icon: Icons.payments_outlined,
                      title: l10n.currency,
                      description: l10n.currencyDescription,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<AppCurrency>(
                              showSelectedIcon: false,
                              segments: [
                                for (final option in AppCurrency.values)
                                  ButtonSegment(
                                    value: option,
                                    label: Text(option.code),
                                  ),
                              ],
                              selected: {currency},
                              onSelectionChanged: (selection) {
                                context.read<CurrencyBloc>().add(
                                  ChangeCurrency(selection.first),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            currency == AppCurrency.cop
                                ? l10n.copCurrencyLabel
                                : l10n.usdCurrencyLabel,
                          ),
                          if (currencyState is CurrencyFailure) ...[
                            const SizedBox(height: 8),
                            Text(
                              currencyState.message,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SettingsSection(
                      icon: Icons.fingerprint_rounded,
                      title: l10n.securityTitle,
                      description: l10n.securityDescription,
                      child: BlocBuilder<SecurityCubit, SecurityState>(
                        builder: (context, security) {
                          return SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            value: security.enabled,
                            onChanged: security.loading || !security.available
                                ? null
                                : (value) => context
                                      .read<SecurityCubit>()
                                      .setEnabled(value),
                            title: Text(l10n.securityTitle),
                            subtitle: security.available
                                ? null
                                : Text(l10n.securityUnavailable),
                          );
                        },
                      ),
                    ),
                    _SettingsSection(
                      icon: Icons.translate_rounded,
                      title: l10n.language,
                      description: l10n.languageDescription,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<String>(
                              showSelectedIcon: false,
                              segments: [
                                ButtonSegment(
                                  value: 'system',
                                  label: Text(l10n.systemLanguage),
                                ),
                                ButtonSegment(
                                  value: 'en',
                                  label: Text(l10n.english),
                                ),
                                ButtonSegment(
                                  value: 'es',
                                  label: Text(l10n.spanish),
                                ),
                              ],
                              selected: {localeValue},
                              onSelectionChanged: (selection) {
                                final value = selection.first;
                                context.read<LocaleBloc>().add(
                                  ChangeLocale(
                                    value == 'system' ? null : Locale(value),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (localeState is LocaleFailure) ...[
                            const SizedBox(height: 8),
                            Text(
                              localeState.message,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SettingsLabel(text: l10n.dataSection),
                    _SettingsSection(
                      icon: Icons.label_outline_rounded,
                      title: l10n.categoriesTitle,
                      description: l10n.categoriesDescription,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.category_outlined,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                        title: Text(l10n.manageCategories),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () =>
                            context.pushNamed(AppRoutes.categoriesName),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SettingsLabel(text: l10n.developerTitle),
                    _SettingsSection(
                      icon: Icons.person_pin_outlined,
                      title: l10n.developerTitle,
                      description: l10n.developerRole,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            'assets/branding/devpaul_logo.jpeg',
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: const Text('DevPaul'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.pushNamed(AppRoutes.developerName),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: Column(
                        children: [
                          const AppLogo(size: 48),
                          const SizedBox(height: 10),
                          Text(
                            l10n.settingsFooter,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SettingsLabel extends StatelessWidget {
  const _SettingsLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.description,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    icon,
                    size: 19,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
