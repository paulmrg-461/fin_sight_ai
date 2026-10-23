import '../models/wallet_model.dart';

abstract interface class WalletLocalDataSource {
  Future<List<WalletModel>> getWallets();

  Future<void> saveWallet(WalletModel wallet);

  Future<List<WalletTransferModel>> getTransfers();

  Future<void> saveTransfer(WalletTransferModel transfer);
}
