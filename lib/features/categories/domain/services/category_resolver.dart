import '../entities/category_entity.dart';

/// Resolves category ids and names for writes, imports, and display.
///
/// New records should store the id; the name remains a fallback for legacy
/// rows and for categories that no longer exist. See
/// `specs/SPEC-category-ids.md`.
class CategoryResolver {
  CategoryResolver(List<CategoryEntity> categories)
    : _categories = List<CategoryEntity>.unmodifiable(categories);

  final List<CategoryEntity> _categories;

  static String _normalize(String name) => name.trim().toLowerCase();

  /// Active, non-deleted category matching [name] (case-insensitive).
  CategoryEntity? findByName(String name) {
    final normalized = _normalize(name);
    if (normalized.isEmpty) {
      return null;
    }
    for (final category in _categories) {
      if (category.isArchived || category.isDeleted) {
        continue;
      }
      if (_normalize(category.name) == normalized) {
        return category;
      }
    }
    return null;
  }

  String? idForName(String name) => findByName(name)?.id;

  /// Resolves the stored name, including archived or deleted categories so
  /// history keeps rendering after a rename or archive.
  String? nameForId(String id) {
    if (id.isEmpty) {
      return null;
    }
    for (final category in _categories) {
      if (category.id == id) {
        return category.name;
      }
    }
    return null;
  }

  /// Label for a record, falling back to its stored name snapshot.
  String displayName({String? categoryId, required String fallback}) =>
      nameForId(categoryId ?? '') ?? fallback;

  /// Stable grouping key: the id when present, otherwise the normalized name.
  String key({String? categoryId, required String fallbackName}) =>
      categoryId ?? _normalize(fallbackName);
}
