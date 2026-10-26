import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../scheduled_payments/domain/entities/committed_cashflow.dart';
import '../../../scheduled_payments/domain/usecases/committed_cashflow_usecase.dart';
import '../../domain/entities/dashboard_entities.dart';
import '../../domain/usecases/dashboard_usecases.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

/// Loads summary, charts, and recent activity for a period.
@injectable
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc(this._getDashboard, this._getCommitted)
    : super(const DashboardInitial()) {
    on<LoadDashboard>(_onLoad);
    on<RefreshData>(_onRefresh);
    on<ChangeDateRange>(_onChangeRange);

    final now = DateTime.now();
    _start = DateTime(now.year, now.month);
    _end = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
  }

  final GetDashboardDataUseCase _getDashboard;
  final GetCommittedCashflowUseCase _getCommitted;

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

    final result = await _getDashboard(params);
    DashboardData? data;
    result.fold(
      (failure) => emit(DashboardFailure(failure.message)),
      (value) => data = value,
    );
    final loaded = data;
    if (loaded == null) {
      return;
    }

    if (loaded.recentTransactions.isEmpty) {
      emit(DashboardEmpty(start: _start, end: _end));
      return;
    }

    final committed = await _projection();
    emit(
      DashboardLoaded(
        summary: loaded.summary,
        breakdown: loaded.breakdown,
        comparison: loaded.comparison,
        recentTransactions: loaded.recentTransactions,
        start: _start,
        end: _end,
        committed30: committed,
      ),
    );
  }

  Future<CommittedCashflow?> _projection() async {
    final from = DateTime.now();
    final result = await _getCommitted(
      CommittedCashflowParams(
        from: DateTime(from.year, from.month, from.day),
        days: 30,
      ),
    );
    return result.getRight().toNullable();
  }
}
