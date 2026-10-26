import '../models/wallet_model.dart';

abstract interface class WalletLocalDataSource {
  /// Visible wallets, excluding tombstones.
  Future<List<WalletModel>> getWallets();

  /// Every stored wallet, including tombstones, for sync merges.
  Future<List<WalletModel>> getAllWallets();

  Future<void> saveWallet(WalletModel wallet);

  /// Visible transfers, excluding tombstones.
  Future<List<WalletTransferModel>> getTransfers();

  /// Every stored transfer, including tombstones, for sync merges.
  Future<List<WalletTransferModel>> getAllTransfers();

  Future<void> saveTransfer(WalletTransferModel transfer);

  /// Removes tombstones older than [before] and returns the count.
  Future<int> purgeTombstones(DateTime before);
}
