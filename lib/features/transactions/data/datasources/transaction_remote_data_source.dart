import '../models/transaction_model.dart';

/// Remote synchronization contract for transactions (Supabase in production).
abstract interface class TransactionRemoteDataSource {
  /// Returns `true` when the backend accepted the record.
  ///
  /// Implementations must not throw for transient connectivity problems:
  /// returning `false` keeps the record pending for the next sync pass.
  Future<bool> uploadTransaction(TransactionModel transaction);
}
