import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/category_model.dart';
import 'category_local_data_source.dart';

/// Hive-backed category catalog.
class HiveCategoryLocalDataSource implements CategoryLocalDataSource {
  const HiveCategoryLocalDataSource(this._box);

  final Box<dynamic> _box;

  @override
  Future<List<CategoryModel>> getCategories() async {
    final categories = await getAllCategories();
    return List<CategoryModel>.unmodifiable(
      categories.where((category) => !category.isDeleted),
    );
  }

  @override
  Future<List<CategoryModel>> getAllCategories() async {
    try {
      final categories = <CategoryModel>[];
      for (final value in _box.values) {
        if (value is! Map) {
          continue;
        }
        try {
          categories.add(
            CategoryModel.fromJson(Map<String, dynamic>.from(value)),
          );
        } on FormatException {
          // Skip corrupted rows instead of breaking the whole catalog.
        }
      }
      return List<CategoryModel>.unmodifiable(categories);
    } catch (_) {
      throw const CacheException(
        'Unable to read local categories.',
        code: 'category_read_failed',
      );
    }
  }

  @override
  Future<void> saveCategory(CategoryModel category) async {
    try {
      await _box.put(category.id, category.toJson());
    } catch (_) {
      throw const CacheException(
        'Unable to save the category locally.',
        code: 'category_write_failed',
      );
    }
  }

  @override
  Future<int> purgeTombstones(DateTime before) async {
    try {
      final keys = <dynamic>[];
      for (final key in _box.keys) {
        final value = _box.get(key);
        if (value is! Map) {
          continue;
        }
        final model = CategoryModel.fromJson(Map<String, dynamic>.from(value));
        final deletedAt = model.deletedAt;
        if (deletedAt != null && deletedAt.isBefore(before)) {
          keys.add(key);
        }
      }
      if (keys.isEmpty) {
        return 0;
      }
      await _box.deleteAll(keys);
      return keys.length;
    } catch (_) {
      throw const CacheException(
        'Unable to purge category tombstones.',
        code: 'category_purge_failed',
      );
    }
  }
}
