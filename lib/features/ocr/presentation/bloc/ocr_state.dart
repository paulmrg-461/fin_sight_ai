import 'package:equatable/equatable.dart';

import '../../domain/entities/receipt_entity.dart';

/// Base state for the OCR feature.
sealed class OcrState extends Equatable {
  const OcrState();

  @override
  List<Object?> get props => const [];
}

final class OcrInitial extends OcrState {
  const OcrInitial();
}

final class OcrLoading extends OcrState {
  const OcrLoading();
}

final class OcrReceiptsLoaded extends OcrState {
  const OcrReceiptsLoaded(this.receipts);

  final List<ReceiptEntity> receipts;

  @override
  List<Object?> get props => [receipts];
}

final class OcrEmpty extends OcrState {
  const OcrEmpty();
}

final class OcrScanning extends OcrState {
  const OcrScanning();
}

final class OcrScanSuccess extends OcrState {
  const OcrScanSuccess(this.receipt);

  final ReceiptEntity receipt;

  @override
  List<Object?> get props => [receipt];
}

final class OcrSaving extends OcrState {
  const OcrSaving();
}

final class OcrSaved extends OcrState {
  const OcrSaved(this.receipt);

  final ReceiptEntity receipt;

  @override
  List<Object?> get props => [receipt];
}

final class OcrFailure extends OcrState {
  const OcrFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
