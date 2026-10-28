import 'package:equatable/equatable.dart';

import '../../../../core/currency/app_currency.dart';

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

final class ChangeReportYear extends ReportsEvent {
  const ChangeReportYear(this.year);

  final int year;

  @override
  List<Object?> get props => [year];
}

final class ShowMonthlyReport extends ReportsEvent {
  const ShowMonthlyReport();
}

final class ShowAnnualReport extends ReportsEvent {
  const ShowAnnualReport();
}

final class ShareCurrentReport extends ReportsEvent {
  const ShareCurrentReport();
}

final class ShareAnnualReport extends ReportsEvent {
  const ShareAnnualReport(this.currency);

  final AppCurrency currency;

  @override
  List<Object?> get props => [currency];
}

final class DismissReportShare extends ReportsEvent {
  const DismissReportShare();
}
