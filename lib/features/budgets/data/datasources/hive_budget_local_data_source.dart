import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../../domain/usecases/budget_usecases.dart';
import '../models/budget_model.dart';
import 'budget_local_data_source.dart';

/// Hive-backed budget storage keyed by id.
class HiveBudgetLocalDataSource implements BudgetLocalDataSource {
  const HiveBudgetLocalDataSource(this._box);

  final Box<dynamic> _box;

  @override
  Future<List<BudgetModel>> getBudgets(DateTime month) async {
    final normalized = normalizeBudgetMonth(month);
    final budgets = await getAllBudgets();
    return budgets
        .where(
          (budget) =>
              budget.month.year == normalized.year &&
              budget.month.month == normalized.month,
        )
        .toList(growable: false);
  }

  @override
  Future<List<BudgetModel>> getAllBudgets() async {
    try {
      final budgets = <BudgetModel>[];
      for (final value in _box.values) {
        if (value is! Map) {
          throw const FormatException('Invalid budget entry.');
        }
        budgets.add(BudgetModel.fromJson(Map<String, dynamic>.from(value)));
      }
      budgets.sort((a, b) => a.category.compareTo(b.category));
      return List<BudgetModel>.unmodifiable(budgets);
    } catch (_) {
      throw const CacheException(
        'Unable to read budgets from local storage.',
        code: 'cache_read_failed',
      );
    }
  }

  @override
  Future<void> saveBudget(BudgetModel budget) async {
    try {
      await _box.put(budget.id, budget.toJson());
    } catch (_) {
      throw const CacheException(
        'Unable to save the budget locally.',
        code: 'cache_write_failed',
      );
    }
  }

  @override
  Future<void> deleteBudget(String id) async {
    try {
      await _box.delete(id);
    } catch (_) {
      throw const CacheException(
        'Unable to delete the budget locally.',
        code: 'cache_delete_failed',
      );
    }
  }
}
