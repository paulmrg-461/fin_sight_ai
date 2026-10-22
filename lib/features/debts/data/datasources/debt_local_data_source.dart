import '../models/debt_model.dart';

/// Local persistence contract for debts.
abstract interface class DebtLocalDataSource {
  Future<List<DebtModel>> getDebts();

  /// Inserts [debt] or replaces the record with the same id.
  Future<void> saveDebt(DebtModel debt);

  Future<void> deleteDebt(String id);
}
