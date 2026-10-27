import '../models/savings_goal_model.dart';

abstract interface class SavingsLocalDataSource {
  /// Visible goals, excluding tombstones.
  Future<List<SavingsGoalModel>> getGoals();

  /// Every goal, including tombstones, for sync merges.
  Future<List<SavingsGoalModel>> getAllGoals();

  Future<void> saveGoal(SavingsGoalModel goal);

  Future<void> deleteGoal(String id);

  /// Removes tombstones older than [before] and returns the count.
  Future<int> purgeTombstones(DateTime before);
}
