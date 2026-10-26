import '../models/category_model.dart';

/// Local persistence contract for the category catalog.
abstract interface class CategoryLocalDataSource {
  /// Visible categories, excluding tombstones.
  Future<List<CategoryModel>> getCategories();

  /// Every stored category, including tombstones, for sync merges.
  Future<List<CategoryModel>> getAllCategories();

  Future<void> saveCategory(CategoryModel category);

  /// Removes tombstones older than [before] and returns the count.
  Future<int> purgeTombstones(DateTime before);
}
