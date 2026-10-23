import '../models/category_model.dart';

/// Local persistence contract for the category catalog.
abstract interface class CategoryLocalDataSource {
  Future<List<CategoryModel>> getCategories();

  Future<void> saveCategory(CategoryModel category);
}
