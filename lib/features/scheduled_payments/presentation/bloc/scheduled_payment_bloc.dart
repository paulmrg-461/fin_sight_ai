import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/committed_cashflow.dart';
import '../../domain/entities/scheduled_payment_entity.dart';
import '../../domain/services/schedule_calculator.dart';
import '../../domain/usecases/committed_cashflow_usecase.dart';
import '../../domain/usecases/scheduled_payment_usecases.dart';
import 'scheduled_payment_event.dart';
import 'scheduled_payment_state.dart';

@injectable
class ScheduledPaymentBloc
    extends Bloc<ScheduledPaymentEvent, ScheduledPaymentState> {
  ScheduledPaymentBloc(
    this._getPayments,
    this._addPayment,
    this._setActive,
    this._deletePayment,
    this._payNow,
    this._processDue,
    this._getCommitted,
  ) : super(const ScheduledPaymentInitial()) {
    on<LoadScheduledPayments>(_onLoad);
    on<AddScheduledPayment>(_onAdd);
    on<SetScheduledPaymentActive>(_onSetActive);
    on<DeleteScheduledPayment>(_onDelete);
    on<PayScheduledPayment>(_onPayNow);
    on<ProcessDuePayments>(_onProcess);
  }

  final GetScheduledPaymentsUseCase _getPayments;
  final AddScheduledPaymentUseCase _addPayment;
  final SetScheduledPaymentActiveUseCase _setActive;
  final DeleteScheduledPaymentUseCase _deletePayment;
  final PayScheduledPaymentUseCase _payNow;
  final ProcessDueScheduledPaymentsUseCase _processDue;
  final GetCommittedCashflowUseCase _getCommitted;

  Future<void> _onLoad(
    LoadScheduledPayments event,
    Emitter<ScheduledPaymentState> emit,
  ) async {
    emit(const ScheduledPaymentLoading());
    await _processAndReload(emit, baseAutoCreated: event.previousAutoCreated);
  }

  Future<void> _onAdd(
    AddScheduledPayment event,
    Emitter<ScheduledPaymentState> emit,
  ) async {
    final result = await _addPayment(event.params);
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      await _reload(emit, error: failure.message);
      return;
    }
    await _processAndReload(emit);
  }

  Future<void> _onSetActive(
    SetScheduledPaymentActive event,
    Emitter<ScheduledPaymentState> emit,
  ) async {
    final result = await _setActive(
      SetScheduledPaymentActiveParams(id: event.id, isActive: event.isActive),
    );
    await _handleActionResult(emit, result.fold((f) => f, (_) => null));
  }

  Future<void> _onDelete(
    DeleteScheduledPayment event,
    Emitter<ScheduledPaymentState> emit,
  ) async {
    final result = await _deletePayment(event.id);
    await _handleActionResult(emit, result.fold((f) => f, (_) => null));
  }

  Future<void> _onPayNow(
    PayScheduledPayment event,
    Emitter<ScheduledPaymentState> emit,
  ) async {
    emit(const ScheduledPaymentLoading());
    final result = await _payNow(event.id);
    final failure = result.fold((f) => f, (_) => null);
    if (failure != null) {
      await _reload(emit, error: failure.message);
      return;
    }
    final run = result.getRight().toNullable();
    await _reload(emit, autoCreated: run?.createdCount ?? 0);
  }

  Future<void> _onProcess(
    ProcessDuePayments event,
    Emitter<ScheduledPaymentState> emit,
  ) async {
    emit(const ScheduledPaymentLoading());
    await _processAndReload(emit);
  }

  Future<void> _handleActionResult(
    Emitter<ScheduledPaymentState> emit,
    Failure? failure,
  ) async {
    if (failure != null) {
      await _reload(emit, error: failure.message);
      return;
    }
    await _reload(emit);
  }

  Future<void> _processAndReload(
    Emitter<ScheduledPaymentState> emit, {
    int baseAutoCreated = 0,
  }) async {
    final result = await _processDue(const NoParams());
    final failure = result.fold((f) => f, (_) => null);
    if (failure != null) {
      emit(ScheduledPaymentFailure(failure.message));
      return;
    }
    final run = result.getRight().toNullable();
    await _reload(
      emit,
      autoCreated: baseAutoCreated + (run?.createdCount ?? 0),
    );
  }

  Future<void> _reload(
    Emitter<ScheduledPaymentState> emit, {
    int autoCreated = 0,
    String? error,
  }) async {
    final result = await _getPayments(const NoParams());
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      emit(ScheduledPaymentFailure(failure.message));
      return;
    }

    final payments = result.getOrElse((_) => const <ScheduledPaymentEntity>[]);
    final projection = await _projection();
    if (payments.isEmpty) {
      emit(
        ScheduledPaymentEmpty(
          autoCreated: autoCreated,
          error: error,
          committed30: projection.$1,
          committed90: projection.$2,
        ),
      );
      return;
    }

    emit(
      ScheduledPaymentLoaded(
        payments,
        autoCreated: autoCreated,
        error: error,
        committed30: projection.$1,
        committed90: projection.$2,
      ),
    );
  }

  /// Both windows are projected so the card can switch without another read.
  /// Projection failures are non-fatal: the card simply hides.
  Future<(CommittedCashflow?, CommittedCashflow?)> _projection() async {
    final from = ScheduleCalculator.dateOnly(DateTime.now());
    final thirty = await _getCommitted(
      CommittedCashflowParams(from: from, days: 30),
    );
    final ninety = await _getCommitted(
      CommittedCashflowParams(from: from, days: 90),
    );
    return (thirty.getRight().toNullable(), ninety.getRight().toNullable());
  }
}
