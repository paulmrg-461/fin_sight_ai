import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/debt_repository.dart';

/// Deletes a debt by id.
@lazySingleton
class DeleteDebtUseCase implements UseCase<void, String> {
  const DeleteDebtUseCase(this._repository);

  final DebtRepository _repository;

  @override
  Future<Result<void>> call(String id) async {
    if (id.trim().isEmpty) {
      return const Left(
        ValidationFailure('Debt id is required.', code: 'missing_id'),
      );
    }
    return _repository.deleteDebt(id);
  }
}
