import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/wallet_usecases.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

@injectable
class WalletBloc extends Bloc<WalletEvent, WalletState> {
  WalletBloc(this._getBalances, this._setBalance, this._transfer)
    : super(const WalletInitial()) {
    on<LoadWallets>(_onLoad);
    on<SetBalance>(_onSetBalance);
    on<TransferMoney>(_onTransfer);
  }

  final GetWalletBalancesUseCase _getBalances;
  final SetWalletBalanceUseCase _setBalance;
  final TransferBetweenWalletsUseCase _transfer;

  Future<void> _onLoad(LoadWallets event, Emitter<WalletState> emit) =>
      _reload(emit);

  Future<void> _onSetBalance(
    SetBalance event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WalletLoading());
    final result = await _setBalance(
      SetWalletBalanceParams(walletId: event.walletId, target: event.target),
    );
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      emit(WalletFailure(failure.message));
      return;
    }
    await _reload(emit);
  }

  Future<void> _onTransfer(
    TransferMoney event,
    Emitter<WalletState> emit,
  ) async {
    emit(const WalletLoading());
    final result = await _transfer(
      TransferBetweenWalletsParams(
        fromWalletId: event.fromWalletId,
        toWalletId: event.toWalletId,
        amount: event.amount,
        date: DateTime.now(),
        note: event.note,
      ),
    );
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      emit(WalletFailure(failure.message));
      return;
    }
    await _reload(emit);
  }

  Future<void> _reload(Emitter<WalletState> emit) async {
    emit(const WalletLoading());
    final result = await _getBalances(const NoParams());
    result.fold(
      (failure) => emit(WalletFailure(failure.message)),
      (balances) => emit(WalletLoaded(balances)),
    );
  }
}
