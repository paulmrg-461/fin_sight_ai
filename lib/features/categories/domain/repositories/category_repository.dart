import '../../../../core/usecase/usecase.dart';
import '../entities/category_entity.dart';

/// Domain contract for the category catalog.
abstract interface class CategoryRepository {
  /// Every category ordered by name, optionally including archived rows.
  ResultFuture<List<CategoryEntity>> getCategories({
    bool includeArchived = false,
  });

  /// Creates a category after validating its name.
  ResultFuture<CategoryEntity> addCategory(String name);

  /// Renames the category with [id].
  ResultFuture<CategoryEntity> renameCategory(String id, String name);

  /// Archives or restores the category with [id].
  ResultFuture<CategoryEntity> setArchived(String id, bool archived);
}
