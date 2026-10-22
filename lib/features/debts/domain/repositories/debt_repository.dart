import '../../../../core/usecase/usecase.dart';
import '../entities/debt_entity.dart';

/// Domain contract for debt persistence and payoff projection.
abstract interface class DebtRepository {
  ResultFuture<DebtEntity> addDebt(DebtEntity debt);

  ResultFuture<DebtEntity> updateDebt(DebtEntity debt);

  /// Deletes the debt with [id]. Succeeds when it does not exist.
  ResultFuture<void> deleteDebt(String id);

  /// Returns every debt, ordered by due date.
  ResultFuture<List<DebtEntity>> getDebts();

  /// Projects the payoff date using [monthlyPayment] or the minimum payment.
  ResultFuture<DateTime?> calculatePayoffDate(
    DebtEntity debt, {
    double? monthlyPayment,
  });
}
