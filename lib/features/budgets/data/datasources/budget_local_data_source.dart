import '../models/budget_model.dart';

/// Local persistence contract for monthly budgets.
abstract interface class BudgetLocalDataSource {
  Future<List<BudgetModel>> getBudgets(DateTime month);

  Future<List<BudgetModel>> getAllBudgets();

  Future<void> saveBudget(BudgetModel budget);

  Future<void> deleteBudget(String id);
}
