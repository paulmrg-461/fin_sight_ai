import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/receipt_entity.dart';
import '../repositories/receipt_repository.dart';

/// Returns every stored receipt, newest first.
@lazySingleton
class GetReceiptsUseCase implements UseCase<List<ReceiptEntity>, NoParams> {
  const GetReceiptsUseCase(this._repository);

  final ReceiptRepository _repository;

  @override
  ResultFuture<List<ReceiptEntity>> call(NoParams params) =>
      _repository.getReceipts();
}
