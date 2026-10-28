import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/sync/sync_operation.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/clock.dart';
import '../../domain/entities/receipt_entity.dart';
import '../../domain/repositories/receipt_repository.dart';
import '../datasources/ocr_data_source.dart';
import '../datasources/receipt_local_data_source.dart';
import '../models/receipt_model.dart';
import '../parsers/receipt_parser.dart';

/// Coordinates OCR extraction, parsing, and local persistence.
@LazySingleton(as: ReceiptRepository)
class ReceiptRepositoryImpl implements ReceiptRepository {
  const ReceiptRepositoryImpl(
    this._localDataSource,
    this._ocrDataSource, {
    this.syncQueue,
    this.uuid = const Uuid(),
    this.clock = const Clock(),
  });

  static const ReceiptParser _parser = ReceiptParser();

  final ReceiptLocalDataSource _localDataSource;
  final OcrDataSource _ocrDataSource;
  final SyncQueue? syncQueue;
  final Uuid uuid;
  final Clock clock;

  @override
  ResultFuture<ReceiptEntity> scanReceipt(String imagePath) async {
    try {
      final rawText = await _ocrDataSource.recognizeText(imagePath);
      if (rawText.trim().isEmpty) {
        return const Left(
          ValidationFailure(
            'No text was detected in the receipt image.',
            code: 'ocr_empty_text',
          ),
        );
      }

      final parsed = _parser.parse(rawText, now: clock.now());
      return Right(
        ReceiptEntity(
          id: uuid.v4(),
          imagePath: imagePath,
          merchantName: parsed.merchantName,
          date: parsed.date,
          totalAmount: parsed.totalAmount,
          items: parsed.items,
          currency: parsed.currency,
        ),
      );
    } on OcrException catch (exception) {
      return Left(
        ServerFailure(
          'Unable to scan the receipt.',
          code: exception.code ?? 'ocr_failed',
        ),
      );
    } catch (_) {
      return const Left(
        ServerFailure('Unable to scan the receipt.', code: 'ocr_failed'),
      );
    }
  }

  @override
  ResultFuture<ReceiptEntity> saveReceipt(ReceiptEntity receipt) async {
    try {
      final model = ReceiptModel.fromEntity(
        receipt.copyWith(updatedAt: clock.now(), isSynced: false),
      );
      await _localDataSource.saveReceipt(model);
      await _enqueue(model);
      return Right(model.toEntity());
    } on CacheException catch (exception) {
      return Left(_toCacheFailure(exception));
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to save the receipt locally.',
          code: 'cache_write_failed',
        ),
      );
    }
  }

  @override
  ResultFuture<List<ReceiptEntity>> getReceipts() async {
    try {
      final models = await _localDataSource.getReceipts();
      return Right(
        List<ReceiptEntity>.unmodifiable(
          models.map((model) => model.toEntity()),
        ),
      );
    } on CacheException catch (exception) {
      return Left(_toCacheFailure(exception));
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to read local receipts.',
          code: 'cache_read_failed',
        ),
      );
    }
  }

  Future<void> _enqueue(ReceiptModel model) async {
    final queue = syncQueue;
    if (queue == null) {
      return;
    }
    try {
      await queue.enqueue(
        SyncOperation.upsert(
          entityType: SyncEntityType.receipt,
          entityId: model.id,
          payload: model.toJson(),
          queuedAt: clock.now(),
        ),
      );
    } catch (_) {
      // The local write is authoritative; a queue failure must not lose it.
    }
  }

  CacheFailure _toCacheFailure(CacheException exception) =>
      CacheFailure(exception.message, code: exception.code);
}
