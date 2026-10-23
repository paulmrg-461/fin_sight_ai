import 'package:bloc_test/bloc_test.dart';
import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/features/categories/domain/entities/category_entity.dart';
import 'package:fin_sight_ai/features/categories/domain/usecases/category_usecases.dart';
import 'package:fin_sight_ai/features/categories/presentation/bloc/category_bloc.dart';
import 'package:fin_sight_ai/features/categories/presentation/bloc/category_event.dart';
import 'package:fin_sight_ai/features/categories/presentation/bloc/category_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryCatalog extends Mock implements GetCategoryCatalogUseCase {}

class MockAddCategory extends Mock implements AddCategoryUseCase {}

class MockRenameCategory extends Mock implements RenameCategoryUseCase {}

class MockSetArchived extends Mock implements SetCategoryArchivedUseCase {}

void main() {
  late MockCategoryCatalog getCategories;
  late MockAddCategory addCategory;
  late MockRenameCategory renameCategory;
  late MockSetArchived setArchived;

  final rent = CategoryEntity(
    id: 'cat-1',
    name: 'Rent',
    createdAt: DateTime.utc(2026, 10, 20),
  );
  final pets = rent.copyWith(id: 'cat-2', name: 'Pets');

  setUpAll(() {
    registerFallbackValue(const GetCategoriesParams(includeArchived: true));
    registerFallbackValue(const RenameCategoryParams(id: 'id', name: 'name'));
    registerFallbackValue(
      const SetCategoryArchivedParams(id: 'id', archived: false),
    );
  });

  setUp(() {
    getCategories = MockCategoryCatalog();
    addCategory = MockAddCategory();
    renameCategory = MockRenameCategory();
    setArchived = MockSetArchived();
  });

  CategoryBloc buildBloc() =>
      CategoryBloc(getCategories, addCategory, renameCategory, setArchived);

  blocTest<CategoryBloc, CategoryState>(
    'loads the catalog',
    setUp: () {
      when(() => getCategories(any()))
          .thenAnswer((_) async => Right([rent, pets]));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const LoadCategories()),
    expect: () => [
      const CategoryLoading(),
      CategoryLoaded([rent, pets]),
    ],
  );

  blocTest<CategoryBloc, CategoryState>(
    'emits empty when there are no categories',
    setUp: () {
      when(() => getCategories(any())).thenAnswer((_) async => const Right([]));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const LoadCategories()),
    expect: () => [const CategoryLoading(), const CategoryEmpty()],
  );

  blocTest<CategoryBloc, CategoryState>(
    'surfaces load failures',
    setUp: () {
      when(() => getCategories(any()))
          .thenAnswer((_) async => const Left(CacheFailure('Storage down.')));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const LoadCategories()),
    expect: () => [
      const CategoryLoading(),
      const CategoryFailure('Storage down.'),
    ],
  );

  blocTest<CategoryBloc, CategoryState>(
    'adds a category and reloads',
    setUp: () {
      when(() => addCategory(any())).thenAnswer((_) async => Right(pets));
      when(() => getCategories(any()))
          .thenAnswer((_) async => Right([rent, pets]));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const AddCategory('Pets')),
    expect: () => [
      CategoryLoaded([rent, pets]),
    ],
  );

  blocTest<CategoryBloc, CategoryState>(
    'keeps the catalog and shows duplicate errors',
    setUp: () {
      when(() => addCategory(any())).thenAnswer(
        (_) async => const Left(
          ValidationFailure('Duplicate.', code: 'duplicate_category'),
        ),
      );
      when(() => getCategories(any())).thenAnswer((_) async => Right([rent]));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const AddCategory('Rent')),
    expect: () => [
      CategoryLoaded([rent], error: 'Duplicate.'),
    ],
  );

  blocTest<CategoryBloc, CategoryState>(
    'renames a category',
    setUp: () {
      when(() => renameCategory(any()))
          .thenAnswer((_) async => Right(rent.copyWith(name: 'Housing')));
      when(() => getCategories(any()))
          .thenAnswer((_) async => Right([rent.copyWith(name: 'Housing')]));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const RenameCategory(id: 'cat-1', name: 'Housing')),
    expect: () => [
      CategoryLoaded([rent.copyWith(name: 'Housing')]),
    ],
  );

  blocTest<CategoryBloc, CategoryState>(
    'archives a category',
    setUp: () {
      when(() => setArchived(any()))
          .thenAnswer((_) async => Right(rent.copyWith(isArchived: true)));
      when(() => getCategories(any()))
          .thenAnswer((_) async => Right([rent.copyWith(isArchived: true)]));
    },
    build: buildBloc,
    act: (bloc) =>
        bloc.add(const SetCategoryArchived(id: 'cat-1', archived: true)),
    expect: () => [
      CategoryLoaded([rent.copyWith(isArchived: true)]),
    ],
  );

  test('events compare by value', () {
    expect(const LoadCategories(), const LoadCategories());
    expect(const AddCategory('Pets'), const AddCategory('Pets'));
    expect(
      const RenameCategory(id: 'a', name: 'b'),
      const RenameCategory(id: 'a', name: 'b'),
    );
    expect(
      const SetCategoryArchived(id: 'a', archived: true),
      const SetCategoryArchived(id: 'a', archived: true),
    );
  });
}
