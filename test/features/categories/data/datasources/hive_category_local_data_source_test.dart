import 'dart:io';

import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/features/categories/data/datasources/hive_category_local_data_source.dart';
import 'package:fin_sight_ai/features/categories/data/models/category_model.dart';
import 'package:fin_sight_ai/features/categories/domain/entities/category_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

void main() {
  late Directory directory;
  late Box<dynamic> box;
  late HiveCategoryLocalDataSource dataSource;
  var counter = 0;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('finsight_categories_');
    Hive.init(directory.path);
  });

  setUp(() async {
    counter++;
    box = await Hive.openBox<dynamic>('categories_$counter');
    dataSource = HiveCategoryLocalDataSource(box);
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

  CategoryModel model({String id = 'cat-1', String name = 'Rent'}) {
    return CategoryModel(
      id: id,
      name: name,
      createdAt: DateTime.utc(2026, 10, 20),
      updatedAt: DateTime.utc(2026, 10, 21),
    );
  }

  test('maps entities to models and JSON', () {
    final entity = CategoryEntity(
      id: 'cat-1',
      name: 'Rent',
      createdAt: DateTime.utc(2026, 10, 20),
      updatedAt: DateTime.utc(2026, 10, 21),
    );

    final model = CategoryModel.fromEntity(entity);

    expect(model.toJson()['name'], 'Rent');
    expect(model.toJson()['updatedAt'], isNotNull);
    expect(model.toEntity(), entity);
  });

  test('round-trips categories through JSON', () async {
    await dataSource.saveCategory(model());
    await dataSource.saveCategory(
      model(id: 'cat-2', name: 'Subscriptions').copyWith(isArchived: true),
    );

    final categories = await dataSource.getCategories();

    expect(categories, hasLength(2));
    expect(categories.first.id, 'cat-1');
    expect(categories.first.name, 'Rent');
    expect(categories.last.isArchived, isTrue);
  });

  test('skips corrupted rows', () async {
    await box.put('bad', {'id': '', 'name': 42});
    await box.put('primitive', 'nope');
    await dataSource.saveCategory(model());

    final categories = await dataSource.getCategories();

    expect(categories, hasLength(1));
    expect(categories.single.name, 'Rent');
  });

  test('maps storage errors to CacheException', () async {
    await box.close();

    await expectLater(
      dataSource.getCategories(),
      throwsA(isA<CacheException>()),
    );
    await expectLater(
      dataSource.saveCategory(model()),
      throwsA(isA<CacheException>()),
    );
  });
}
