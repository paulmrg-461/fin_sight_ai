import 'package:equatable/equatable.dart';

import '../../domain/entities/annual_report.dart';
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

final class ReportsAnnualLoaded extends ReportsState {
  const ReportsAnnualLoaded(
    this.report, {
    this.sharing = false,
    this.shareStatus = ReportShareStatus.none,
    this.shareError,
  });

  final AnnualReport report;
  final bool sharing;
  final ReportShareStatus shareStatus;
  final String? shareError;

  ReportsAnnualLoaded copyWith({
    bool? sharing,
    ReportShareStatus? shareStatus,
    String? shareError,
  }) {
    return ReportsAnnualLoaded(
      report,
      sharing: sharing ?? this.sharing,
      shareStatus: shareStatus ?? this.shareStatus,
      shareError: shareError ?? this.shareError,
    );
  }

  @override
  List<Object?> get props => [report, sharing, shareStatus, shareError];
}

final class ReportsAnnualEmpty extends ReportsState {
  const ReportsAnnualEmpty(this.year);

  final int year;

  @override
  List<Object?> get props => [year];
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
