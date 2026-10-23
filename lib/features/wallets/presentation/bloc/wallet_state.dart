import 'package:equatable/equatable.dart';

import '../../domain/entities/wallet_entity.dart';

sealed class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => const [];
}

final class WalletInitial extends WalletState {
  const WalletInitial();
}

final class WalletLoading extends WalletState {
  const WalletLoading();
}

final class WalletLoaded extends WalletState {
  const WalletLoaded(this.balances);

  final List<WalletBalance> balances;

  double get total => balances.fold(0, (sum, balance) => sum + balance.balance);

  @override
  List<Object?> get props => [balances];
}

final class WalletFailure extends WalletState {
  const WalletFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
