import '../models/receipt_model.dart';

/// Local persistence contract for scanned receipts.
abstract interface class ReceiptLocalDataSource {
  Future<List<ReceiptModel>> getReceipts();

  /// Inserts [receipt] or replaces the record with the same id.
  Future<void> saveReceipt(ReceiptModel receipt);
}
