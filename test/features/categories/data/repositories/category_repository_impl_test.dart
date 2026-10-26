import 'dart:io';

import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/core/sync/sync_operation.dart';
import 'package:fin_sight_ai/features/categories/data/datasources/category_local_data_source.dart';
import 'package:fin_sight_ai/features/categories/data/datasources/hive_category_local_data_source.dart';
import 'package:fin_sight_ai/features/categories/data/models/category_model.dart';
import 'package:fin_sight_ai/features/categories/data/repositories/category_repository_impl.dart';
import 'package:fin_sight_ai/features/categories/domain/entities/category_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryLocalDataSource extends Mock
    implements CategoryLocalDataSource {}

class MockSyncQueue extends Mock implements SyncQueue {}

void main() {
  late Directory directory;
  late Box<dynamic> box;
  late HiveCategoryLocalDataSource dataSource;
  var counter = 0;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('finsight_cat_repo_');
    Hive.init(directory.path);
    registerFallbackValue(
      CategoryModel(
        id: 'fallback',
        name: 'Fallback',
        createdAt: DateTime.utc(2026),
      ),
    );
    registerFallbackValue(
      SyncOperation.upsert(
        entityType: SyncEntityType.category,
        entityId: 'fallback',
        payload: const {},
        queuedAt: DateTime.utc(2026),
      ),
    );
  });

  setUp(() async {
    counter++;
    box = await Hive.openBox<dynamic>('cat_repo_$counter');
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

  CategoryRepositoryImpl repository({
    String languageCode = 'en',
    SyncQueue? syncQueue,
  }) => CategoryRepositoryImpl(
    dataSource,
    languageCode: languageCode,
    syncQueue: syncQueue,
  );

  test('enqueues an upsert for every catalog mutation', () async {
    final queue = MockSyncQueue();
    when(() => queue.enqueue(any())).thenAnswer((_) async {});
    final repo = repository(syncQueue: queue);

    final added = await repo.addCategory('Coffee');
    final id = added.fold((_) => '', (value) => value.id);
    await repo.renameCategory(id, 'Coffee beans');
    await repo.setArchived(id, true);

    final operations = verify(() => queue.enqueue(captureAny())).captured
        .cast<SyncOperation>();
    expect(operations, hasLength(3));
    expect(
      operations.map((operation) => operation.entityType),
      everyElement(SyncEntityType.category),
    );
    expect(operations.map((operation) => operation.payload['name']), [
      'Coffee',
      'Coffee beans',
      'Coffee beans',
    ]);
    expect(operations.last.payload['isArchived'], isTrue);
  });

  test('keeps the local write when the sync queue fails', () async {
    final queue = MockSyncQueue();
    when(() => queue.enqueue(any())).thenThrow(Exception('queue down'));

    final result = await repository(syncQueue: queue).addCategory('Coffee');

    expect(result.isRight(), isTrue);
    final stored = await dataSource.getCategories();
    expect(stored.map((category) => category.name), contains('Coffee'));
  });

  test('seeds English defaults once', () async {
    final result = await repository().getCategories();

    final categories = result
        .fold<List<CategoryEntity>>((_) => const [], (value) => value)
        .map((category) => category.name)
        .toList();
    expect(categories, containsAll(['Rent', 'Salary', 'Subscriptions']));
    expect(categories, hasLength(18));
    expect(categories, orderedEquals([...categories]..sort()));
  });

  test('seeds Spanish defaults for Spanish devices', () async {
    final result = await repository(languageCode: 'es').getCategories();

    final names = result
        .fold<List<CategoryEntity>>((_) => const [], (value) => value)
        .map((category) => category.name)
        .toList();
    expect(names, containsAll(['Arriendo', 'Salario', 'Suscripciones']));
  });

  test('does not reseed after archiving every category', () async {
    final repo = repository();
    final first = await repo.getCategories(includeArchived: true);
    final categories = first.fold<List<CategoryEntity>>(
      (_) => const [],
      (value) => value,
    );
    for (final category in categories) {
      await repo.setArchived(category.id, true);
    }

    final visible = await repo.getCategories();
    final all = await repo.getCategories(includeArchived: true);

    expect(visible.fold((_) => null, (value) => value), isEmpty);
    expect(all.fold((_) => null, (value) => value), hasLength(18));
  });

  test('adds a trimmed custom category', () async {
    final result = await repository().addCategory('  Pets  ');

    final category = result.fold((_) => null, (value) => value);
    expect(category?.name, 'Pets');
    expect(category?.isArchived, isFalse);
  });

  test('rejects duplicates ignoring case', () async {
    await repository().addCategory('Pets');

    final result = await repository().addCategory('  pets ');

    expect(
      result.fold((failure) => failure.code, (_) => null),
      'duplicate_category',
    );
  });

  test('renames a category', () async {
    final repo = repository();
    final added = await repo.addCategory('Pets');
    final category = added.fold((_) => null, (value) => value)!;

    final result = await repo.renameCategory(category.id, '  Pets & vet ');

    expect(result.fold((_) => null, (value) => value.name), 'Pets & vet');
  });

  test('rejects renaming onto another category', () async {
    final repo = repository();
    final added = await repo.addCategory('Pets');
    final category = added.fold((_) => null, (value) => value)!;

    final result = await repo.renameCategory(category.id, 'Rent');

    expect(
      result.fold((failure) => failure.code, (_) => null),
      'duplicate_category',
    );
  });

  test('reports a missing category on rename', () async {
    final result = await repository().renameCategory('missing', 'Pets');

    expect(
      result.fold((failure) => failure.code, (_) => null),
      'category_not_found',
    );
  });

  test('archives and restores categories', () async {
    final repo = repository();
    final added = await repo.addCategory('Pets');
    final category = added.fold((_) => null, (value) => value)!;

    await repo.setArchived(category.id, true);
    final visible = await repo.getCategories();
    expect(
      visible
          .fold<List<CategoryEntity>>((_) => const [], (value) => value)
          .map((item) => item.name),
      isNot(contains('Pets')),
    );

    await repo.setArchived(category.id, false);
    final restored = await repo.getCategories();
    expect(
      restored
          .fold<List<CategoryEntity>>((_) => const [], (value) => value)
          .map((item) => item.name),
      contains('Pets'),
    );
  });

  test('maps cache failures from the data source', () async {
    final failing = MockCategoryLocalDataSource();
    when(() => failing.getCategories()).thenThrow(
      const CacheException('Storage down.', code: 'category_read_failed'),
    );

    final result = await CategoryRepositoryImpl(
      failing,
      languageCode: 'en',
    ).getCategories();

    expect(
      result.fold((failure) => failure.code, (_) => null),
      'category_read_failed',
    );
  });

  test('maps write failures while adding', () async {
    final failing = MockCategoryLocalDataSource();
    when(() => failing.getCategories()).thenAnswer((_) async => []);
    when(() => failing.saveCategory(any())).thenThrow(
      const CacheException('Disk full.', code: 'category_write_failed'),
    );

    final result = await CategoryRepositoryImpl(
      failing,
      languageCode: 'en',
    ).addCategory('Pets');

    expect(
      result.fold((failure) => failure.code, (_) => null),
      'category_write_failed',
    );
  });

  test('maps cache failures while renaming', () async {
    final failing = MockCategoryLocalDataSource();
    when(() => failing.getCategories()).thenAnswer(
      (_) async => [
        CategoryModel(id: 'cat-1', name: 'Rent', createdAt: DateTime.utc(2026)),
      ],
    );
    when(() => failing.saveCategory(any())).thenThrow(
      const CacheException('Disk full.', code: 'category_write_failed'),
    );

    final result = await CategoryRepositoryImpl(
      failing,
      languageCode: 'en',
    ).renameCategory('cat-1', 'Housing');

    expect(
      result.fold((failure) => failure.code, (_) => null),
      'category_write_failed',
    );
  });

  test('maps cache failures while archiving', () async {
    final failing = MockCategoryLocalDataSource();
    when(() => failing.getCategories()).thenAnswer(
      (_) async => [
        CategoryModel(id: 'cat-1', name: 'Rent', createdAt: DateTime.utc(2026)),
      ],
    );
    when(() => failing.saveCategory(any())).thenThrow(
      const CacheException('Disk full.', code: 'category_write_failed'),
    );

    final result = await CategoryRepositoryImpl(
      failing,
      languageCode: 'en',
    ).setArchived('cat-1', true);

    expect(
      result.fold((failure) => failure.code, (_) => null),
      'category_write_failed',
    );
  });

  test('falls back to the device language when none is injected', () async {
    final result = await CategoryRepositoryImpl(dataSource).getCategories();

    expect(
      result.fold((_) => <CategoryEntity>[], (value) => value),
      isNotEmpty,
    );
  });

  test('maps unexpected errors to a cache failure', () async {
    final failing = MockCategoryLocalDataSource();
    when(() => failing.getCategories()).thenThrow(StateError('boom'));

    final result = await CategoryRepositoryImpl(
      failing,
      languageCode: 'en',
    ).getCategories();

    expect(
      result.fold((failure) => failure.runtimeType, (_) => null),
      CacheFailure,
    );
  });
}
