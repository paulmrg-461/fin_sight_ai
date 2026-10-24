import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/receivable_repository.dart';

/// Deletes a receivable and its payment history.
@lazySingleton
class DeleteReceivableUseCase implements UseCase<void, String> {
  const DeleteReceivableUseCase(this._repository);

  final ReceivableRepository _repository;

  @override
  Future<Result<void>> call(String id) async {
    if (id.trim().isEmpty) {
      return const Left(
        ValidationFailure('Receivable id is required.', code: 'missing_id'),
      );
    }
    return _repository.deleteReceivable(id);
  }
}
