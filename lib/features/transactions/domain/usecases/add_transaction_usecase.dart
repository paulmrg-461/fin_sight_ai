import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';

/// Untrusted input for [AddTransactionUseCase].
class AddTransactionParams {
  const AddTransactionParams({
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
    this.note = '',
    this.id,
  });

  /// Positive magnitude in the user's display currency.
  final double amount;
  final String category;
  final TransactionType type;
  final DateTime date;
  final String note;

  /// Optional explicit id; a UUID v4 is generated when omitted.
  final String? id;
}

/// Validates and records a new transaction.
@lazySingleton
class AddTransactionUseCase
    implements UseCase<Transaction, AddTransactionParams> {
  AddTransactionUseCase(this._repository, {this.uuid = const Uuid()});

  final TransactionRepository _repository;
  final Uuid uuid;

  static const int _maxNoteLength = 500;

  @override
  Future<Result<Transaction>> call(AddTransactionParams params) async {
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

    final note = params.note.trim();
    if (note.length > _maxNoteLength) {
      return const Left(
        ValidationFailure(
          'Note must be 500 characters or fewer.',
          code: 'note_too_long',
        ),
      );
    }

    final requestedId = params.id?.trim();
    final transaction = Transaction(
      id: requestedId == null || requestedId.isEmpty ? uuid.v4() : requestedId,
      amount: double.parse(params.amount.toStringAsFixed(2)),
      date: params.date,
      category: category,
      type: params.type,
      note: note,
    );

    return _repository.addTransaction(transaction);
  }
}
