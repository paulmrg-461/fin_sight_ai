import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/currency/presentation/widgets/money_text.dart';
import '../../../../core/l10n/failure_text.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_layout.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../dashboard/domain/entities/dashboard_entities.dart';
import '../../domain/entities/monthly_report.dart';
import '../bloc/reports_bloc.dart';
import '../bloc/reports_event.dart';
import '../bloc/reports_state.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportsTitle),
        actions: [
          BlocBuilder<ReportsBloc, ReportsState>(
            builder: (context, state) {
              final loaded = state is ReportsLoaded;
              return IconButton(
                onPressed: loaded && !state.sharing
                    ? () => context.read<ReportsBloc>().add(
                        const ShareCurrentReport(),
                      )
                    : null,
                tooltip: l10n.shareReport,
                icon: state is ReportsLoaded && state.sharing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.ios_share_rounded),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<ReportsBloc, ReportsState>(
        listener: (context, state) {
          if (state is! ReportsLoaded) {
            return;
          }
          switch (state.shareStatus) {
            case ReportShareStatus.success:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.l10n.reportShared)),
              );
              context.read<ReportsBloc>().add(const DismissReportShare());
            case ReportShareStatus.failure:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    context.failureText(
                      state.shareError ?? context.l10n.reportShareFailed,
                    ),
                  ),
                ),
              );
              context.read<ReportsBloc>().add(const DismissReportShare());
            case ReportShareStatus.none:
              break;
          }
        },
        builder: (context, state) {
          return switch (state) {
            ReportsInitial() || ReportsLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            ReportsFailure(:final message) => AppErrorState(
              message: context.failureText(message),
              onRetry: () =>
                  context.read<ReportsBloc>().add(const LoadReports()),
            ),
            ReportsEmpty(:final month) => AppContent(
              maxWidth: 720,
              child: Column(
                children: [
                  _MonthSelector(month: month),
                  const SizedBox(height: 12),
                  Expanded(
                    child: AppEmptyState(
                      icon: Icons.insert_chart_outlined,
                      title: context.l10n.noReportData,
                      message: context.l10n.noReportDataBody,
                    ),
                  ),
                ],
              ),
            ),
            ReportsLoaded(:final report) => AppContent(
              padding: EdgeInsets.zero,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  _MonthSelector(month: report.month),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.reportsDescription,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  _SummaryCard(report: report),
                  const SizedBox(height: 12),
                  _BreakdownCard(breakdown: report.breakdown),
                ],
              ),
            ),
          };
        },
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({required this.month});

  final DateTime month;

  void _change(BuildContext context, int offset) {
    context.read<ReportsBloc>().add(
      ChangeReportMonth(DateTime(month.year, month.month + offset)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = MaterialLocalizations.of(context)
        .formatMonthYear(DateTime(month.year, month.month));
    return Row(
      children: [
        IconButton(
          onPressed: () => _change(context, -1),
          tooltip: context.l10n.previousMonth,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          onPressed: () => _change(context, 1),
          tooltip: context.l10n.nextMonth,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.report});

  final MonthlyReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final summary = report.summary;
    final comparison = report.comparison;
    final change = comparison.expenseChangePercentage;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.balance,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            MoneyText(
              summary.balance,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _Metric(
                  label: l10n.income,
                  amount: summary.totalIncome,
                  color: AppColors.success,
                ),
                const SizedBox(width: 20),
                _Metric(
                  label: l10n.expenses,
                  amount: summary.totalExpenses,
                  color: AppColors.danger,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}% '
              '${l10n.monthComparison}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: change > 0 ? AppColors.danger : AppColors.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          MoneyText(
            amount,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.breakdown});

  final List<CategoryBreakdown> breakdown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    if (breakdown.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.categoriesTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 10),
            for (final item in breakdown) ...[
              Row(
                children: [
                  Expanded(child: Text(item.category)),
                  Text(
                    '${item.percentage.toStringAsFixed(1)}%',
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(width: 8),
                  MoneyText(
                    item.amount,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (item.percentage / 100).clamp(0, 1),
                  minHeight: 6,
                  semanticsLabel: item.category,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
