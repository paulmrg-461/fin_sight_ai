import 'package:equatable/equatable.dart';

sealed class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object?> get props => const [];
}

final class LoadWallets extends WalletEvent {
  const LoadWallets();
}

final class SetBalance extends WalletEvent {
  const SetBalance({required this.walletId, required this.target});

  final String walletId;
  final double target;

  @override
  List<Object?> get props => [walletId, target];
}

final class TransferMoney extends WalletEvent {
  const TransferMoney({
    required this.fromWalletId,
    required this.toWalletId,
    required this.amount,
    this.note = '',
  });

  final String fromWalletId;
  final String toWalletId;
  final double amount;
  final String note;

  @override
  List<Object?> get props => [fromWalletId, toWalletId, amount, note];
}
