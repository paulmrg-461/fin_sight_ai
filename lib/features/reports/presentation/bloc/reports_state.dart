import 'package:equatable/equatable.dart';

import '../../domain/entities/monthly_report.dart';

enum ReportShareStatus { none, success, failure }

sealed class ReportsState extends Equatable {
  const ReportsState();

  @override
  List<Object?> get props => const [];
}

final class ReportsInitial extends ReportsState {
  const ReportsInitial();
}

final class ReportsLoading extends ReportsState {
  const ReportsLoading();
}

final class ReportsLoaded extends ReportsState {
  const ReportsLoaded(
    this.report, {
    this.sharing = false,
    this.shareStatus = ReportShareStatus.none,
    this.shareError,
  });

  final MonthlyReport report;
  final bool sharing;
  final ReportShareStatus shareStatus;
  final String? shareError;

  ReportsLoaded copyWith({
    bool? sharing,
    ReportShareStatus? shareStatus,
    String? shareError,
  }) {
    return ReportsLoaded(
      report,
      sharing: sharing ?? this.sharing,
      shareStatus: shareStatus ?? this.shareStatus,
      shareError: shareError ?? this.shareError,
    );
  }

  @override
  List<Object?> get props => [report, sharing, shareStatus, shareError];
}

final class ReportsEmpty extends ReportsState {
  const ReportsEmpty(this.month);

  final DateTime month;

  @override
  List<Object?> get props => [month];
}

final class ReportsFailure extends ReportsState {
  const ReportsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
