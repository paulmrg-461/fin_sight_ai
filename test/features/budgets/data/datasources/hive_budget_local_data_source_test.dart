import 'dart:io';

import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/features/budgets/data/datasources/hive_budget_local_data_source.dart';
import 'package:fin_sight_ai/features/budgets/data/models/budget_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

void main() {
  late Directory tempDirectory;
  late Box<dynamic> box;
  late HiveBudgetLocalDataSource dataSource;
  var counter = 0;

  BudgetModel buildModel({
    String id = 'budget-1',
    String category = 'Food',
    DateTime? month,
  }) => BudgetModel(
    id: id,
    category: category,
    monthlyLimit: 100,
    month: month ?? DateTime.utc(2026, 10),
  );

  setUpAll(() async {
    tempDirectory = await Directory.systemTemp.createTemp('finsight_budget_');
    Hive.init(tempDirectory.path);
  });

  setUp(() async {
    counter++;
    box = await Hive.openBox<dynamic>('budgets_$counter');
    dataSource = HiveBudgetLocalDataSource(box);
  });

  tearDown(() async {
    await box.close();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDirectory.delete(recursive: true);
  });

  group('HiveBudgetLocalDataSource', () {
    test('filters budgets by month', () async {
      await dataSource.saveBudget(buildModel(id: 'oct'));
      await dataSource.saveBudget(
        buildModel(id: 'nov', month: DateTime.utc(2026, 11)),
      );

      final budgets = await dataSource.getBudgets(DateTime.utc(2026, 10));

      expect(budgets.single.id, 'oct');
      expect(await dataSource.getAllBudgets(), hasLength(2));
    });

    test('sorts categories alphabetically', () async {
      await dataSource.saveBudget(buildModel(id: 'travel', category: 'Travel'));
      await dataSource.saveBudget(buildModel(id: 'food', category: 'Food'));

      final budgets = await dataSource.getAllBudgets();

      expect(budgets.map((b) => b.category), ['Food', 'Travel']);
    });

    test('replaces a budget with the same id', () async {
      await dataSource.saveBudget(buildModel());
      await dataSource.saveBudget(
        BudgetModel(
          id: 'budget-1',
          category: 'Food',
          monthlyLimit: 250,
          month: DateTime.utc(2026, 10),
        ),
      );

      final budgets = await dataSource.getAllBudgets();

      expect(budgets, hasLength(1));
      expect(budgets.single.monthlyLimit, 250);
    });

    test('deletes a budget', () async {
      await dataSource.saveBudget(buildModel());

      await dataSource.deleteBudget('budget-1');

      expect(await dataSource.getAllBudgets(), isEmpty);
    });

    test('maps corrupted entries to CacheException', () async {
      await box.put('broken', 'not-a-map');

      await expectLater(
        dataSource.getAllBudgets(),
        throwsA(isA<CacheException>()),
      );
    });
  });
}
