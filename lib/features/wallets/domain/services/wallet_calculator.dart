import '../../../transactions/domain/entities/transaction_entity.dart';
import '../entities/wallet_entity.dart';

/// Computes per-wallet balances from transactions and transfers.
abstract final class WalletCalculator {
  static List<WalletBalance> balances({
    required List<WalletEntity> wallets,
    required List<TransactionEntity> transactions,
    required List<WalletTransferEntity> transfers,
  }) {
    if (wallets.isEmpty) {
      return const [];
    }

    final defaultWallet = wallets.firstWhere(
      (wallet) => wallet.type == WalletType.bank,
      orElse: () => wallets.first,
    );
    final walletIds = wallets.map((wallet) => wallet.id).toSet();

    return List<WalletBalance>.unmodifiable(
      wallets.map((wallet) {
        var movements = 0.0;

        for (final transaction in transactions) {
          final walletId = transaction.walletId ?? defaultWallet.id;
          if (walletId != wallet.id) {
            continue;
          }
          movements += transaction.isIncome
              ? transaction.amount
              : -transaction.amount;
        }

        for (final transfer in transfers) {
          if (!walletIds.contains(transfer.fromWalletId) ||
              !walletIds.contains(transfer.toWalletId)) {
            continue;
          }
          if (transfer.fromWalletId == wallet.id) {
            movements -= transfer.amount;
          }
          if (transfer.toWalletId == wallet.id) {
            movements += transfer.amount;
          }
        }

        return WalletBalance(
          wallet: wallet,
          balance: _round(wallet.openingBalance + movements),
        );
      }),
    );
  }

  static double _round(double value) => double.parse(value.toStringAsFixed(2));
}
