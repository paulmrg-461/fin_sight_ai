import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/add_receivable_usecase.dart';
import '../../domain/usecases/delete_receivable_usecase.dart';
import '../../domain/usecases/get_receivables_usecase.dart';
import '../../domain/usecases/make_receivable_payment_usecase.dart';
import '../../domain/usecases/update_receivable_usecase.dart';
import 'receivable_event.dart';
import 'receivable_state.dart';

/// Coordinates receivable use cases and exposes a single UI state.
@injectable
class ReceivableBloc extends Bloc<ReceivableEvent, ReceivableState> {
  ReceivableBloc(
    this._getReceivables,
    this._addReceivable,
    this._updateReceivable,
    this._makePayment,
    this._deleteReceivable,
  ) : super(const ReceivableInitial()) {
    on<LoadReceivables>(_onLoad);
    on<AddReceivable>(_onAdd);
    on<UpdateReceivable>(_onUpdate);
    on<RecordReceivablePayment>(_onPayment);
    on<DeleteReceivable>(_onDelete);
  }

  final GetReceivablesUseCase _getReceivables;
  final AddReceivableUseCase _addReceivable;
  final UpdateReceivableUseCase _updateReceivable;
  final MakeReceivablePaymentUseCase _makePayment;
  final DeleteReceivableUseCase _deleteReceivable;

  Future<void> _onLoad(LoadReceivables event, Emitter<ReceivableState> emit) =>
      _reload(emit);

  Future<void> _onAdd(
    AddReceivable event,
    Emitter<ReceivableState> emit,
  ) async {
    emit(const ReceivableLoading());
    final result = await _addReceivable(
      AddReceivableParams(
        debtorName: event.debtorName,
        totalAmount: event.totalAmount,
        dateLent: event.dateLent,
        dueDate: event.dueDate,
        notes: event.notes,
      ),
    );
    if (result.isLeft()) {
      emit(ReceivableFailure(_messageOf(result)));
      return;
    }
    await _reload(emit);
  }

  Future<void> _onUpdate(
    UpdateReceivable event,
    Emitter<ReceivableState> emit,
  ) async {
    emit(const ReceivableLoading());
    final result = await _updateReceivable(
      UpdateReceivableParams(
        id: event.id,
        debtorName: event.debtorName,
        totalAmount: event.totalAmount,
        dateLent: event.dateLent,
        dueDate: event.dueDate,
        notes: event.notes,
      ),
    );
    if (result.isLeft()) {
      emit(ReceivableFailure(_messageOf(result)));
      return;
    }
    await _reload(emit);
  }

  Future<void> _onPayment(
    RecordReceivablePayment event,
    Emitter<ReceivableState> emit,
  ) async {
    emit(const ReceivableLoading());
    final result = await _makePayment(
      MakeReceivablePaymentParams(
        receivableId: event.receivableId,
        amount: event.amount,
        note: event.note,
      ),
    );
    if (result.isLeft()) {
      emit(ReceivableFailure(_messageOf(result)));
      return;
    }
    await _reload(emit);
  }

  Future<void> _onDelete(
    DeleteReceivable event,
    Emitter<ReceivableState> emit,
  ) async {
    emit(const ReceivableLoading());
    final result = await _deleteReceivable(event.id);
    if (result.isLeft()) {
      emit(ReceivableFailure(_messageOf(result)));
      return;
    }
    await _reload(emit);
  }

  Future<void> _reload(Emitter<ReceivableState> emit) async {
    emit(const ReceivableLoading());
    final result = await _getReceivables(const NoParams());
    result.fold(
      (failure) => emit(ReceivableFailure(failure.message)),
      (receivables) => emit(
        receivables.isEmpty
            ? const ReceivableEmpty()
            : ReceivableLoaded(receivables: receivables),
      ),
    );
  }

  String _messageOf(Either<Failure, dynamic> result) {
    final failure = result.getLeft().toNullable();
    return failure?.message ?? 'Something went wrong.';
  }
}
