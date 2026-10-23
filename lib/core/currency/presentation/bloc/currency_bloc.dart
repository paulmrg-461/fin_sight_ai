import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../usecase/usecase.dart';
import '../../app_currency.dart';
import '../../currency_usecases.dart';
import 'currency_event.dart';
import 'currency_state.dart';

@injectable
class CurrencyBloc extends Bloc<CurrencyEvent, CurrencyState> {
  CurrencyBloc(this._getCurrency, this._setCurrency)
    : super(const CurrencyInitial()) {
    on<LoadCurrency>(_onLoad);
    on<ChangeCurrency>(_onChange);
  }

  final GetCurrencyUseCase _getCurrency;
  final SetCurrencyUseCase _setCurrency;

  Future<void> _onLoad(LoadCurrency event, Emitter<CurrencyState> emit) async {
    final result = await _getCurrency(const NoParams());
    result.fold(
      (failure) => emit(CurrencyFailure(failure.message)),
      (currency) => emit(CurrencyLoaded(currency)),
    );
  }

  Future<void> _onChange(
    ChangeCurrency event,
    Emitter<CurrencyState> emit,
  ) async {
    final result = await _setCurrency(event.currency);
    result.fold(
      (failure) => emit(CurrencyFailure(failure.message)),
      (currency) => emit(CurrencyLoaded(currency)),
    );
  }

  AppCurrency get currency {
    final current = state;
    return current is CurrencyLoaded ? current.currency : AppCurrency.cop;
  }
}
