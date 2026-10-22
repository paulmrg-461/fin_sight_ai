import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/debt_entity.dart';
import '../repositories/debt_repository.dart';

/// Returns every debt ordered by due date.
@lazySingleton
class GetDebtsUseCase implements UseCase<List<DebtEntity>, NoParams> {
  const GetDebtsUseCase(this._repository);

  final DebtRepository _repository;

  @override
  ResultFuture<List<DebtEntity>> call(NoParams params) =>
      _repository.getDebts();
}
