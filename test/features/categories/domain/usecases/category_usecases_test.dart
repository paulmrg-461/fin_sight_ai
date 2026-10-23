import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/features/categories/domain/entities/category_entity.dart';
import 'package:fin_sight_ai/features/categories/domain/repositories/category_repository.dart';
import 'package:fin_sight_ai/features/categories/domain/usecases/category_usecases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late MockCategoryRepository repository;
  final now = DateTime.utc(2026, 10, 20);

  final category = CategoryEntity(id: 'cat-1', name: 'Rent', createdAt: now);

  setUp(() {
    repository = MockCategoryRepository();
  });

  group('GetCategoryCatalogUseCase', () {
    test('passes the archive flag to the repository', () async {
      when(() => repository.getCategories(includeArchived: true))
          .thenAnswer((_) async => Right([category]));

      final result = await GetCategoryCatalogUseCase(repository)(
        const GetCategoriesParams(includeArchived: true),
      );

      expect(result.fold((_) => null, (value) => value), [category]);
    });
  });

  group('AddCategoryUseCase', () {
    test('rejects empty names', () async {
      final result = await AddCategoryUseCase(repository)('   ');

      expect(result.fold((failure) => failure.code, (_) => null), 'empty_name');
      verifyNever(() => repository.addCategory(any()));
    });

    test('rejects overlong names', () async {
      final result = await AddCategoryUseCase(repository)('x' * 61);

      expect(
        result.fold((failure) => failure.code, (_) => null),
        'name_too_long',
      );
    });

    test('trims and delegates to the repository', () async {
      when(() => repository.addCategory('Pets'))
          .thenAnswer((_) async => Right(category));

      final result = await AddCategoryUseCase(repository)('  Pets  ');

      expect(result.isRight(), isTrue);
      verify(() => repository.addCategory('Pets')).called(1);
    });
  });

  group('RenameCategoryUseCase', () {
    test('requires an id', () async {
      final result = await RenameCategoryUseCase(repository)(
        const RenameCategoryParams(id: ' ', name: 'Pets'),
      );

      expect(result.fold((failure) => failure.code, (_) => null), 'missing_id');
    });

    test('rejects empty names', () async {
      final result = await RenameCategoryUseCase(repository)(
        const RenameCategoryParams(id: 'cat-1', name: '  '),
      );

      expect(result.fold((failure) => failure.code, (_) => null), 'empty_name');
    });

    test('trims and delegates', () async {
      when(() => repository.renameCategory('cat-1', 'Housing'))
          .thenAnswer((_) async => Right(category));

      final result = await RenameCategoryUseCase(repository)(
        const RenameCategoryParams(id: ' cat-1 ', name: ' Housing '),
      );

      expect(result.isRight(), isTrue);
      verify(() => repository.renameCategory('cat-1', 'Housing')).called(1);
    });
  });

  group('SetCategoryArchivedUseCase', () {
    test('requires an id', () async {
      final result = await SetCategoryArchivedUseCase(repository)(
        const SetCategoryArchivedParams(id: '', archived: true),
      );

      expect(result.fold((failure) => failure.code, (_) => null), 'missing_id');
    });

    test('delegates archive changes', () async {
      when(() => repository.setArchived('cat-1', true))
          .thenAnswer((_) async => Right(category.copyWith(isArchived: true)));

      final result = await SetCategoryArchivedUseCase(repository)(
        const SetCategoryArchivedParams(id: ' cat-1 ', archived: true),
      );

      expect(result.isRight(), isTrue);
      verify(() => repository.setArchived('cat-1', true)).called(1);
    });

    test('propagates validation failures', () async {
      when(() => repository.setArchived(any(), any())).thenAnswer(
        (_) async => const Left(
          ValidationFailure('Category not found.', code: 'category_not_found'),
        ),
      );

      final result = await SetCategoryArchivedUseCase(repository)(
        const SetCategoryArchivedParams(id: 'missing', archived: false),
      );

      expect(
        result.fold((failure) => failure.code, (_) => null),
        'category_not_found',
      );
    });
  });
}
