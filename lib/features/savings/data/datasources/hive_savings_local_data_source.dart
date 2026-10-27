import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/savings_goal_model.dart';
import 'savings_local_data_source.dart';

class HiveSavingsLocalDataSource implements SavingsLocalDataSource {
  const HiveSavingsLocalDataSource(this._box);

  final Box<dynamic> _box;

  @override
  Future<List<SavingsGoalModel>> getGoals() async {
    final goals = await getAllGoals();
    return List<SavingsGoalModel>.unmodifiable(
      goals.where((goal) => !goal.isDeleted),
    );
  }

  @override
  Future<List<SavingsGoalModel>> getAllGoals() async {
    try {
      final goals = <SavingsGoalModel>[];
      for (final value in _box.values) {
        if (value is! Map) {
          continue;
        }
        try {
          goals.add(
            SavingsGoalModel.fromJson(Map<String, dynamic>.from(value)),
          );
        } on FormatException {
          // Skip corrupted rows.
        }
      }
      goals.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return List<SavingsGoalModel>.unmodifiable(goals);
    } catch (_) {
      throw const CacheException(
        'Unable to read savings goals.',
        code: 'savings_read_failed',
      );
    }
  }

  @override
  Future<void> saveGoal(SavingsGoalModel goal) async {
    try {
      await _box.put(goal.id, goal.toJson());
    } catch (_) {
      throw const CacheException(
        'Unable to save the savings goal.',
        code: 'savings_write_failed',
      );
    }
  }

  @override
  Future<void> deleteGoal(String id) async {
    try {
      await _box.delete(id);
    } catch (_) {
      throw const CacheException(
        'Unable to delete the savings goal.',
        code: 'savings_delete_failed',
      );
    }
  }

  @override
  Future<int> purgeTombstones(DateTime before) async {
    try {
      final keys = <dynamic>[];
      for (final key in _box.keys) {
        final value = _box.get(key);
        if (value is! Map) {
          continue;
        }
        final model = SavingsGoalModel.fromJson(
          Map<String, dynamic>.from(value),
        );
        final deletedAt = model.deletedAt;
        if (deletedAt != null && deletedAt.isBefore(before)) {
          keys.add(key);
        }
      }
      if (keys.isEmpty) {
        return 0;
      }
      await _box.deleteAll(keys);
      return keys.length;
    } catch (_) {
      throw const CacheException(
        'Unable to purge savings goal tombstones.',
        code: 'savings_purge_failed',
      );
    }
  }
}
