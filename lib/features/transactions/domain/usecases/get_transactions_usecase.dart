import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/transaction.dart';
import '../repositories/transaction_repository.dart';

/// Returns all transactions, newest first.
@lazySingleton
class GetTransactionsUseCase implements UseCase<List<Transaction>, NoParams> {
  const GetTransactionsUseCase(this._repository);

  final TransactionRepository _repository;

  @override
  ResultFuture<List<Transaction>> call(NoParams params) =>
      _repository.getTransactions();
}
