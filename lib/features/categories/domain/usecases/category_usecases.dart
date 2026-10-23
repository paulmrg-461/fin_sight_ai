import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/category_entity.dart';
import '../repositories/category_repository.dart';

/// Input for category listing.
class GetCategoriesParams {
  const GetCategoriesParams({this.includeArchived = false});

  final bool includeArchived;
}

@lazySingleton
class GetCategoryCatalogUseCase
    implements UseCase<List<CategoryEntity>, GetCategoriesParams> {
  const GetCategoryCatalogUseCase(this._repository);

  final CategoryRepository _repository;

  @override
  ResultFuture<List<CategoryEntity>> call(GetCategoriesParams params) =>
      _repository.getCategories(includeArchived: params.includeArchived);
}

@lazySingleton
class AddCategoryUseCase implements UseCase<CategoryEntity, String> {
  const AddCategoryUseCase(this._repository);

  final CategoryRepository _repository;

  @override
  ResultFuture<CategoryEntity> call(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return Future.value(
        const Left(
          ValidationFailure('Category name is required.', code: 'empty_name'),
        ),
      );
    }
    if (trimmed.length > 60) {
      return Future.value(
        const Left(
          ValidationFailure(
            'Category name is too long.',
            code: 'name_too_long',
          ),
        ),
      );
    }
    return _repository.addCategory(trimmed);
  }
}

/// Input for renaming a category.
class RenameCategoryParams {
  const RenameCategoryParams({required this.id, required this.name});

  final String id;
  final String name;
}

@lazySingleton
class RenameCategoryUseCase
    implements UseCase<CategoryEntity, RenameCategoryParams> {
  const RenameCategoryUseCase(this._repository);

  final CategoryRepository _repository;

  @override
  ResultFuture<CategoryEntity> call(RenameCategoryParams params) {
    if (params.id.trim().isEmpty) {
      return Future.value(
        const Left(
          ValidationFailure('Category id is required.', code: 'missing_id'),
        ),
      );
    }
    final trimmed = params.name.trim();
    if (trimmed.isEmpty) {
      return Future.value(
        const Left(
          ValidationFailure('Category name is required.', code: 'empty_name'),
        ),
      );
    }
    if (trimmed.length > 60) {
      return Future.value(
        const Left(
          ValidationFailure(
            'Category name is too long.',
            code: 'name_too_long',
          ),
        ),
      );
    }
    return _repository.renameCategory(params.id.trim(), trimmed);
  }
}

/// Input for archiving or restoring a category.
class SetCategoryArchivedParams {
  const SetCategoryArchivedParams({required this.id, required this.archived});

  final String id;
  final bool archived;
}

@lazySingleton
class SetCategoryArchivedUseCase
    implements UseCase<CategoryEntity, SetCategoryArchivedParams> {
  const SetCategoryArchivedUseCase(this._repository);

  final CategoryRepository _repository;

  @override
  ResultFuture<CategoryEntity> call(SetCategoryArchivedParams params) {
    if (params.id.trim().isEmpty) {
      return Future.value(
        const Left(
          ValidationFailure('Category id is required.', code: 'missing_id'),
        ),
      );
    }
    return _repository.setArchived(params.id.trim(), params.archived);
  }
}
