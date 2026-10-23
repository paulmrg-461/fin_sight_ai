import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/receipt_entity.dart';
import '../repositories/receipt_repository.dart';

/// Validates and persists a receipt.
@lazySingleton
class SaveReceiptUseCase implements UseCase<ReceiptEntity, ReceiptEntity> {
  SaveReceiptUseCase(this._repository, {this.uuid = const Uuid()});

  final ReceiptRepository _repository;
  final Uuid uuid;

  @override
  Future<Result<ReceiptEntity>> call(ReceiptEntity receipt) async {
    final imagePath = receipt.imagePath.trim();
    if (imagePath.isEmpty) {
      return const Left(
        ValidationFailure(
          'Receipt image path is required.',
          code: 'missing_image',
        ),
      );
    }

    final merchantName = receipt.merchantName.trim();
    if (merchantName.isEmpty) {
      return const Left(
        ValidationFailure(
          'Merchant name is required.',
          code: 'invalid_merchant',
        ),
      );
    }

    if (!receipt.totalAmount.isFinite || receipt.totalAmount <= 0) {
      return const Left(
        ValidationFailure(
          'Receipt total must be greater than zero.',
          code: 'invalid_total',
        ),
      );
    }

    final currency = receipt.currency.trim().toUpperCase();
    if (!RegExp(r'^[A-Z]{3}$').hasMatch(currency)) {
      return const Left(
        ValidationFailure(
          'Currency must be a 3-letter ISO code.',
          code: 'invalid_currency',
        ),
      );
    }

    final items = <ReceiptItem>[];
    for (final item in receipt.items) {
      final name = item.name.trim();
      if (name.isEmpty) {
        return const Left(
          ValidationFailure(
            'Every receipt item needs a name.',
            code: 'invalid_item_name',
          ),
        );
      }
      if (!item.quantity.isFinite || item.quantity <= 0) {
        return const Left(
          ValidationFailure(
            'Item quantity must be greater than zero.',
            code: 'invalid_item_quantity',
          ),
        );
      }
      if (!item.price.isFinite || item.price < 0) {
        return const Left(
          ValidationFailure(
            'Item price cannot be negative.',
            code: 'invalid_item_price',
          ),
        );
      }
      items.add(
        item.copyWith(
          name: name,
          price: double.parse(item.price.toStringAsFixed(2)),
        ),
      );
    }

    final id = receipt.id.trim();
    final normalized = receipt.copyWith(
      id: id.isEmpty ? uuid.v4() : id,
      imagePath: imagePath,
      merchantName: merchantName,
      totalAmount: double.parse(receipt.totalAmount.toStringAsFixed(2)),
      currency: currency,
      items: List<ReceiptItem>.unmodifiable(items),
    );

    return _repository.saveReceipt(normalized);
  }
}
