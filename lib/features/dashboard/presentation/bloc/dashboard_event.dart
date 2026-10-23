import 'package:equatable/equatable.dart';

/// Base event for the dashboard.
sealed class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => const [];
}

/// Loads the dashboard for the current range.
final class LoadDashboard extends DashboardEvent {
  const LoadDashboard();
}

/// Refreshes the current range.
final class RefreshData extends DashboardEvent {
  const RefreshData();
}

/// Changes the selected period and reloads.
final class ChangeDateRange extends DashboardEvent {
  const ChangeDateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  @override
  List<Object?> get props => [start, end];
}
