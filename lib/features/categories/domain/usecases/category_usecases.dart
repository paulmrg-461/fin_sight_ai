import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../budgets/domain/repositories/budget_repository.dart';
import '../../../scheduled_payments/domain/repositories/scheduled_payment_repository.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';
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
  const RenameCategoryUseCase(
    this._repository,
    this._transactions,
    this._budgets,
    this._schedules,
  );

  final CategoryRepository _repository;
  final TransactionRepository _transactions;
  final BudgetRepository _budgets;
  final ScheduledPaymentRepository _schedules;

  @override
  Future<Result<CategoryEntity>> call(RenameCategoryParams params) async {
    if (params.id.trim().isEmpty) {
      return const Left(
        ValidationFailure('Category id is required.', code: 'missing_id'),
      );
    }
    final trimmed = params.name.trim();
    if (trimmed.isEmpty) {
      return const Left(
        ValidationFailure('Category name is required.', code: 'empty_name'),
      );
    }
    if (trimmed.length > 60) {
      return const Left(
        ValidationFailure('Category name is too long.', code: 'name_too_long'),
      );
    }

    final catalogResult = await _repository.getCategories(
      includeArchived: true,
    );
    final catalogFailure = catalogResult.getLeft().toNullable();
    if (catalogFailure != null) {
      return Left(catalogFailure);
    }
    final categories = catalogResult.getOrElse((_) => const <CategoryEntity>[]);
    CategoryEntity? existing;
    for (final category in categories) {
      if (category.id == params.id.trim()) {
        existing = category;
        break;
      }
    }
    if (existing == null) {
      return const Left(
        ValidationFailure('Category not found.', code: 'category_not_found'),
      );
    }

    final renamed = await _repository.renameCategory(params.id.trim(), trimmed);
    final failure = renamed.getLeft().toNullable();
    if (failure != null) {
      return Left(failure);
    }

    if (existing.name != trimmed) {
      final transactionResult = await _transactions.renameCategory(
        from: existing.name,
        to: trimmed,
      );
      final transactionFailure = transactionResult.getLeft().toNullable();
      if (transactionFailure != null) {
        return Left(transactionFailure);
      }

      final budgetResult = await _budgets.renameCategory(
        from: existing.name,
        to: trimmed,
      );
      final budgetFailure = budgetResult.getLeft().toNullable();
      if (budgetFailure != null) {
        return Left(budgetFailure);
      }

      final scheduleResult = await _schedules.renameCategory(
        from: existing.name,
        to: trimmed,
      );
      final scheduleFailure = scheduleResult.getLeft().toNullable();
      if (scheduleFailure != null) {
        return Left(scheduleFailure);
      }
    }

    return renamed;
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
