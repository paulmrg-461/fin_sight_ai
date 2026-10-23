import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/services/receipt_image_store.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/domain/usecases/add_transaction_usecase.dart';
import '../../domain/usecases/get_receipts_usecase.dart';
import '../../domain/usecases/save_receipt_usecase.dart';
import '../../domain/usecases/scan_receipt_usecase.dart';
import 'ocr_event.dart';
import 'ocr_state.dart';

/// Coordinates receipt scanning, editing, persistence, and expense creation.
@injectable
class OcrBloc extends Bloc<OcrEvent, OcrState> {
  OcrBloc(
    this._scanReceipt,
    this._saveReceipt,
    this._getReceipts,
    this._addTransaction,
    this._imageStore,
  ) : super(const OcrInitial()) {
    on<LoadReceipts>(_onLoad);
    on<ScanReceipt>(_onScan);
    on<SaveReceipt>(_onSave);
  }

  final ScanReceiptUseCase _scanReceipt;
  final SaveReceiptUseCase _saveReceipt;
  final GetReceiptsUseCase _getReceipts;
  final AddTransactionUseCase _addTransaction;
  final ReceiptImageStore _imageStore;

  Future<void> _onLoad(LoadReceipts event, Emitter<OcrState> emit) async {
    emit(const OcrLoading());
    final result = await _getReceipts(const NoParams());
    result.fold(
      (failure) => emit(OcrFailure(failure.message)),
      (receipts) => emit(
        receipts.isEmpty ? const OcrEmpty() : OcrReceiptsLoaded(receipts),
      ),
    );
  }

  Future<void> _onScan(ScanReceipt event, Emitter<OcrState> emit) async {
    emit(const OcrScanning());
    String? persistedPath;
    try {
      persistedPath = await _imageStore.persist(event.imagePath);
      final result = await _scanReceipt(persistedPath);
      final failure = result.getLeft().toNullable();
      if (failure != null) {
        await _imageStore.delete(persistedPath);
        emit(OcrFailure(failure.message));
        return;
      }
      final receipt = result.getOrElse(
        (_) => throw StateError('Unreachable: failure handled above.'),
      );
      emit(OcrScanSuccess(receipt));
    } catch (_) {
      if (persistedPath != null) {
        await _imageStore.delete(persistedPath);
      }
      emit(const OcrFailure('Unable to prepare the receipt image.'));
    }
  }

  Future<void> _onSave(SaveReceipt event, Emitter<OcrState> emit) async {
    emit(const OcrSaving());
    final result = await _saveReceipt(event.receipt);
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      emit(OcrFailure(failure.message));
      return;
    }

    final saved = result.getOrElse((_) => event.receipt);
    if (event.createTransaction) {
      await _addTransaction(
        AddTransactionParams(
          id: saved.id,
          amount: saved.totalAmount,
          type: TransactionType.expense,
          category: 'Receipts',
          description: saved.merchantName,
          date: saved.date,
          receiptImagePath: saved.imagePath,
        ),
      );
    }

    emit(OcrSaved(saved));
  }
}
