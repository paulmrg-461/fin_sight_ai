import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

/// Returns every transaction, newest first.
@lazySingleton
class GetTransactionsUseCase
    implements UseCase<List<TransactionEntity>, NoParams> {
  const GetTransactionsUseCase(this._repository);

  final TransactionRepository _repository;

  @override
  ResultFuture<List<TransactionEntity>> call(NoParams params) =>
      _repository.getTransactions();
}
