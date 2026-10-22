import '../models/transaction_model.dart';

/// Local persistence contract for transactions.
///
/// Implementations must throw `CacheException` on infrastructure failures so
/// the repository can map them to `CacheFailure`.
abstract interface class TransactionLocalDataSource {
  Future<List<TransactionModel>> getTransactions();

  /// Inserts [transaction] or replaces the existing record with the same id.
  Future<void> saveTransaction(TransactionModel transaction);
}
