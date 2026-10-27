import 'dart:io';

import 'package:fin_sight_ai/core/error/exceptions.dart';
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

    when(
      () => local.deleteGoal(any()),
    ).thenThrow(const CacheException('Broken.', code: 'savings_delete_failed'));
    final delete = await failing.deleteGoal('g-1');
    expect(delete.getLeft().toNullable()?.code, 'savings_delete_failed');
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
