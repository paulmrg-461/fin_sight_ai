import '../../../../core/usecase/usecase.dart';
import '../entities/transaction.dart';

/// Contract owned by the domain and implemented by the data layer.
abstract interface class TransactionRepository {
  /// Returns every locally stored transaction, newest first.
  ResultFuture<List<Transaction>> getTransactions();

  /// Persists [transaction] locally, then attempts a best-effort remote sync.
  ///
  /// The returned entity reflects the sync outcome through `isSynced`. A remote
  /// failure is not a repository failure: the local write already succeeded.
  ResultFuture<Transaction> addTransaction(Transaction transaction);
}
