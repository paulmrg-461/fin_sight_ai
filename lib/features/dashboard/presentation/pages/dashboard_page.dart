import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/branding/app_logo.dart';
import '../../../../app/main_shell.dart';
import '../../../../core/currency/presentation/widgets/money_text.dart';
import '../../../../core/l10n/failure_text.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../core/widgets/app_layout.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_states.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_event.dart';
import '../bloc/dashboard_state.dart';
import '../../domain/entities/dashboard_entities.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/committed_30_days_card.dart';
import '../widgets/budget_alerts_card.dart';
import '../widgets/debts_summary_card.dart';
import '../widgets/savings_summary_card.dart';
import '../widgets/monthly_comparison_chart.dart';
import '../widgets/recent_transactions_list.dart';
import '../../../wallets/domain/entities/wallet_entity.dart';
import '../../../wallets/presentation/bloc/wallet_bloc.dart';
import '../../../wallets/presentation/bloc/wallet_state.dart';
import '../../../receivables/presentation/widgets/receivables_summary_card.dart';
import '../../../debts/presentation/bloc/debt_bloc.dart';
import '../../../debts/domain/entities/debt_entity.dart';
import '../../../savings/domain/entities/savings_goal_entity.dart';
import '../../../debts/presentation/bloc/debt_state.dart';
import '../../../savings/presentation/bloc/savings_bloc.dart';
import '../../../savings/presentation/bloc/savings_state.dart';
import '../../../budgets/domain/entities/budget_entity.dart';
import '../../../budgets/presentation/bloc/budget_bloc.dart';
import '../../../budgets/presentation/bloc/budget_state.dart';

