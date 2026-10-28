import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/currency/app_currency.dart';
import '../../../../core/currency/presentation/bloc/currency_bloc.dart';
import '../../../../core/currency/presentation/bloc/currency_state.dart';
import '../../../../core/currency/presentation/widgets/money_text.dart';
import '../../../../core/l10n/failure_text.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_layout.dart';
import '../../../../core/widgets/app_states.dart';
import '../../../dashboard/domain/entities/dashboard_entities.dart';
import '../../domain/entities/annual_report.dart';
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
              final loaded =
                  state is ReportsLoaded || state is ReportsAnnualLoaded;
              final sharing = switch (state) {
                ReportsLoaded(:final sharing) => sharing,
                ReportsAnnualLoaded(:final sharing) => sharing,
                _ => false,
              };
              return IconButton(
                onPressed: loaded && !sharing
                    ? () {
                        final bloc = context.read<ReportsBloc>();
                        if (state is ReportsLoaded) {
                          bloc.add(const ShareCurrentReport());
                          return;
                        }
                        final currencyState = context
                            .read<CurrencyBloc>()
                            .state;
                        bloc.add(
                          ShareAnnualReport(
                            currencyState is CurrencyLoaded
                                ? currencyState.currency
                                : AppCurrency.cop,
                          ),
                        );
                      }
                    : null,
                tooltip: state is ReportsAnnualLoaded
                    ? l10n.shareAnnualReport
                    : l10n.shareReport,
                icon: sharing
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
          final status = switch (state) {
            ReportsLoaded(:final shareStatus) => shareStatus,
            ReportsAnnualLoaded(:final shareStatus) => shareStatus,
            _ => ReportShareStatus.none,
          };
          if (status == ReportShareStatus.none) {
            return;
          }
          final error = switch (state) {
            ReportsLoaded(:final shareError) => shareError,
            ReportsAnnualLoaded(:final shareError) => shareError,
            _ => null,
          };
          switch (status) {
            case ReportShareStatus.success:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state is ReportsAnnualLoaded
                        ? context.l10n.annualReportShared
                        : context.l10n.reportShared,
                  ),
                ),
              );
              context.read<ReportsBloc>().add(const DismissReportShare());
            case ReportShareStatus.failure:
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    context.failureText(
                      error ?? context.l10n.reportShareFailed,
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
                  const _ReportModeSwitch(annual: false),
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
                  const _ReportModeSwitch(annual: false),
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
            ReportsAnnualEmpty(:final year) => AppContent(
              maxWidth: 720,
              child: Column(
                children: [
                  const _ReportModeSwitch(annual: true),
                  _YearSelector(year: year),
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
            ReportsAnnualLoaded(:final report) => AppContent(
              padding: EdgeInsets.zero,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  const _ReportModeSwitch(annual: true),
                  _YearSelector(year: report.year),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.annualReportDescription,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  _AnnualSummaryCard(report: report),
                  const SizedBox(height: 12),
                  _AnnualMonthsCard(report: report),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: MoneyText(
              amount,
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
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

class _ReportModeSwitch extends StatelessWidget {
  const _ReportModeSwitch({required this.annual});

  final bool annual;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SegmentedButton<bool>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: false,
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(l10n.monthlyReport),
          ),
          ButtonSegment(
            value: true,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(l10n.annualReport),
          ),
        ],
        selected: {annual},
        onSelectionChanged: (selection) {
          context.read<ReportsBloc>().add(
            selection.first
                ? const ShowAnnualReport()
                : const ShowMonthlyReport(),
          );
        },
      ),
    );
  }
}

class _YearSelector extends StatelessWidget {
  const _YearSelector({required this.year});

  final int year;

  void _change(BuildContext context, int offset) {
    context.read<ReportsBloc>().add(ChangeReportYear(year + offset));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => _change(context, -1),
          tooltip: MaterialLocalizations.of(context).previousPageTooltip,
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          '$year',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        IconButton(
          onPressed: () => _change(context, 1),
          tooltip: MaterialLocalizations.of(context).nextPageTooltip,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _AnnualSummaryCard extends StatelessWidget {
  const _AnnualSummaryCard({required this.report});

  final AnnualReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.annualReport} ${report.year}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _Metric(
                  label: l10n.income,
                  amount: report.summary.totalIncome,
                  color: AppColors.success,
                ),
                const SizedBox(width: 12),
                _Metric(
                  label: l10n.expenses,
                  amount: report.summary.totalExpenses,
                  color: AppColors.danger,
                ),
                const SizedBox(width: 12),
                _Metric(
                  label: l10n.balance,
                  amount: report.summary.balance,
                  color: report.summary.balance < 0
                      ? AppColors.danger
                      : AppColors.success,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnualMonthsCard extends StatelessWidget {
  const _AnnualMonthsCard({required this.report});

  final AnnualReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final formatMonth = MaterialLocalizations.of(context).formatMonthYear;
    final months = report.months.where((month) => !month.isEmpty).toList();
    var maxFlow = 0.0;
    for (final month in report.months) {
      if (month.income > maxFlow) {
        maxFlow = month.income;
      }
      if (month.expenses > maxFlow) {
        maxFlow = month.expenses;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.monthlyBreakdown, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            for (final month in months)
              _AnnualMonthRow(
                month: month,
                label: formatMonth(month.month),
                maxFlow: maxFlow,
              ),
          ],
        ),
      ),
    );
  }
}

class _AnnualMonthRow extends StatelessWidget {
  const _AnnualMonthRow({
    required this.month,
    required this.label,
    required this.maxFlow,
  });

  final AnnualMonthSummary month;
  final String label;
  final double maxFlow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final positive = month.balance >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 96,
                child: Text(
                  label,
                  maxLines: 2,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 2,
                  children: [
                    _FlowLabel(
                      label: l10n.income,
                      amount: month.income,
                      color: AppColors.emerald,
                    ),
                    _FlowLabel(
                      label: l10n.expenses,
                      amount: month.expenses,
                      color: AppColors.danger,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: MoneyText(
                    month.balance,
                    signed: true,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: positive ? AppColors.emerald : AppColors.danger,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: _FlowBar(
                  value: maxFlow <= 0 ? 0 : month.income / maxFlow,
                  color: AppColors.emerald,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _FlowBar(
                  value: maxFlow <= 0 ? 0 : month.expenses / maxFlow,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlowLabel extends StatelessWidget {
  const _FlowLabel({
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label ',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        MoneyText(amount, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

class _FlowBar extends StatelessWidget {
  const _FlowBar({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 5,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
