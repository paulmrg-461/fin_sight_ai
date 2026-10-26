import 'package:equatable/equatable.dart';

import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../scheduled_payments/domain/entities/committed_cashflow.dart';
import '../../domain/entities/dashboard_entities.dart';

/// Base state for the dashboard.
sealed class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => const [];
}

final class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

final class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

final class DashboardLoaded extends DashboardState {
  const DashboardLoaded({
    required this.summary,
    required this.breakdown,
    required this.comparison,
    required this.recentTransactions,
    required this.start,
    required this.end,
    this.committed30,
  });

  final DashboardSummaryEntity summary;
  final List<CategoryBreakdown> breakdown;
  final MonthlyComparisonEntity comparison;
  final List<TransactionEntity> recentTransactions;
  final DateTime start;
  final DateTime end;

  /// Outflows committed in the next 30 days, when available.
  final CommittedCashflow? committed30;

  @override
  List<Object?> get props => [
    summary,
    breakdown,
    comparison,
    recentTransactions,
    start,
    end,
    committed30,
  ];
}

final class DashboardEmpty extends DashboardState {
  const DashboardEmpty({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  @override
  List<Object?> get props => [start, end];
}

final class DashboardFailure extends DashboardState {
  const DashboardFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
