import '../models/debt_model.dart';

/// Local persistence contract for debts.
abstract interface class DebtLocalDataSource {
  Future<List<DebtModel>> getDebts();

  /// Returns active and soft-deleted records (used by sync merges).
  Future<List<DebtModel>> getAllDebts();

  /// Inserts [debt] or replaces the record with the same id.
  Future<void> saveDebt(DebtModel debt);

  Future<void> deleteDebt(String id);

  /// Hard-deletes tombstones older than [before] and returns the count.
  Future<int> purgeTombstones(DateTime before);
}
