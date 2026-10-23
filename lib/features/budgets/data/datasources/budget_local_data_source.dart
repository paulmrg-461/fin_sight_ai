import '../models/budget_model.dart';

/// Local persistence contract for monthly budgets.
abstract interface class BudgetLocalDataSource {
  Future<List<BudgetModel>> getBudgets(DateTime month);

  Future<List<BudgetModel>> getAllBudgets();

  /// Returns active and soft-deleted records (used by sync merges).
  Future<List<BudgetModel>> getAllBudgetsIncludingDeleted();

  /// Returns every stored budget whose persisted month still uses the legacy
  /// UTC-instant convention, normalized to the calendar-month convention.
  Future<List<BudgetModel>> getLegacyCalendarBudgets();

  Future<void> saveBudget(BudgetModel budget);

  Future<void> deleteBudget(String id);

  /// Hard-deletes tombstones older than [before] and returns the count.
  Future<int> purgeTombstones(DateTime before);
}
