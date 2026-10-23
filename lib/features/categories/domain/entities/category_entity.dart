import '../../../../core/domain/entity.dart';

/// A spending or income category owned by the user.
///
/// Transactions and budgets store the category [name], so renaming the catalog
/// never invalidates historical records.
class CategoryEntity extends Entity {
  const CategoryEntity({
    required this.id,
    required this.name,
    required this.createdAt,
    this.isArchived = false,
    this.updatedAt,
  });

  @override
  final String id;

  final String name;

  /// Archived categories stay in history but are hidden from pickers.
  final bool isArchived;

  final DateTime createdAt;
  final DateTime? updatedAt;

  CategoryEntity copyWith({
    String? id,
    String? name,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryEntity &&
          other.id == id &&
          other.name == name &&
          other.isArchived == isArchived &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, name, isArchived, createdAt, updatedAt);

  @override
  String toString() =>
      'CategoryEntity(id: $id, name: $name, archived: $isArchived)';
}
