import '../models/receivable_model.dart';

/// Local persistence contract for receivables.
abstract interface class ReceivableLocalDataSource {
  /// Returns every receivable: active first, then paid entries.
  Future<List<ReceivableModel>> getReceivables();

  /// Inserts [receivable] or replaces the record with the same id.
  Future<void> saveReceivable(ReceivableModel receivable);

  /// Permanently removes the receivable and its payment history.
  Future<void> deleteReceivable(String id);
}
