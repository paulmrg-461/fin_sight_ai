import 'dart:io';

import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/core/sync/sync_operation.dart';
import 'package:fin_sight_ai/core/utils/clock.dart';
import 'package:fin_sight_ai/features/receivables/data/datasources/hive_receivable_local_data_source.dart';
import 'package:fin_sight_ai/features/receivables/data/datasources/receivable_local_data_source.dart';
import 'package:fin_sight_ai/features/receivables/data/models/receivable_model.dart';
import 'package:fin_sight_ai/features/receivables/data/repositories/receivable_repository_impl.dart';
import 'package:fin_sight_ai/features/receivables/domain/entities/receivable_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

class MockReceivableLocalDataSource extends Mock
    implements ReceivableLocalDataSource {}

class MockSyncQueue extends Mock implements SyncQueue {}

class FixedClock extends Clock {
  const FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

void main() {
  final dateLent = DateTime.utc(2026, 10, 1);
  final createdAt = DateTime.utc(2026, 10, 1, 9);
  final now = DateTime.utc(2026, 10, 22, 15);
  final payment = ReceivablePayment(
    id: 'p-1',
    amount: 400,
    paidAt: now,
    note: 'Cash',
  );

  ReceivableEntity buildEntity({double remaining = 1000}) {
    return ReceivableEntity(
      id: 'receivable-1',
      debtorName: 'Ana',
      totalAmount: 1000,
      remainingAmount: remaining,
      dateLent: dateLent,
      dueDate: DateTime.utc(2026, 12, 1),
      notes: 'Lunch loan',
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  group('ReceivableRepositoryImpl synchronization queue', () {
    late MockReceivableLocalDataSource dataSource;
    late MockSyncQueue queue;
    late ReceivableRepositoryImpl repository;

    setUpAll(() {
      registerFallbackValue(ReceivableModel.fromEntity(buildEntity()));
      registerFallbackValue(
        SyncOperation.upsert(
          entityType: SyncEntityType.receivable,
          entityId: 'fallback',
          payload: const {},
          queuedAt: now,
        ),
      );
    });

    setUp(() {
      dataSource = MockReceivableLocalDataSource();
      queue = MockSyncQueue();
      repository = ReceivableRepositoryImpl(
        dataSource,
        syncQueue: queue,
        clock: FixedClock(now),
      );
      when(() => queue.enqueue(any())).thenAnswer((_) async {});
      when(() => dataSource.saveReceivable(any())).thenAnswer((_) async {});
      when(() => dataSource.getReceivables())
          .thenAnswer((_) async => [ReceivableModel.fromEntity(buildEntity())]);
    });

    test('queues adds, payments, and tombstones for sync', () async {
      await repository.addReceivable(buildEntity());
      await repository.makePayment('receivable-1', payment);
      await repository.deleteReceivable('receivable-1');

      final operations = verify(() => queue.enqueue(captureAny())).captured
          .cast<SyncOperation>();
      expect(operations, hasLength(3));
      expect(
        operations.every(
          (operation) => operation.entityType == SyncEntityType.receivable,
        ),
        isTrue,
      );
      expect(operations.last.payload['deletedAt'], isNotNull);
    });
  });

  group('ReceivableRepositoryImpl with Hive', () {
    late Directory tempDirectory;
    late Box<dynamic> box;
    late ReceivableRepositoryImpl repository;

    setUpAll(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'finsight_receivable_repository_',
      );
      Hive.init(tempDirectory.path);
      registerFallbackValue(ReceivableModel.fromEntity(buildEntity()));
    });

    setUp(() async {
      box = await Hive.openBox<dynamic>(
        'receivable_repo_${DateTime.now().microsecondsSinceEpoch}',
      );
      repository = ReceivableRepositoryImpl(
        HiveReceivableLocalDataSource(box),
        clock: FixedClock(now),
      );
    });

    tearDown(() async {
      await box.close();
    });

    tearDownAll(() async {
      await Hive.close();
      await tempDirectory.delete(recursive: true);
    });

    test('adds and reads a receivable', () async {
      final added = await repository.addReceivable(buildEntity());

      expect(
        added.getOrElse((_) => fail('Expected a receivable')).id,
        'receivable-1',
      );

      final result = await repository.getReceivables();
      final receivables = result.getOrElse((_) => fail('Expected receivables'));
      expect(receivables.single.debtorName, 'Ana');
      expect(receivables.single.updatedAt, now);
    });

    test('updates and returns the stored receivable', () async {
      await repository.addReceivable(buildEntity());

      final result = await repository.updateReceivable(
        buildEntity(remaining: 500),
      );

      final updated = result.getOrElse((_) => fail('Expected an update'));
      expect(updated.remainingAmount, 500);
      expect(
        (await repository.getReceivables())
            .getOrElse((_) => fail('Expected receivables'))
            .single
            .remainingAmount,
        500,
      );
    });

    test('applies a partial payment and keeps the receivable active', () async {
      await repository.addReceivable(buildEntity());

      final result = await repository.makePayment('receivable-1', payment);
      final updated = result.getOrElse((_) => fail('Expected a payment'));

      expect(updated.remainingAmount, 600);
      expect(updated.status, ReceivableStatus.active);
      expect(updated.paymentHistory, hasLength(1));
      expect(updated.paymentHistory.single.amount, 400);
      expect(updated.updatedAt, now);
    });

    test('clamps an overpayment and marks the receivable paid', () async {
      await repository.addReceivable(buildEntity(remaining: 250));

      final result = await repository.makePayment(
        'receivable-1',
        payment.copyWith(amount: 1000),
      );
      final updated = result.getOrElse((_) => fail('Expected a payment'));

      expect(updated.remainingAmount, 0);
      expect(updated.status, ReceivableStatus.paid);
      expect(updated.paymentHistory.single.amount, 250);
      expect(updated.isPaid, isTrue);
    });

    test('marks an exact full payment as paid', () async {
      await repository.addReceivable(buildEntity());

      final result = await repository.makePayment(
        'receivable-1',
        payment.copyWith(amount: 1000),
      );
      final updated = result.getOrElse((_) => fail('Expected a payment'));

      expect(updated.remainingAmount, 0);
      expect(updated.isPaid, isTrue);
      expect(updated.progress, 1);
    });

    test('rejects a payment for an unknown receivable', () async {
      final result = await repository.makePayment('missing', payment);

      expect(result.getLeft().toNullable()?.code, 'receivable_not_found');
    });

    test('rejects a payment for a settled receivable', () async {
      await repository.addReceivable(buildEntity(remaining: 0));

      final result = await repository.makePayment('receivable-1', payment);

      expect(result.getLeft().toNullable()?.code, 'receivable_already_paid');
    });

    test('rejects non-positive payments', () async {
      final result = await repository.makePayment(
        'receivable-1',
        payment.copyWith(amount: 0),
      );

      expect(result.getLeft().toNullable()?.code, 'invalid_payment');
    });

    test('deletes the receivable and its history', () async {
      await repository.addReceivable(buildEntity());

      final result = await repository.deleteReceivable('receivable-1');

      expect(result.isRight(), isTrue);
      expect(
        (await repository.getReceivables()).getOrElse(
          (_) => fail('Expected receivables'),
        ),
        isEmpty,
      );
    });

    test('deleting a missing receivable succeeds', () async {
      final result = await repository.deleteReceivable('missing');

      expect(result.isRight(), isTrue);
    });
  });

  group('ReceivableRepositoryImpl failure mapping', () {
    late MockReceivableLocalDataSource dataSource;
    late ReceivableRepositoryImpl repository;

    setUp(() {
      dataSource = MockReceivableLocalDataSource();
      repository = ReceivableRepositoryImpl(dataSource, clock: FixedClock(now));
    });

    test('maps read failures to CacheFailure', () async {
      when(
        () => dataSource.getReceivables(),
      ).thenThrow(const CacheException('Corrupt.', code: 'cache_read_failed'));

      final result = await repository.getReceivables();

      expect(result.getLeft().toNullable()?.code, 'cache_read_failed');
    });

    test('maps unexpected read errors to a generic CacheFailure', () async {
      when(() => dataSource.getReceivables()).thenThrow(StateError('boom'));

      final result = await repository.getReceivables();

      expect(result.getLeft().toNullable(), isA<CacheFailure>());
    });

    test('maps write failures to CacheFailure', () async {
      when(() => dataSource.saveReceivable(any())).thenThrow(
        const CacheException('Disk full.', code: 'cache_write_failed'),
      );

      final result = await repository.addReceivable(buildEntity());

      expect(result.getLeft().toNullable()?.code, 'cache_write_failed');
    });

    test('maps unexpected write errors to a generic CacheFailure', () async {
      when(() => dataSource.saveReceivable(any()))
          .thenThrow(StateError('boom'));

      final result = await repository.addReceivable(buildEntity());

      expect(result.getLeft().toNullable(), isA<CacheFailure>());
    });

    test('maps delete failures to CacheFailure', () async {
      when(() => dataSource.deleteReceivable(any())).thenThrow(
        const CacheException('Missing.', code: 'cache_delete_failed'),
      );

      final result = await repository.deleteReceivable('receivable-1');

      expect(result.getLeft().toNullable()?.code, 'cache_delete_failed');
    });

    test('maps payment failures to CacheFailure', () async {
      when(() => dataSource.getReceivables())
          .thenAnswer((_) async => [ReceivableModel.fromEntity(buildEntity())]);
      when(() => dataSource.saveReceivable(any())).thenThrow(
        const CacheException('Disk full.', code: 'cache_write_failed'),
      );

      final result = await repository.makePayment('receivable-1', payment);

      expect(result.getLeft().toNullable()?.code, 'cache_write_failed');
    });
  });
}
