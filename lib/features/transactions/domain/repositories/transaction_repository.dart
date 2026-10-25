import '../../../../core/usecase/usecase.dart';
import '../entities/transaction_entity.dart';

/// Domain contract for transaction persistence and querying.
abstract interface class TransactionRepository {
  /// Persists a new transaction. Returns the stored entity.
  ResultFuture<TransactionEntity> addTransaction(TransactionEntity transaction);

  /// Returns every transaction, newest first.
  ResultFuture<List<TransactionEntity>> getTransactions();

  /// Updates an existing transaction, preserving its id.
  ResultFuture<TransactionEntity> updateTransaction(
    TransactionEntity transaction,
  );

  /// Deletes the transaction with [id]. Succeeds when it does not exist.
  ResultFuture<void> deleteTransaction(String id);

  /// Returns transactions with a date inside `[start, end]`, newest first.
  ResultFuture<List<TransactionEntity>> getTransactionsByDateRange({
    required DateTime start,
    required DateTime end,
  });

  /// Renames the category snapshot on every record using [from].
  ///
  /// Returns the number of updated transactions.
  ResultFuture<int> renameCategory({required String from, required String to});
}
