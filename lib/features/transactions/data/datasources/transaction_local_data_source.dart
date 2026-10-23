import '../models/transaction_model.dart';

/// Local persistence contract for transactions.
///
/// Implementations throw `CacheException` on infrastructure failures so the
/// repository can map them to `CacheFailure`.
abstract interface class TransactionLocalDataSource {
  Future<List<TransactionModel>> getTransactions();

  /// Inserts [transaction] or replaces the record with the same id.
  Future<void> saveTransaction(TransactionModel transaction);

  Future<void> deleteTransaction(String id);

  /// Returns records inside the inclusive `[start, end]` range.
  Future<List<TransactionModel>> getTransactionsByDateRange({
    required DateTime start,
    required DateTime end,
  });

  /// Hard-deletes tombstones older than [before] and returns the count.
  Future<int> purgeTombstones(DateTime before);
}