/// Analytics dashboard with navigation shortcuts.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Future<void> _openFeature(BuildContext context, String route) async {
    final shell = ShellScope.maybeOf(context);
    if (shell != null && shell.goToPrimary(route)) {
      return;
    }
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
      helpText: context.l10n.period,
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

  List<Widget> _responsiveSections(
    BuildContext context, {
    required List<Widget> summary,
    required List<Widget> insights,
  }) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    if (!wide) {
      return [...summary, ...insights];
    }
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Column(children: summary)),
          const SizedBox(width: 16),
          Expanded(child: Column(children: insights)),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppMenuButton(),
        title: AppLogo(
          size: 30,
          showWordmark: true,
          wordmarkStyle: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: () => context.pushNamed(AppRoutes.searchName),
            tooltip: context.l10n.globalSearch,
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            onPressed: () => _pickRange(context),
            tooltip: context.l10n.changePeriod,
            icon: const Icon(Icons.date_range_outlined),
          ),
        ],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          return switch (state) {
            DashboardInitial() || DashboardLoading() => Center(
              child: CircularProgressIndicator(
                semanticsLabel: context.l10n.loading,
              ),
            ),
            DashboardFailure(:final message) => AppErrorState(
              message: context.failureText(message),
              onRetry: () =>
                  context.read<DashboardBloc>().add(const LoadDashboard()),
            ),
            DashboardEmpty(:final start, :final end) => AppContent(
              padding: EdgeInsets.zero,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  _PeriodPill(
                    start: start,
                    end: end,
                    onTap: () => _pickRange(context),
                  ),
                  const SizedBox(height: 14),
                  const _AccountsOverview(),
                  const SizedBox(height: 14),
                  ReceivablesSummaryCard(
                    onTap: () =>
                        _openFeature(context, AppRoutes.receivablesName),
                  ),
                  const SizedBox(height: 14),
                  AppEmptyState(
                    icon: Icons.insights_rounded,
                    title: context.l10n.noTransactionsYet,
                    message: context.l10n.noTransactionsBody,
                    actionLabel: context.l10n.addFirstTransaction,
                    onAction: () =>
                        _openFeature(context, AppRoutes.transactionsName),
                  ),
                  const SizedBox(height: 20),
                  AppSectionHeader(
                    title: context.l10n.quickActions,
                    subtitle: context.l10n.quickActionsSubtitle,
                  ),
                  _QuickActions(
                    onOpen: (route) => _openFeature(context, route),
                  ),
                ],
              ),
            ),
            DashboardLoaded(
              :final summary,
              :final breakdown,
              :final comparison,
              :final recentTransactions,
              :final start,
              :final end,
              :final committed30,
            ) =>
              RefreshIndicator(
                onRefresh: () async {
                  final bloc = context.read<DashboardBloc>();
                  bloc.add(const RefreshData());
                  await Future<void>.delayed(const Duration(milliseconds: 500));
                },
                child: AppContent(
                  padding: EdgeInsets.zero,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    children: [
                      _PeriodPill(
                        start: start,
                        end: end,
                        onTap: () => _pickRange(context),
                      ),
                      const SizedBox(height: 14),
                      ..._responsiveSections(
                        context,
                        summary: [
                          _BalanceHero(summary: summary),
                          const SizedBox(height: 12),
                          const _AccountsOverview(),
                          const SizedBox(height: 14),
                          ReceivablesSummaryCard(
                            onTap: () => _openFeature(
                              context,
                              AppRoutes.receivablesName,
                            ),
                          ),
                          BlocBuilder<DebtBloc, DebtState>(
                            builder: (context, debtState) {
                              final debts = debtState is DebtLoaded
                                  ? debtState.debts
                                  : const <DebtEntity>[];
                              return DebtsSummaryCard(
                                debts: debts,
                                onTap: () =>
                                    _openFeature(context, AppRoutes.debtsName),
                              );
                            },
                          ),
                          BlocBuilder<BudgetBloc, BudgetState>(
                            builder: (context, budgetState) {
                              final progress = budgetState is BudgetLoaded
                                  ? budgetState.progress
                                  : const <BudgetProgress>[];
                              return BudgetAlertsCard(
                                progress: progress,
                                onTap: () => _openFeature(
                                  context,
                                  AppRoutes.budgetsName,
                                ),
                              );
                            },
                          ),
                          BlocBuilder<SavingsBloc, SavingsState>(
                            builder: (context, savingsState) {
                              final goals = savingsState is SavingsLoaded
                                  ? savingsState.goals
                                  : const <SavingsGoalEntity>[];
                              return SavingsSummaryCard(
                                goals: goals,
                                onTap: () => _openFeature(
                                  context,
                                  AppRoutes.savingsName,
                                ),
                              );
                            },
                          ),
                          if (committed30 != null && !committed30.isEmpty)
                            Committed30DaysCard(
                              cashflow: committed30,
                              onTap: () => _openFeature(
                                context,
                                AppRoutes.scheduledPaymentsName,
                              ),
                            ),
                        ],
                        insights: [
                          CategoryPieChart(breakdown: breakdown),
                          MonthlyComparisonChart(comparison: comparison),
                          RecentTransactionsList(
                            transactions: recentTransactions,
                          ),
                          const SizedBox(height: 20),
                          AppSectionHeader(
                            title: context.l10n.quickActions,
                            subtitle: context.l10n.quickActionsSubtitle,
                          ),
                          _QuickActions(
                            onOpen: (route) => _openFeature(context, route),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
          };
        },
      ),
    );
  }
}

class _AccountsOverview extends StatelessWidget {
  const _AccountsOverview();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        final balances = state is WalletLoaded
            ? state.balances
            : const <WalletBalance>[];
        final bank = balances
            .where((balance) => balance.type == WalletType.bank)
            .fold<double>(0, (sum, balance) => sum + balance.balance);
        final cash = balances
            .where((balance) => balance.type == WalletType.cash)
            .fold<double>(0, (sum, balance) => sum + balance.balance);
        final loading = state is WalletInitial || state is WalletLoading;
        final theme = Theme.of(context);

