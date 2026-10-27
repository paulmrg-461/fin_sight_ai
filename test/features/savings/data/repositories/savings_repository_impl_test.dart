import 'dart:io';

import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/core/sync/sync_operation.dart';
import 'package:fin_sight_ai/core/utils/clock.dart';
import 'package:fin_sight_ai/features/savings/data/datasources/hive_savings_local_data_source.dart';
import 'package:fin_sight_ai/features/savings/data/datasources/savings_local_data_source.dart';
import 'package:fin_sight_ai/features/savings/data/models/savings_goal_model.dart';
import 'package:fin_sight_ai/features/savings/data/repositories/savings_repository_impl.dart';
import 'package:fin_sight_ai/features/savings/domain/entities/savings_goal_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

class MockSavingsLocalDataSource extends Mock
    implements SavingsLocalDataSource {}

class MockSyncQueue extends Mock implements SyncQueue {}

class FixedClock extends Clock {
  FixedClock(this.value);
  final DateTime value;
  @override
  DateTime now() => value;
}

void main() {
  late Directory directory;
  late Box<dynamic> box;
  late HiveSavingsLocalDataSource dataSource;
  late SavingsRepositoryImpl repository;
  var counter = 0;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('finsight_savings_');
    Hive.init(directory.path);
    registerFallbackValue(
      SyncOperation.upsert(
        entityType: SyncEntityType.savingsGoal,
        entityId: 'fallback',
        payload: const {},
        queuedAt: DateTime.utc(2026),
      ),
    );
    registerFallbackValue(
      SavingsGoalModel(
        id: 'fallback',
        name: 'Fallback',
        targetAmount: 1,
        createdAt: DateTime.utc(2026),
      ),
    );
  });

  setUp(() async {
    counter++;
    box = await Hive.openBox<dynamic>('savings_$counter');
    dataSource = HiveSavingsLocalDataSource(box);
    repository = SavingsRepositoryImpl(dataSource);
  });

  tearDown(() async {
    if (box.isOpen) {
      await box.close();
    }
  });

  tearDownAll(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  SavingsGoalEntity goal({String id = 'g-1'}) {
    return SavingsGoalEntity(
      id: id,
      name: 'Trip',
      targetAmount: 1000,
      createdAt: DateTime.utc(2026, 10, 1),
    );
  }

  test('adds, contributes to, and deletes goals', () async {
    await repository.addGoal(goal());
    final contribution = SavingsContribution(
      id: 'c-1',
      amount: 400,
      date: DateTime.utc(2026, 10, 2),
    );

    final updated = await repository.addContribution('g-1', contribution);
    expect(updated.getOrElse((_) => fail('Expected goal')).savedAmount, 400);

    final goals = await repository.getGoals();
    expect(goals.getOrElse((_) => const []), hasLength(1));

    await repository.deleteGoal('g-1');
    expect((await repository.getGoals()).getOrElse((_) => const []), isEmpty);
  });

  test('enqueues upserts and a tombstone for sync', () async {
    final queue = MockSyncQueue();
    when(() => queue.enqueue(any())).thenAnswer((_) async {});
    final now = DateTime.utc(2026, 10, 27, 12);
    final synced = SavingsRepositoryImpl(
      dataSource,
      syncQueue: queue,
      clock: FixedClock(now),
    );

    await synced.addGoal(goal());
    await synced.addContribution(
      'g-1',
      SavingsContribution(id: 'c-1', amount: 100, date: now),
    );
    await synced.deleteGoal('g-1');

    final operations = verify(() => queue.enqueue(captureAny())).captured
        .cast<SyncOperation>();
    expect(operations, hasLength(3));
    expect(
      operations.map((operation) => operation.entityType),
      everyElement(SyncEntityType.savingsGoal),
    );
    expect(operations.last.payload['deletedAt'], isNotNull);
    expect((await dataSource.getAllGoals()).single.isDeleted, isTrue);
  });

  test('purges old savings tombstones', () async {
    await repository.deleteGoal('missing');
    await repository.addGoal(goal());
    await repository.deleteGoal('g-1');

    expect(
      await repository.getGoals().then((r) => r.getOrElse((_) => [])),
      isEmpty,
    );
    expect(await dataSource.purgeTombstones(DateTime.utc(2027)), 1);
    expect(await dataSource.getAllGoals(), isEmpty);
  });

  test('updates a goal while preserving contributions', () async {
    await repository.addGoal(goal());
    await repository.addContribution(
      'g-1',
      SavingsContribution(id: 'c-1', amount: 100, date: DateTime.utc(2026)),
    );

    final result = await repository.updateGoal(
      goal().copyWith(name: 'House', targetAmount: 2000),
    );

    final updated = result.getOrElse((_) => fail('Expected update'));
    expect(updated.name, 'House');
    expect(updated.targetAmount, 2000);
    expect(updated.savedAmount, 100);
    expect(updated.isSynced, isFalse);
  });

  test('reports missing goals when contributing', () async {
    final result = await repository.addContribution(
      'missing',
      SavingsContribution(id: 'c', amount: 1, date: DateTime.utc(2026)),
    );

    expect(
      result.fold((failure) => failure.code, (_) => null),
      'savings_not_found',
    );
  });

  test('maps storage failures', () async {
    final local = MockSavingsLocalDataSource();
    when(
      () => local.getGoals(),
    ).thenThrow(const CacheException('Broken.', code: 'savings_read_failed'));
    final failing = SavingsRepositoryImpl(local);

    final result = await failing.getGoals();
    expect(result.getLeft().toNullable()?.code, 'savings_read_failed');

    when(
      () => local.saveGoal(any()),
    ).thenThrow(const CacheException('Broken.', code: 'savings_write_failed'));
    final save = await failing.addGoal(goal());
    expect(save.getLeft().toNullable()?.code, 'savings_write_failed');

    when(() => local.getGoals()).thenAnswer(
      (_) async => [
        SavingsGoalModel(
          id: 'g-1',
          name: 'Trip',
          targetAmount: 1000,
          createdAt: DateTime.utc(2026, 10, 1),
        ),
      ],
    );
    final delete = await failing.deleteGoal('g-1');
    expect(delete.getLeft().toNullable()?.code, 'savings_write_failed');
  });

  test('maps addContribution storage failures', () async {
    final local = MockSavingsLocalDataSource();
    when(() => local.getGoals()).thenAnswer(
      (_) async => [
        SavingsGoalModel(
          id: 'g-1',
          name: 'Trip',
          targetAmount: 1000,
          createdAt: DateTime.utc(2026, 10, 1),
        ),
      ],
    );
    when(
      () => local.saveGoal(any()),
    ).thenThrow(const CacheException('Broken.', code: 'savings_write_failed'));
    final failing = SavingsRepositoryImpl(local);

    final result = await failing.addContribution(
      'g-1',
      SavingsContribution(id: 'c', amount: 1, date: DateTime.utc(2026)),
    );

    expect(result.getLeft().toNullable()?.code, 'savings_write_failed');
  });
}
