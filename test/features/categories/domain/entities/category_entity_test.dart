import 'package:fin_sight_ai/features/categories/domain/entities/category_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime.utc(2026, 10, 20);

  CategoryEntity category({bool archived = false, String? updatedAt}) {
    return CategoryEntity(
      id: 'cat-1',
      name: 'Rent',
      createdAt: createdAt,
      isArchived: archived,
      updatedAt: updatedAt == null ? null : DateTime.parse(updatedAt),
    );
  }

  test('compares by value', () {
    expect(category(), category());
    expect(category(archived: true), isNot(category()));
  });

  test('hashes equal instances consistently', () {
    expect(category().hashCode, category().hashCode);
  });

  test('copies with overrides', () {
    final updated = category().copyWith(
      name: 'Housing',
      isArchived: true,
      updatedAt: DateTime.utc(2026, 10, 21),
    );

    expect(updated.id, 'cat-1');
    expect(updated.name, 'Housing');
    expect(updated.isArchived, isTrue);
    expect(updated.createdAt, createdAt);
    expect(updated.updatedAt, DateTime.utc(2026, 10, 21));
  });

  test('reports a readable string', () {
    expect(category().toString(), contains('Rent'));
  });
}
