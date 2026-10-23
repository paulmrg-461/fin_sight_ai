import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/utils/date_formatters.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/monthly_comparison_chart.dart';
import '../widgets/recent_transactions_list.dart';
import '../../../auth/presentation/widgets/account_button.dart';
import '../../../sync/presentation/widgets/sync_status_chip.dart';
import '../widgets/summary_cards.dart';

/// Analytics dashboard with navigation shortcuts and theme toggle.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.themeController});

  final ThemeController themeController;

  Future<void> _openFeature(BuildContext context, String route) async {
    final bloc = context.read<DashboardBloc>();
    await context.pushNamed(route);
    bloc.add(const RefreshData());
  }

  Future<void> _pickRange(BuildContext context) async {
    final bloc = context.read<DashboardBloc>();
    final now = DateTime.now();
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDateRange: DateTimeRange(
        start: DateTime(now.year, now.month),
        end: DateTime(now.year, now.month + 1, 0),
      ),
      helpText: 'Dashboard period',
    );
    if (selected == null) {
      return;
    }
    bloc.add(
      ChangeDateRange(
        start: startOfDay(selected.start),
        end: endOfDay(selected.end),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Scaffold(
          appBar: AppBar(
            title: const Text('FinSight AI'),
            actions: [
              const AccountButton(),
              const SyncStatusChip(),
              IconButton(
                onPressed: () => _pickRange(context),
                tooltip: 'Change period',
                icon: const Icon(Icons.date_range_outlined),
              ),
              IconButton(
                onPressed: () => context.pushNamed(AppRoutes.settingsName),
                tooltip: 'Settings',
                icon: const Icon(Icons.settings_outlined),
              ),
              IconButton(
                onPressed: themeController.toggle,
                tooltip: isDark
                    ? 'Switch to light mode'
                    : 'Switch to dark mode',
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                ),
              ),
            ],
          ),
          body: BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              return switch (state) {
                DashboardInitial() || DashboardLoading() => const Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: 'Loading dashboard',
                  ),
                ),
                DashboardFailure(:final message) => _DashboardError(
                  message: message,
                  onRetry: () =>
                      context.read<DashboardBloc>().add(const LoadDashboard()),
                ),
                DashboardEmpty(:final start, :final end) => ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _PeriodLabel(start: start, end: end),
                    const SizedBox(height: 16),
                    _EmptyDashboard(
                      onAddTransaction: () =>
                          _openFeature(context, AppRoutes.transactionsName),
                    ),
                    const SizedBox(height: 24),
                    _QuickActions(
                      onOpen: (route) => _openFeature(context, route),
                    ),
                  ],
                ),
                DashboardLoaded(
                  :final summary,
                  :final breakdown,
                  :final comparison,
                  :final recentTransactions,
                  :final start,
                  :final end,
                ) =>
                  RefreshIndicator(
                    onRefresh: () async {
                      final bloc = context.read<DashboardBloc>();
                      bloc.add(const RefreshData());
                      await Future<void>.delayed(
                        const Duration(milliseconds: 500),
                      );
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        _PeriodLabel(start: start, end: end),
                        const SizedBox(height: 16),
                        SummaryCards(summary: summary),
                        CategoryPieChart(breakdown: breakdown),
                        MonthlyComparisonChart(comparison: comparison),
                        RecentTransactionsList(
                          transactions: recentTransactions,
                        ),
                        const SizedBox(height: 16),
                        _QuickActions(
                          onOpen: (route) => _openFeature(context, route),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
              };
            },
          ),
        );
      },
    );
  }
}

class _PeriodLabel extends StatelessWidget {
  const _PeriodLabel({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${formatDisplayDate(start)} – ${formatDisplayDate(end)}',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard({required this.onAddTransaction});

  final VoidCallback onAddTransaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.insights_outlined,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text('No transactions yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Add your first income or expense to unlock spending insights.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAddTransaction,
              icon: const Icon(Icons.add),
              label: const Text('Add a transaction'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onOpen});

  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Quick actions',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.swap_vert, size: 18),
                  label: const Text('Transactions'),
                  onPressed: () => onOpen(AppRoutes.transactionsName),
                ),
                ActionChip(
                  avatar: const Icon(Icons.account_balance_outlined, size: 18),
                  label: const Text('Debts'),
                  onPressed: () => onOpen(AppRoutes.debtsName),
                ),
                ActionChip(
                  avatar: const Icon(Icons.pie_chart_outline, size: 18),
                  label: const Text('Budgets'),
                  onPressed: () => onOpen(AppRoutes.budgetsName),
                ),
                ActionChip(
                  avatar: const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 18,
                  ),
                  label: const Text('Money'),
                  onPressed: () => onOpen(AppRoutes.moneyName),
                ),
                ActionChip(
                  avatar: const Icon(Icons.document_scanner_outlined, size: 18),
                  label: const Text('Scan receipt'),
                  onPressed: () => onOpen(AppRoutes.ocrName),
                ),
                ActionChip(
                  avatar: const Icon(Icons.auto_awesome_outlined, size: 18),
                  label: const Text('AI coach'),
                  onPressed: () => onOpen(AppRoutes.aiCoachName),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
