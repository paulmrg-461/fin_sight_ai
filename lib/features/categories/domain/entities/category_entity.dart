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
    this.isSynced = false,
    this.deletedAt,
  });

  @override
  final String id;

  final String name;

  /// Archived categories stay in history but are hidden from pickers.
  final bool isArchived;

  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Whether the remote backend already accepted this record.
  final bool isSynced;

  /// Soft-delete tombstone. Hidden from queries but kept for synchronization.
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  DateTime get lastModified => updatedAt ?? createdAt;

  CategoryEntity copyWith({
    String? id,
    String? name,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? deletedAt,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      deletedAt: deletedAt ?? this.deletedAt,
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
          other.updatedAt == updatedAt &&
          other.isSynced == isSynced &&
          other.deletedAt == deletedAt;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    isArchived,
    createdAt,
    updatedAt,
    isSynced,
    deletedAt,
  );

  @override
  String toString() =>
      'CategoryEntity(id: $id, name: $name, archived: $isArchived)';
}
