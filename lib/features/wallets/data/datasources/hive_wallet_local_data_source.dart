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
    final wallets = await getAllWallets();
    return List<WalletModel>.unmodifiable(
      wallets.where((wallet) => !wallet.isDeleted),
    );
  }

  @override
  Future<List<WalletModel>> getAllWallets() async {
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
    final transfers = await getAllTransfers();
    return List<WalletTransferModel>.unmodifiable(
      transfers.where((transfer) => !transfer.isDeleted),
    );
  }

  @override
  Future<List<WalletTransferModel>> getAllTransfers() async {
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

  @override
  Future<int> purgeTombstones(DateTime before) async {
    try {
      var purged = 0;
      purged += await _purgeBox(_walletsBox, WalletModel.fromJson, before);
      purged += await _purgeBox(
        _transfersBox,
        WalletTransferModel.fromJson,
        before,
      );
      return purged;
    } catch (_) {
      throw const CacheException(
        'Unable to purge wallet tombstones.',
        code: 'wallet_purge_failed',
      );
    }
  }

  Future<int> _purgeBox<T>(
    Box<dynamic> box,
    T Function(Map<String, dynamic>) parse,
    DateTime before,
  ) async {
    final keys = <dynamic>[];
    for (final key in box.keys) {
      final value = box.get(key);
      if (value is! Map) {
        continue;
      }
      final model = parse(Map<String, dynamic>.from(value));
      final deletedAt = switch (model) {
        final WalletModel wallet => wallet.deletedAt,
        final WalletTransferModel transfer => transfer.deletedAt,
        _ => null,
      };
      if (deletedAt != null && deletedAt.isBefore(before)) {
        keys.add(key);
      }
    }
    if (keys.isEmpty) {
      return 0;
    }
    await box.deleteAll(keys);
    return keys.length;
  }
}
