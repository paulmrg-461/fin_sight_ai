import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../dashboard/domain/services/dashboard_calculator.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/domain/services/transaction_csv.dart';
import '../../../transactions/domain/usecases/get_transactions_by_date_range_usecase.dart';
import '../../data/services/annual_report_pdf_builder.dart';
import '../../domain/entities/annual_report.dart';
import '../../domain/entities/monthly_report.dart';
import '../../domain/repositories/report_exporter.dart';
import 'reports_event.dart';
import 'reports_state.dart';

@injectable
class ReportsBloc extends Bloc<ReportsEvent, ReportsState> {
  ReportsBloc(this._getByRange, this._exporter)
    : super(const ReportsInitial()) {
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _year = now.year;
    on<LoadReports>(_onLoad);
    on<ChangeReportMonth>(_onChangeMonth);
    on<ChangeReportYear>(_onChangeYear);
    on<ShowMonthlyReport>(_onShowMonthly);
    on<ShowAnnualReport>(_onShowAnnual);
    on<ShareCurrentReport>(_onShare);
    on<ShareAnnualReport>(_onShareAnnual);
    on<DismissReportShare>(_onDismissShare);
  }

  final GetTransactionsByDateRangeUseCase _getByRange;
  final ReportExporter _exporter;
  final AnnualReportPdfBuilder _pdfBuilder = AnnualReportPdfBuilder();

  late DateTime _month;
  late int _year;
  bool _annual = false;

  Future<void> _onLoad(LoadReports event, Emitter<ReportsState> emit) =>
      _reload(emit);

  Future<void> _onChangeMonth(
    ChangeReportMonth event,
    Emitter<ReportsState> emit,
  ) async {
    _annual = false;
    _month = DateTime(event.month.year, event.month.month);
    await _reload(emit);
  }

  Future<void> _onChangeYear(
    ChangeReportYear event,
    Emitter<ReportsState> emit,
  ) async {
    _annual = true;
    _year = event.year;
    await _reload(emit);
  }

  Future<void> _onShowMonthly(
    ShowMonthlyReport event,
    Emitter<ReportsState> emit,
  ) async {
    _annual = false;
    await _reload(emit);
  }

  Future<void> _onShowAnnual(
    ShowAnnualReport event,
    Emitter<ReportsState> emit,
  ) async {
    _annual = true;
    await _reload(emit);
  }

  Future<void> _reload(Emitter<ReportsState> emit) async {
    if (_annual) {
      await _reloadAnnual(emit);
      return;
    }
    emit(const ReportsLoading());
    final current = await _fetch(_month);
    final failure = current.getLeft().toNullable();
    if (failure != null) {
      emit(ReportsFailure(failure.message));
      return;
    }
    final transactions = current.getOrElse((_) => const []);
    if (transactions.isEmpty) {
      emit(ReportsEmpty(_month));
      return;
    }

    final previousMonth = DateTime(_month.year, _month.month - 1);
    final previous = await _fetch(previousMonth);
    final previousTransactions = previous.getOrElse((_) => const []);

    emit(
      ReportsLoaded(
        MonthlyReport(
          month: _month,
          transactions: transactions,
          summary: DashboardCalculator.summary(
            current: transactions,
            previous: previousTransactions,
          ),
          breakdown: DashboardCalculator.categoryBreakdown(transactions),
          comparison: DashboardCalculator.monthlyComparison(
            current: transactions,
            previous: previousTransactions,
          ),
        ),
      ),
    );
  }

  Future<void> _reloadAnnual(Emitter<ReportsState> emit) async {
    emit(const ReportsLoading());
    final result = await _getByRange(
      DateRangeParams(
        start: DateTime(_year),
        end: DateTime(_year, 12, 31, 23, 59, 59, 999),
      ),
    );
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      emit(ReportsFailure(failure.message));
      return;
    }
    final transactions = result.getOrElse((_) => const []);
    if (transactions.isEmpty) {
      emit(ReportsAnnualEmpty(_year));
      return;
    }
    emit(
      ReportsAnnualLoaded(
        AnnualReport.fromTransactions(year: _year, transactions: transactions),
      ),
    );
  }

  Future<void> _onShareAnnual(
    ShareAnnualReport event,
    Emitter<ReportsState> emit,
  ) async {
    final current = state;
    if (current is! ReportsAnnualLoaded || current.sharing) {
      return;
    }
    emit(current.copyWith(sharing: true, shareStatus: ReportShareStatus.none));
    final bytes = await _pdfBuilder.build(
      current.report,
      currency: event.currency,
      title: 'FinSight AI - ${current.report.year}',
    );
    final result = await _exporter.sharePdf(
      fileName: 'finsight-${current.report.year}.pdf',
      bytes: bytes,
      subject: 'FinSight AI annual report',
    );
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      emit(
        current.copyWith(
          sharing: false,
          shareStatus: ReportShareStatus.failure,
          shareError: failure.message,
        ),
      );
      return;
    }
    emit(
      current.copyWith(sharing: false, shareStatus: ReportShareStatus.success),
    );
  }

  Future<Result<List<TransactionEntity>>> _fetch(DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59, 999);
    return _getByRange(DateRangeParams(start: start, end: end));
  }

  Future<void> _onShare(
    ShareCurrentReport event,
    Emitter<ReportsState> emit,
  ) async {
    final current = state;
    if (current is! ReportsLoaded || current.sharing) {
      return;
    }
    emit(current.copyWith(sharing: true, shareStatus: ReportShareStatus.none));
    final csv = TransactionCsv.build(current.report.transactions);
    final fileName =
        'finsight-${current.report.month.year}-${current.report.month.month.toString().padLeft(2, '0')}.csv';
    final result = await _exporter.shareCsv(
      fileName: fileName,
      csv: csv,
      subject: 'FinSight AI report',
    );
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      emit(
        current.copyWith(
          sharing: false,
          shareStatus: ReportShareStatus.failure,
          shareError: failure.message,
        ),
      );
      return;
    }
    emit(
      current.copyWith(sharing: false, shareStatus: ReportShareStatus.success),
    );
  }

  Future<void> _onDismissShare(
    DismissReportShare event,
    Emitter<ReportsState> emit,
  ) async {
    final current = state;
    if (current is ReportsLoaded) {
      emit(
        current.copyWith(shareStatus: ReportShareStatus.none, shareError: ''),
      );
    } else if (current is ReportsAnnualLoaded) {
      emit(
        current.copyWith(shareStatus: ReportShareStatus.none, shareError: ''),
      );
    }
  }
}
