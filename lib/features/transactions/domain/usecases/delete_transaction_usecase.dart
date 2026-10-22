import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/transaction_repository.dart';

/// Deletes a transaction by id.
@lazySingleton
class DeleteTransactionUseCase implements UseCase<void, String> {
  const DeleteTransactionUseCase(this._repository);

  final TransactionRepository _repository;

  @override
  Future<Result<void>> call(String id) async {
    if (id.trim().isEmpty) {
      return const Left(
        ValidationFailure('Transaction id is required.', code: 'missing_id'),
      );
    }
    return _repository.deleteTransaction(id);
  }
}
