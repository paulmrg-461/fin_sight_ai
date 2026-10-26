import 'dart:convert';

import 'package:fin_sight_ai/features/categories/data/models/category_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips sync metadata and tombstones', () {
    final deletedAt = DateTime.utc(2026, 10, 20);
    final model = CategoryModel(
      id: 'cat-1',
      name: 'Coffee',
      createdAt: DateTime.utc(2026, 10, 1),
      updatedAt: DateTime.utc(2026, 10, 19),
      isArchived: true,
      isSynced: true,
      deletedAt: deletedAt,
    );

    final json = jsonDecode(jsonEncode(model.toJson()));
    final restored = CategoryModel.fromJson(json as Map<String, dynamic>);

    expect(restored.toEntity(), model.toEntity());
    expect(restored.isSynced, isTrue);
    expect(restored.deletedAt, deletedAt);
    expect(restored.isDeleted, isTrue);
    expect(restored.lastModified, DateTime.utc(2026, 10, 19));
  });

  test('defaults legacy rows to unsynced and visible', () {
    final restored = CategoryModel.fromJson(const {
      'id': 'cat-1',
      'name': 'Coffee',
      'createdAt': '2026-10-01T00:00:00.000Z',
    });

    expect(restored.isSynced, isFalse);
    expect(restored.isDeleted, isFalse);
    expect(restored.lastModified, DateTime.utc(2026, 10, 1));
  });
}
