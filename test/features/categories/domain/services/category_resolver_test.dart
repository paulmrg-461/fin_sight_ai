import 'package:fin_sight_ai/features/categories/domain/entities/category_entity.dart';
import 'package:fin_sight_ai/features/categories/domain/services/category_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime.utc(2026, 1, 1);
  CategoryEntity category(
    String id,
    String name, {
    bool archived = false,
    DateTime? deletedAt,
  }) {
    return CategoryEntity(
      id: id,
      name: name,
      createdAt: createdAt,
      isArchived: archived,
      deletedAt: deletedAt,
    );
  }

  final resolver = CategoryResolver([
    category('food', 'Food'),
    category('rent', 'Rent', archived: true),
    category('old', 'Old', deletedAt: DateTime.utc(2026, 5, 1)),
    category('transport', 'Transport'),
  ]);

  test('matches active categories ignoring case and whitespace', () {
    expect(resolver.idForName('  food '), 'food');
    expect(resolver.idForName('TRANSPORT'), 'transport');
  });

  test('does not resolve archived or deleted categories for new writes', () {
    expect(resolver.idForName('Rent'), isNull);
    expect(resolver.idForName('Old'), isNull);
    expect(resolver.idForName('missing'), isNull);
    expect(resolver.idForName('  '), isNull);
  });

  test('resolves names for display, including archived and deleted', () {
    expect(resolver.nameForId('rent'), 'Rent');
    expect(resolver.nameForId('old'), 'Old');
    expect(resolver.nameForId('missing'), isNull);
    expect(resolver.nameForId(''), isNull);
  });

  test('falls back to the stored snapshot when the id is unknown', () {
    expect(
      resolver.displayName(categoryId: 'food', fallback: 'Legacy'),
      'Food',
    );
    expect(
      resolver.displayName(categoryId: 'gone', fallback: 'Legacy'),
      'Legacy',
    );
    expect(resolver.displayName(fallback: 'Legacy'), 'Legacy');
  });

  test('groups by id when present and normalized name otherwise', () {
    expect(resolver.key(categoryId: 'food', fallbackName: 'Dining'), 'food');
    expect(resolver.key(fallbackName: ' Dining '), 'dining');
  });

  test('finds the active category entity', () {
    expect(resolver.findByName('food')?.name, 'Food');
    expect(resolver.findByName('Rent'), isNull);
  });
}
