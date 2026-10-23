import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/app_constants.dart';
import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

/// Untrusted input for [AddTransactionUseCase].
class AddTransactionParams {
  const AddTransactionParams({
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.date,
    this.receiptImagePath,
    this.walletId,
    this.id,
  });

  final double amount;
  final TransactionType type;
  final String category;
  final String description;
  final DateTime date;
  final String? receiptImagePath;

  /// Wallet (bank/cash) the transaction belongs to.
  final String? walletId;

  /// Optional explicit id; a UUID v4 is generated when omitted.
  final String? id;
}

/// Validates and records a new transaction.
@lazySingleton
class AddTransactionUseCase
    implements UseCase<TransactionEntity, AddTransactionParams> {
  AddTransactionUseCase(this._repository, {this.uuid = const Uuid()});

  final TransactionRepository _repository;
  final Uuid uuid;

  @override
  Future<Result<TransactionEntity>> call(AddTransactionParams params) async {
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

    final transaction = TransactionEntity(
      id: params.id?.trim().isNotEmpty == true ? params.id!.trim() : uuid.v4(),
      amount: double.parse(params.amount.toStringAsFixed(2)),
      type: params.type,
      category: category,
      description: description,
      date: params.date,
      walletId: params.walletId?.trim().isEmpty == true
          ? null
          : params.walletId?.trim(),
      receiptImagePath: receiptImagePath == null || receiptImagePath.isEmpty
          ? null
          : receiptImagePath,
    );

    return _repository.addTransaction(transaction);
  }
}