        return Card(
          child: InkWell(
            onTap: () {
              final shell = ShellScope.maybeOf(context);
              if (shell == null || !shell.goToPrimary(AppRoutes.moneyName)) {
                context.goNamed(AppRoutes.moneyName);
              }
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.l10n.accounts,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _AccountBalance(
                          icon: Icons.payments_rounded,
                          label: context.l10n.cash,
                          amount: cash,
                          color: theme.colorScheme.tertiary,
                          loading: loading,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AccountBalance(
                          icon: Icons.credit_card_rounded,
                          label: context.l10n.cardLabel,
                          amount: bank,
                          color: theme.colorScheme.primary,
                          loading: loading,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AccountBalance extends StatelessWidget {
  const _AccountBalance({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
    required this.loading,
  });

  final IconData icon;
  final String label;
  final double amount;
  final Color color;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                if (loading)
                  Text(
                    '—',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  DefaultTextStyle(
                    style:
                        theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ) ??
                        const TextStyle(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: MoneyText(amount),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodPill extends StatelessWidget {
  const _PeriodPill({
    required this.start,
    required this.end,
    required this.onTap,
  });

  final DateTime start;
  final DateTime end;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ActionChip(
        avatar: const Icon(Icons.date_range_outlined, size: 18),
        label: Text('${formatDisplayDate(start)} – ${formatDisplayDate(end)}'),
        onPressed: onTap,
      ),
    );
  }
}

class _BalanceHero extends StatelessWidget {
  const _BalanceHero({required this.summary});

  final DashboardSummaryEntity summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onHero = Colors.white.withValues(alpha: 0.78);
    final valueStyle = theme.textTheme.titleMedium?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w700,
    );

    return BrandGradientCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_rounded,
                color: onHero,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                context.l10n.balance,
                style: theme.textTheme.labelLarge?.copyWith(color: onHero),
              ),
            ],
          ),
          const SizedBox(height: 8),
          MoneyText(
            summary.balance,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: context.l10n.income,
                  value: MoneyText(summary.totalIncome, style: valueStyle),
                  icon: Icons.south_west_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroStat(
                  label: context.l10n.expenses,
                  value: MoneyText(summary.totalExpenses, style: valueStyle),
                  icon: Icons.north_east_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroStat(
                  label: context.l10n.savingsRate,
                  value: Text(
                    '${summary.savingsRate.toStringAsFixed(1)}%',
                    style: valueStyle,
                  ),
                  icon: Icons.savings_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final Widget value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        DefaultTextStyle(
          style: theme.textTheme.titleSmall ?? const TextStyle(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          child: value,
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onOpen});

  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        icon: Icons.swap_vert_rounded,
        label: context.l10n.transactions,
        route: AppRoutes.transactionsName,
        color: AppColors.emerald,
      ),
      (
        icon: Icons.event_repeat_rounded,
        label: context.l10n.scheduledPayments,
        route: AppRoutes.scheduledPaymentsName,
        color: AppColors.warning,
      ),
      (
        icon: Icons.account_balance_wallet_rounded,
        label: context.l10n.money,
        route: AppRoutes.moneyName,
        color: AppColors.teal,
      ),
      (
        icon: Icons.pie_chart_rounded,
        label: context.l10n.budgets,
        route: AppRoutes.budgetsName,
        color: AppColors.sky,
      ),
      (
        icon: Icons.account_balance_rounded,
        label: context.l10n.debts,
        route: AppRoutes.debtsName,
        color: AppColors.danger,
      ),
      (
        icon: Icons.handshake_rounded,
        label: context.l10n.owedToMe,
        route: AppRoutes.receivablesName,
        color: AppColors.teal,
      ),
      (
        icon: Icons.document_scanner_rounded,
        label: context.l10n.scanReceipt,
        route: AppRoutes.ocrName,
        color: AppColors.teal,
      ),
      (
        icon: Icons.auto_awesome_rounded,
        label: context.l10n.aiCoach,
        route: AppRoutes.aiCoachName,
        color: AppColors.sky,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760
            ? 4
            : constraints.maxWidth >= 440
            ? 3
            : 2;
        const spacing = 10.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final action in actions)
              SizedBox(
                key: ValueKey('quick-action-${action.route}'),
                width: width,
                child: _ActionTile(
                  icon: action.icon,
                  label: action.label,
                  color: action.color,
                  onTap: () => onOpen(action.route),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
