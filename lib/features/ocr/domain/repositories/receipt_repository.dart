import '../../../../core/usecase/usecase.dart';
import '../entities/receipt_entity.dart';

/// Domain contract for receipt scanning and persistence.
abstract interface class ReceiptRepository {
  /// Runs OCR on [imagePath] and extracts a receipt draft.
  ResultFuture<ReceiptEntity> scanReceipt(String imagePath);

  /// Persists [receipt] and returns the stored entity.
  ResultFuture<ReceiptEntity> saveReceipt(ReceiptEntity receipt);

  /// Returns every saved receipt, newest first.
  ResultFuture<List<ReceiptEntity>> getReceipts();
}
