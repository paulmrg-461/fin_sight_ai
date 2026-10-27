import 'package:equatable/equatable.dart';

sealed class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object?> get props => const [];
}

final class LoadReports extends ReportsEvent {
  const LoadReports();
}

final class ChangeReportMonth extends ReportsEvent {
  const ChangeReportMonth(this.month);

  final DateTime month;

  @override
  List<Object?> get props => [month];
}

final class ShareCurrentReport extends ReportsEvent {
  const ShareCurrentReport();
}

final class DismissReportShare extends ReportsEvent {
  const DismissReportShare();
}
