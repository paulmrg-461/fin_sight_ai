import 'dart:io';

import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/features/wallets/data/datasources/hive_wallet_local_data_source.dart';
import 'package:fin_sight_ai/features/wallets/data/models/wallet_model.dart';
import 'package:fin_sight_ai/features/wallets/domain/entities/wallet_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

void main() {
  late Directory tempDirectory;
  late Box<dynamic> walletsBox;
  late Box<dynamic> transfersBox;
  late HiveWalletLocalDataSource dataSource;
  var counter = 0;

  setUpAll(() async {
    tempDirectory = await Directory.systemTemp.createTemp('finsight_wallets_');
    Hive.init(tempDirectory.path);
  });

  setUp(() async {
    counter++;
    walletsBox = await Hive.openBox<dynamic>('wallets_$counter');
    transfersBox = await Hive.openBox<dynamic>('transfers_$counter');
    dataSource = HiveWalletLocalDataSource(walletsBox, transfersBox);
  });

  tearDown(() async {
    await walletsBox.close();
    await transfersBox.close();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDirectory.delete(recursive: true);
  });

  test('saves wallets and sorts bank before cash', () async {
    await dataSource.saveWallet(
      const WalletModel(
        id: 'cash',
        name: 'Efectivo',
        type: WalletType.cash,
        openingBalance: 0,
      ),
    );
    await dataSource.saveWallet(
      const WalletModel(
        id: 'bank',
        name: 'Cuenta',
        type: WalletType.bank,
        openingBalance: 0,
      ),
    );

    final wallets = await dataSource.getWallets();

    expect(wallets.map((w) => w.id), ['bank', 'cash']);
  });

  test('saves transfers newest first', () async {
    await dataSource.saveTransfer(
      WalletTransferModel(
        id: 'old',
        fromWalletId: 'bank',
        toWalletId: 'cash',
        amount: 10,
        date: DateTime.utc(2026, 10, 1),
      ),
    );
    await dataSource.saveTransfer(
      WalletTransferModel(
        id: 'new',
        fromWalletId: 'bank',
        toWalletId: 'cash',
        amount: 20,
        date: DateTime.utc(2026, 10, 2),
      ),
    );

    final transfers = await dataSource.getTransfers();

    expect(transfers.map((t) => t.id), ['new', 'old']);
  });

  test('hides tombstones and purges them on demand', () async {
    await dataSource.saveWallet(
      WalletModel(
        id: 'wallet-bank',
        name: 'Bank',
        type: WalletType.bank,
        openingBalance: 0,
        updatedAt: DateTime.utc(2026, 10, 1),
        deletedAt: DateTime.utc(2026, 10, 1),
      ),
    );
    await dataSource.saveTransfer(
      WalletTransferModel(
        id: 't-1',
        fromWalletId: 'wallet-bank',
        toWalletId: 'wallet-cash',
        amount: 10,
        date: DateTime.utc(2026, 10, 1),
        createdAt: DateTime.utc(2026, 10, 1),
        updatedAt: DateTime.utc(2026, 10, 1),
        deletedAt: DateTime.utc(2026, 10, 1),
      ),
    );

    expect(await dataSource.getWallets(), isEmpty);
    expect(await dataSource.getTransfers(), isEmpty);
    expect(await dataSource.getAllWallets(), hasLength(1));
    expect(await dataSource.getAllTransfers(), hasLength(1));

    expect(await dataSource.purgeTombstones(DateTime.utc(2026, 10, 2)), 2);
    expect(await dataSource.getAllWallets(), isEmpty);
    expect(await dataSource.getAllTransfers(), isEmpty);
  });

  test('maps corrupted data to CacheException', () async {
    await walletsBox.put('broken', 'not-a-map');

    await expectLater(dataSource.getWallets(), throwsA(isA<CacheException>()));
  });
}
