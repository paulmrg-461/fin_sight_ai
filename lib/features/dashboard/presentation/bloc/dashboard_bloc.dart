import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/domain/usecases/get_transactions_by_date_range_usecase.dart';
import '../../domain/entities/dashboard_entities.dart';
import '../../domain/usecases/dashboard_usecases.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

/// Loads summary, charts, and recent activity for a period.
@injectable
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc(
    this._getSummary,
    this._getBreakdown,
    this._getComparison,
    this._getTransactionsByRange,
  ) : super(const DashboardInitial()) {
    on<LoadDashboard>(_onLoad);
    on<RefreshData>(_onRefresh);
    on<ChangeDateRange>(_onChangeRange);

    final now = DateTime.now();
    _start = DateTime(now.year, now.month);
    _end = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
  }

  final GetDashboardSummaryUseCase _getSummary;
  final GetCategoryBreakdownUseCase _getBreakdown;
  final GetMonthlyComparisonUseCase _getComparison;
  final GetTransactionsByDateRangeUseCase _getTransactionsByRange;

  late DateTime _start;
  late DateTime _end;

  Future<void> _onLoad(LoadDashboard event, Emitter<DashboardState> emit) =>
      _reload(emit);

  Future<void> _onRefresh(RefreshData event, Emitter<DashboardState> emit) =>
      _reload(emit);

  Future<void> _onChangeRange(
    ChangeDateRange event,
    Emitter<DashboardState> emit,
  ) async {
    if (event.start.isAfter(event.end)) {
      emit(
        const DashboardFailure('The start date must be before the end date.'),
      );
      return;
    }
    _start = event.start;
    _end = event.end;
    await _reload(emit);
  }

  Future<void> _reload(Emitter<DashboardState> emit) async {
    emit(const DashboardLoading());
    final params = DashboardRangeParams(start: _start, end: _end);

    final summary = await _getSummary(params);
    final failure = summary.getLeft().toNullable();
    if (failure != null) {
      emit(DashboardFailure(failure.message));
      return;
    }

    final breakdown = await _getBreakdown(params);
    final breakdownFailure = breakdown.getLeft().toNullable();
    if (breakdownFailure != null) {
      emit(DashboardFailure(breakdownFailure.message));
      return;
    }

    final comparison = await _getComparison(params);
    final comparisonFailure = comparison.getLeft().toNullable();
    if (comparisonFailure != null) {
      emit(DashboardFailure(comparisonFailure.message));
      return;
    }

    final transactions = await _getTransactionsByRange(
      DateRangeParams(start: _start, end: _end),
    );
    final transactionsFailure = transactions.getLeft().toNullable();
    if (transactionsFailure != null) {
      emit(DashboardFailure(transactionsFailure.message));
      return;
    }

    final current = transactions.getOrElse((_) => const <TransactionEntity>[]);
    if (current.isEmpty) {
      emit(DashboardEmpty(start: _start, end: _end));
      return;
    }

    emit(
      DashboardLoaded(
        summary: summary.getOrElse((_) => DashboardCalculatorFallback.summary),
        breakdown: breakdown.getOrElse((_) => const <CategoryBreakdown>[]),
        comparison: comparison.getOrElse(
          (_) => DashboardCalculatorFallback.comparison,
        ),
        recentTransactions: List<TransactionEntity>.unmodifiable(
          current.take(5),
        ),
        start: _start,
        end: _end,
      ),
    );
  }
}

/// Unreachable placeholders kept explicit instead of using `!`.
abstract final class DashboardCalculatorFallback {
  static const DashboardSummaryEntity summary = DashboardSummaryEntity(
    totalIncome: 0,
    totalExpenses: 0,
    balance: 0,
    savingsRate: 0,
    monthOverMonthChange: 0,
  );

  static const MonthlyComparisonEntity comparison = MonthlyComparisonEntity(
    currentIncome: 0,
    currentExpenses: 0,
    previousIncome: 0,
    previousExpenses: 0,
    expenseChangePercentage: 0,
  );
}
