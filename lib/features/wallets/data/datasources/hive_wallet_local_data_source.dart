import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/wallet_model.dart';
import 'wallet_local_data_source.dart';

class HiveWalletLocalDataSource implements WalletLocalDataSource {
  const HiveWalletLocalDataSource(this._walletsBox, this._transfersBox);

  final Box<dynamic> _walletsBox;
  final Box<dynamic> _transfersBox;

  @override
  Future<List<WalletModel>> getWallets() async {
    try {
      final wallets = <WalletModel>[];
      for (final value in _walletsBox.values) {
        if (value is! Map) {
          throw const FormatException('Invalid wallet entry.');
        }
        wallets.add(WalletModel.fromJson(Map<String, dynamic>.from(value)));
      }
      wallets.sort((a, b) {
        final typeOrder = a.type.index.compareTo(b.type.index);
        return typeOrder != 0 ? typeOrder : a.name.compareTo(b.name);
      });
      return List<WalletModel>.unmodifiable(wallets);
    } catch (_) {
      throw const CacheException(
        'Unable to read wallets from local storage.',
        code: 'wallet_read_failed',
      );
    }
  }

  @override
  Future<void> saveWallet(WalletModel wallet) async {
    try {
      await _walletsBox.put(wallet.id, wallet.toJson());
    } catch (_) {
      throw const CacheException(
        'Unable to save the wallet locally.',
        code: 'wallet_write_failed',
      );
    }
  }

  @override
  Future<List<WalletTransferModel>> getTransfers() async {
    try {
      final transfers = <WalletTransferModel>[];
      for (final value in _transfersBox.values) {
        if (value is! Map) {
          throw const FormatException('Invalid transfer entry.');
        }
        transfers.add(
          WalletTransferModel.fromJson(Map<String, dynamic>.from(value)),
        );
      }
      transfers.sort((a, b) => b.date.compareTo(a.date));
      return List<WalletTransferModel>.unmodifiable(transfers);
    } catch (_) {
      throw const CacheException(
        'Unable to read transfers from local storage.',
        code: 'transfer_read_failed',
      );
    }
  }

  @override
  Future<void> saveTransfer(WalletTransferModel transfer) async {
    try {
      await _transfersBox.put(transfer.id, transfer.toJson());
    } catch (_) {
      throw const CacheException(
        'Unable to save the transfer locally.',
        code: 'transfer_write_failed',
      );
    }
  }
}
