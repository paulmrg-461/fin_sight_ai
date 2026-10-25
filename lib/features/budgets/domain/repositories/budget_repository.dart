import '../../../../core/usecase/usecase.dart';
import '../entities/budget_entity.dart';

/// Domain contract for monthly budgets and categories.
abstract interface class BudgetRepository {
  ResultFuture<BudgetEntity> addBudget(BudgetEntity budget);

  /// Updates an existing budget while preserving its id.
  ResultFuture<BudgetEntity> updateBudget(BudgetEntity budget);

  ResultFuture<void> deleteBudget(String id);

  /// Returns budgets for [month] with spending aggregated from transactions.
  ResultFuture<List<BudgetProgress>> getBudgetProgress(DateTime month);

  /// Returns known categories from transactions and budgets.
  ResultFuture<List<String>> getCategories();

  /// Renames the category snapshot on every budget using [from].
  ResultFuture<int> renameCategory({required String from, required String to});
}
