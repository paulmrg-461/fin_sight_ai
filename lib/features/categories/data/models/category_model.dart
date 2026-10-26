import '../../domain/entities/category_entity.dart';

/// Data-transfer representation of [CategoryEntity].
class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.createdAt,
    super.isArchived,
    super.updatedAt,
    super.isSynced,
    super.deletedAt,
  });

  factory CategoryModel.fromEntity(CategoryEntity category) {
    return CategoryModel(
      id: category.id,
      name: category.name,
      createdAt: category.createdAt,
      isArchived: category.isArchived,
      updatedAt: category.updatedAt,
      isSynced: category.isSynced,
      deletedAt: category.deletedAt,
    );
  }

  @override
  CategoryModel copyWith({
    String? id,
    String? name,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? deletedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  CategoryEntity toEntity() => CategoryEntity(
    id: id,
    name: name,
    createdAt: createdAt,
    isArchived: isArchived,
    updatedAt: updatedAt,
    isSynced: isSynced,
    deletedAt: deletedAt,
  );

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final createdAt = json['createdAt'];
    final updatedAt = json['updatedAt'];
    final isSynced = json['isSynced'];
    final deletedAt = json['deletedAt'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('Category id is missing or invalid.');
    }
    if (name is! String || name.trim().isEmpty) {
      throw const FormatException('Category name is missing or invalid.');
    }

    return CategoryModel(
      id: id,
      name: name,
      createdAt: _parseDate(createdAt) ?? DateTime.now(),
      isArchived: json['isArchived'] == true,
      updatedAt: _parseDate(updatedAt),
      isSynced: isSynced is bool ? isSynced : false,
      deletedAt: _parseDate(deletedAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isArchived': isArchived,
    'createdAt': createdAt.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    'isSynced': isSynced,
    if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
  };

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
