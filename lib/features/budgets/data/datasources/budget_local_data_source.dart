import '../models/budget_model.dart';

/// Local persistence contract for monthly budgets.
abstract interface class BudgetLocalDataSource {
  Future<List<BudgetModel>> getBudgets(DateTime month);

  Future<List<BudgetModel>> getAllBudgets();

  /// Returns active and soft-deleted records (used by sync merges).
  Future<List<BudgetModel>> getAllBudgetsIncludingDeleted();

  Future<void> saveBudget(BudgetModel budget);

  Future<void> deleteBudget(String id);

  /// Hard-deletes tombstones older than [before] and returns the count.
  Future<int> purgeTombstones(DateTime before);
}
