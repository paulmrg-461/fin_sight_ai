import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/receivable_entity.dart';
import '../repositories/receivable_repository.dart';

/// Returns every receivable ordered for display.
@lazySingleton
class GetReceivablesUseCase
    implements UseCase<List<ReceivableEntity>, NoParams> {
  const GetReceivablesUseCase(this._repository);

  final ReceivableRepository _repository;

  @override
  ResultFuture<List<ReceivableEntity>> call(NoParams params) =>
      _repository.getReceivables();
}
