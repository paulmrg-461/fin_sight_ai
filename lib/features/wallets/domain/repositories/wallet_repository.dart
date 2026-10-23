import '../../../../core/usecase/usecase.dart';
import '../entities/wallet_entity.dart';

/// Domain contract for account/cash balances and transfers.
abstract interface class WalletRepository {
  /// Ensures the default bank/cash wallets exist and returns their balances.
  ResultFuture<List<WalletBalance>> getWalletBalances();

  /// Reconciles a wallet so its current balance equals [target].
  ResultFuture<WalletBalance> setWalletBalance({
    required String walletId,
    required double target,
  });

  /// Moves money between two wallets (e.g. bank → cash).
  ResultFuture<WalletTransferEntity> transfer({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    required DateTime date,
    String note = '',
  });
}
