import '../models/savings_goal_model.dart';

abstract interface class SavingsLocalDataSource {
  Future<List<SavingsGoalModel>> getGoals();

  Future<void> saveGoal(SavingsGoalModel goal);

  Future<void> deleteGoal(String id);
}
