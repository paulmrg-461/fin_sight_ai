import 'dart:io';

import 'package:fin_sight_ai/core/services/app_boxes.dart';
import 'package:fin_sight_ai/core/services/local_data_scope.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

void main() {
  late Directory tempDirectory;
  late AppBoxes boxes;
  late HiveLocalDataScope scope;

  setUpAll(() async {
    tempDirectory = await Directory.systemTemp.createTemp('finsight_scope_');
    Hive.init(tempDirectory.path);
  });

  setUp(() async {
    boxes = AppBoxes(
      transactions: await Hive.openBox<dynamic>('scope_transactions'),
      debts: await Hive.openBox<dynamic>('scope_debts'),
      receivables: await Hive.openBox<dynamic>('scope_receivables'),
      receipts: await Hive.openBox<dynamic>('scope_receipts'),
      syncQueue: await Hive.openBox<dynamic>('scope_sync_queue'),
      syncMeta: await Hive.openBox<dynamic>('scope_sync_meta'),
      budgets: await Hive.openBox<dynamic>('scope_budgets'),
      wallets: await Hive.openBox<dynamic>('scope_wallets'),
      walletTransfers: await Hive.openBox<dynamic>('scope_wallet_transfers'),
      settings: await Hive.openBox<dynamic>('scope_settings'),
      categories: await Hive.openBox<dynamic>('scope_categories'),
      scheduledPayments: await Hive.openBox<dynamic>(
        'scope_scheduled_payments',
      ),
    );
    scope = HiveLocalDataScope(boxes);
  });

  tearDown(() async {
    for (final box in [
      boxes.transactions,
      boxes.debts,
      boxes.receivables,
      boxes.receipts,
      boxes.syncQueue,
      boxes.syncMeta,
      boxes.budgets,
      boxes.wallets,
      boxes.walletTransfers,
      boxes.settings,
      boxes.categories,
      boxes.scheduledPayments,
    ]) {
      await box.close();
    }
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDirectory.delete(recursive: true);
  });

  test('returns null when no owner is recorded', () async {
    expect(await scope.getOwnerUserId(), isNull);
  });

  test('persists and removes the owner', () async {
    await scope.setOwnerUserId('user-1');
    expect(await scope.getOwnerUserId(), 'user-1');

    await scope.setOwnerUserId(null);
    expect(await scope.getOwnerUserId(), isNull);
  });

  test('clears every data box and preserves settings preferences', () async {
    await boxes.transactions.put('t1', {'id': 't1'});
    await boxes.debts.put('d1', {'id': 'd1'});
    await boxes.receivables.put('r1', {'id': 'r1'});
    await boxes.receipts.put('r1', {'id': 'r1'});
    await boxes.budgets.put('b1', {'id': 'b1'});
    await boxes.wallets.put('w1', {'id': 'w1'});
    await boxes.walletTransfers.put('wt1', {'id': 'wt1'});
    await boxes.categories.put('c1', {'id': 'c1'});
    await boxes.scheduledPayments.put('sp1', {'id': 'sp1'});
    await boxes.syncQueue.put('q1', {'id': 'q1'});
    await boxes.syncMeta.put('m1', {'id': 'm1'});
    await boxes.settings.put('currency', 'USD');
    await boxes.settings.put('locale', 'es');
    await boxes.settings.put('calendar_migration_v1', true);
    await scope.setOwnerUserId('user-1');

    await scope.clearAllUserData();

    expect(boxes.transactions.isEmpty, isTrue);
    expect(boxes.debts.isEmpty, isTrue);
    expect(boxes.receivables.isEmpty, isTrue);
    expect(boxes.receipts.isEmpty, isTrue);
    expect(boxes.budgets.isEmpty, isTrue);
    expect(boxes.wallets.isEmpty, isTrue);
    expect(boxes.walletTransfers.isEmpty, isTrue);
    expect(boxes.categories.isEmpty, isTrue);
    expect(boxes.scheduledPayments.isEmpty, isTrue);
    expect(boxes.syncQueue.isEmpty, isTrue);
    expect(boxes.syncMeta.isEmpty, isTrue);
    expect(boxes.settings.get('currency'), 'USD');
    expect(boxes.settings.get('locale'), 'es');
    expect(boxes.settings.get('calendar_migration_v1'), isTrue);
    expect(await scope.getOwnerUserId(), 'user-1');
  });
}
