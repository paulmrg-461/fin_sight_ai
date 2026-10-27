import '../../../../core/usecase/usecase.dart';
import '../entities/savings_goal_entity.dart';

abstract interface class SavingsRepository {
  ResultFuture<List<SavingsGoalEntity>> getGoals();

  ResultFuture<SavingsGoalEntity> addGoal(SavingsGoalEntity goal);

  /// Updates editable fields while preserving id and contributions.
  ResultFuture<SavingsGoalEntity> updateGoal(SavingsGoalEntity goal);

  ResultFuture<SavingsGoalEntity> addContribution(
    String goalId,
    SavingsContribution contribution,
  );

  ResultFuture<void> deleteGoal(String id);
}
