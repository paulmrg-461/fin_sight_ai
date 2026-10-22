import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/debt_entity.dart';
import '../../domain/usecases/add_debt_usecase.dart';
import '../../domain/usecases/calculate_payoff_usecase.dart';
import '../../domain/usecases/delete_debt_usecase.dart';
import '../../domain/usecases/get_debts_usecase.dart';
import '../../domain/usecases/make_payment_usecase.dart';
import 'debt_event.dart';
import 'debt_state.dart';

/// Coordinates debt use cases and exposes a single UI state.
@injectable
class DebtBloc extends Bloc<DebtEvent, DebtState> {
  DebtBloc(
    this._getDebts,
    this._addDebt,
    this._makePayment,
    this._deleteDebt,
    this._calculatePayoff,
  ) : super(const DebtInitial()) {
    on<LoadDebts>(_onLoad);
    on<AddDebt>(_onAdd);
    on<MakePayment>(_onMakePayment);
    on<DeleteDebt>(_onDelete);
    on<CalculatePayoff>(_onCalculatePayoff);
  }

  final GetDebtsUseCase _getDebts;
  final AddDebtUseCase _addDebt;
  final MakePaymentUseCase _makePayment;
  final DeleteDebtUseCase _deleteDebt;
  final CalculatePayoffUseCase _calculatePayoff;

  Future<void> _onLoad(LoadDebts event, Emitter<DebtState> emit) =>
      _reload(emit);

  Future<void> _onAdd(AddDebt event, Emitter<DebtState> emit) async {
    emit(const DebtLoading());
    final result = await _addDebt(
      AddDebtParams(
        creditorName: event.creditorName,
        totalAmount: event.totalAmount,
        remainingAmount: event.remainingAmount ?? event.totalAmount,
        interestRate: event.interestRate,
        minimumPayment: event.minimumPayment,
        dueDate: event.dueDate,
      ),
    );
    if (result.isLeft()) {
      emit(DebtFailure(_messageOf(result)));
      return;
    }
    await _reload(emit);
  }

  Future<void> _onMakePayment(
    MakePayment event,
    Emitter<DebtState> emit,
  ) async {
    emit(const DebtLoading());
    final result = await _makePayment(
      MakePaymentParams(debtId: event.debtId, amount: event.amount),
    );
    if (result.isLeft()) {
      emit(DebtFailure(_messageOf(result)));
      return;
    }
    await _reload(emit);
  }

  Future<void> _onDelete(DeleteDebt event, Emitter<DebtState> emit) async {
    emit(const DebtLoading());
    final result = await _deleteDebt(event.id);
    if (result.isLeft()) {
      emit(DebtFailure(_messageOf(result)));
      return;
    }
    await _reload(emit);
  }

  Future<void> _onCalculatePayoff(
    CalculatePayoff event,
    Emitter<DebtState> emit,
  ) async {
    final current = state;
    if (current is! DebtLoaded) {
      return;
    }

    DebtEntity? debt;
    for (final candidate in current.debts) {
      if (candidate.id == event.debtId) {
        debt = candidate;
        break;
      }
    }
    if (debt == null) {
      return;
    }

    final result = await _calculatePayoff(
      CalculatePayoffParams(debt: debt, monthlyPayment: event.monthlyPayment),
    );
    if (result.isLeft()) {
      emit(DebtFailure(_messageOf(result)));
      return;
    }

    emit(
      DebtLoaded(
        debts: current.debts,
        payoff: PayoffEstimate(
          debtId: debt.id,
          monthlyPayment: event.monthlyPayment,
          expectedDate: result.getOrElse((_) => null),
        ),
      ),
    );
  }

  Future<void> _reload(Emitter<DebtState> emit) async {
    emit(const DebtLoading());
    final result = await _getDebts(const NoParams());
    result.fold(
      (failure) => emit(DebtFailure(failure.message)),
      (debts) =>
          emit(debts.isEmpty ? const DebtEmpty() : DebtLoaded(debts: debts)),
    );
  }

  String _messageOf(Either<Failure, dynamic> result) {
    final failure = result.getLeft().toNullable();
    return failure?.message ?? 'Something went wrong.';
  }
}
