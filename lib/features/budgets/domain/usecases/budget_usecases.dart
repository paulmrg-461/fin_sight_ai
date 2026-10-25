import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/budget_entity.dart';
import '../repositories/budget_repository.dart';

class AddBudgetParams {
  const AddBudgetParams({
    required this.category,
    required this.monthlyLimit,
    required this.month,
  });

  final String category;
  final double monthlyLimit;
  final DateTime month;
}

@lazySingleton
class AddBudgetUseCase implements UseCase<BudgetEntity, AddBudgetParams> {
  AddBudgetUseCase(this._repository, {this.uuid = const Uuid()});

  final BudgetRepository _repository;
  final Uuid uuid;

  @override
  Future<Result<BudgetEntity>> call(AddBudgetParams params) async {
    final category = params.category.trim();
    if (category.isEmpty) {
      return const Left(
        ValidationFailure('Category is required.', code: 'missing_category'),
      );
    }
    if (!params.monthlyLimit.isFinite || params.monthlyLimit <= 0) {
      return const Left(
        ValidationFailure(
          'Monthly limit must be greater than zero.',
          code: 'invalid_limit',
        ),
      );
    }

    final budget = BudgetEntity(
      id: uuid.v4(),
      category: category,
      monthlyLimit: double.parse(params.monthlyLimit.toStringAsFixed(2)),
      month: normalizeBudgetMonth(params.month),
    );
    return _repository.addBudget(budget);
  }
}

class UpdateBudgetParams {
  const UpdateBudgetParams({
    required this.id,
    required this.category,
    required this.monthlyLimit,
    required this.month,
  });

  final String id;
  final String category;
  final double monthlyLimit;
  final DateTime month;
}

@lazySingleton
class UpdateBudgetUseCase implements UseCase<BudgetEntity, UpdateBudgetParams> {
  const UpdateBudgetUseCase(this._repository);

  final BudgetRepository _repository;

  @override
  Future<Result<BudgetEntity>> call(UpdateBudgetParams params) async {
    final id = params.id.trim();
    if (id.isEmpty) {
      return const Left(
        ValidationFailure('Budget id is required.', code: 'missing_id'),
      );
    }
    final category = params.category.trim();
    if (category.isEmpty) {
      return const Left(
        ValidationFailure('Category is required.', code: 'missing_category'),
      );
    }
    if (!params.monthlyLimit.isFinite || params.monthlyLimit <= 0) {
      return const Left(
        ValidationFailure(
          'Monthly limit must be greater than zero.',
          code: 'invalid_limit',
        ),
      );
    }

    return _repository.updateBudget(
      BudgetEntity(
        id: id,
        category: category,
        monthlyLimit: double.parse(params.monthlyLimit.toStringAsFixed(2)),
        month: normalizeBudgetMonth(params.month),
      ),
    );
  }
}

@lazySingleton
class DeleteBudgetUseCase implements UseCase<void, String> {
  const DeleteBudgetUseCase(this._repository);

  final BudgetRepository _repository;

  @override
  Future<Result<void>> call(String id) async {
    if (id.trim().isEmpty) {
      return const Left(
        ValidationFailure('Budget id is required.', code: 'missing_id'),
      );
    }
    return _repository.deleteBudget(id);
  }
}

@lazySingleton
class GetBudgetProgressUseCase
    implements UseCase<List<BudgetProgress>, DateTime> {
  const GetBudgetProgressUseCase(this._repository);

  final BudgetRepository _repository;

  @override
  ResultFuture<List<BudgetProgress>> call(DateTime month) =>
      _repository.getBudgetProgress(normalizeBudgetMonth(month));
}

@lazySingleton
class GetCategoriesUseCase implements UseCase<List<String>, NoParams> {
  const GetCategoriesUseCase(this._repository);

  final BudgetRepository _repository;

  @override
  ResultFuture<List<String>> call(NoParams params) =>
      _repository.getCategories();
}

/// Normalizes a date to the first day of its month at midnight.
DateTime normalizeBudgetMonth(DateTime date) => DateTime(date.year, date.month);
