import 'dart:io';

import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/core/sync/sync_operation.dart';
import 'package:fin_sight_ai/features/sync/data/datasources/hive_sync_local_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

void main() {
  late Directory tempDirectory;
  late Box<dynamic> queueBox;
  late Box<dynamic> metaBox;
  late HiveSyncLocalDataSource dataSource;
  var counter = 0;

  final queuedAt = DateTime.utc(2026, 10, 22, 12);

  SyncOperation upsert(String id, {DateTime? at}) {
    return SyncOperation.upsert(
      entityType: SyncEntityType.transaction,
      entityId: id,
      payload: {'id': id, 'updatedAt': (at ?? queuedAt).toIso8601String()},
      queuedAt: at ?? queuedAt,
    );
  }

  setUpAll(() async {
    tempDirectory = await Directory.systemTemp.createTemp('finsight_sync_');
    Hive.init(tempDirectory.path);
  });

  setUp(() async {
    counter++;
    queueBox = await Hive.openBox<dynamic>('queue_$counter');
    metaBox = await Hive.openBox<dynamic>('meta_$counter');
    dataSource = HiveSyncLocalDataSource(queueBox, metaBox);
  });

  tearDown(() async {
    await queueBox.close();
    await metaBox.close();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDirectory.delete(recursive: true);
  });

  group('HiveSyncLocalDataSource', () {
    test('starts empty', () async {
      expect(await dataSource.pending(), isEmpty);
      expect(await dataSource.pendingCount(), 0);
      expect(await dataSource.lastSyncedAt(), isNull);
    });

    test('enqueues and reads operations oldest first', () async {
      final later = queuedAt.add(const Duration(minutes: 1));
      await dataSource.enqueue(upsert('tx-2', at: later));
      await dataSource.enqueue(upsert('tx-1'));

      final pending = await dataSource.pending();

      expect(pending.map((op) => op.entityId), ['tx-1', 'tx-2']);
      expect(await dataSource.pendingCount(), 2);
    });

    test('collapses repeated edits of the same entity', () async {
      await dataSource.enqueue(upsert('tx-1'));
      await dataSource.enqueue(
        SyncOperation.upsert(
          entityType: SyncEntityType.transaction,
          entityId: 'tx-1',
          payload: {'id': 'tx-1', 'amount': 99},
          queuedAt: queuedAt.add(const Duration(minutes: 1)),
        ),
      );

      final pending = await dataSource.pending();

      expect(pending, hasLength(1));
      expect(pending.single.payload['amount'], 99);
    });

    test('removes an operation', () async {
      await dataSource.enqueue(upsert('tx-1'));

      await dataSource.remove('transaction:tx-1');

      expect(await dataSource.pending(), isEmpty);
    });

    test('stores and reads the last sync timestamp', () async {
      await dataSource.setLastSyncedAt(queuedAt);

      expect(await dataSource.lastSyncedAt(), queuedAt);
    });

    test('maps corrupted entries to CacheException', () async {
      await queueBox.put('broken', 'not-a-map');

      await expectLater(
        dataSource.pending(),
        throwsA(
          isA<CacheException>().having(
            (e) => e.code,
            'code',
            'sync_queue_read_failed',
          ),
        ),
      );
    });
  });
}
