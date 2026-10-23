import 'package:equatable/equatable.dart';

import '../../domain/entities/receipt_entity.dart';

/// Base event for the OCR feature.
sealed class OcrEvent extends Equatable {
  const OcrEvent();

  @override
  List<Object?> get props => const [];
}

/// Loads saved receipts.
final class LoadReceipts extends OcrEvent {
  const LoadReceipts();
}

/// Runs OCR on an image picked by the user.
final class ScanReceipt extends OcrEvent {
  const ScanReceipt(this.imagePath);

  final String imagePath;

  @override
  List<Object?> get props => [imagePath];
}

/// Persists an edited or scanned receipt.
///
/// When [createTransaction] is true, an expense transaction is created from
/// the receipt total using the catalog [category].
final class SaveReceipt extends OcrEvent {
  const SaveReceipt(
    this.receipt, {
    this.createTransaction = false,
    this.category,
  });

  final ReceiptEntity receipt;
  final bool createTransaction;
  final String? category;

  @override
  List<Object?> get props => [receipt, createTransaction, category];
}
