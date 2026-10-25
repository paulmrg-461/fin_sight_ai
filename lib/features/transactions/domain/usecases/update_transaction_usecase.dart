import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../core/utils/calendar_date.dart';
import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

/// Input for [UpdateTransactionUseCase].
class UpdateTransactionParams {
  const UpdateTransactionParams({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.date,
    this.receiptImagePath,
    this.walletId,
  });

  final String id;
  final double amount;
  final TransactionType type;
  final String category;
  final String description;
  final DateTime date;
  final String? receiptImagePath;
  final String? walletId;
}

/// Validates and updates an existing transaction without changing its id.
@lazySingleton
class UpdateTransactionUseCase
    implements UseCase<TransactionEntity, UpdateTransactionParams> {
  const UpdateTransactionUseCase(this._repository);

  final TransactionRepository _repository;

  @override
  Future<Result<TransactionEntity>> call(UpdateTransactionParams params) async {
    final id = params.id.trim();
    if (id.isEmpty) {
      return const Left(
        ValidationFailure('Transaction id is required.', code: 'missing_id'),
      );
    }
    if (!params.amount.isFinite || params.amount <= 0) {
      return const Left(
        ValidationFailure(
          'Amount must be greater than zero.',
          code: 'invalid_amount',
        ),
      );
    }

    final category = params.category.trim();
    if (category.isEmpty) {
      return const Left(
        ValidationFailure('Category is required.', code: 'missing_category'),
      );
    }

    final description = params.description.trim();
    if (description.length > AppConstants.maxNoteLength) {
      return const Left(
        ValidationFailure(
          'Description must be 500 characters or fewer.',
          code: 'description_too_long',
        ),
      );
    }

    final receiptImagePath = params.receiptImagePath?.trim();
    final walletId = params.walletId?.trim();

    return _repository.updateTransaction(
      TransactionEntity(
        id: id,
        amount: double.parse(params.amount.toStringAsFixed(2)),
        type: params.type,
        category: category,
        description: description,
        date: calendarDate(params.date),
        receiptImagePath: receiptImagePath == null || receiptImagePath.isEmpty
            ? null
            : receiptImagePath,
        walletId: walletId == null || walletId.isEmpty ? null : walletId,
      ),
    );
  }
}
