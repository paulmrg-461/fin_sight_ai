import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/receipt_entity.dart';
import '../repositories/receipt_repository.dart';

/// Extracts receipt data from an image.
@lazySingleton
class ScanReceiptUseCase implements UseCase<ReceiptEntity, String> {
  const ScanReceiptUseCase(this._repository);

  final ReceiptRepository _repository;

  @override
  Future<Result<ReceiptEntity>> call(String imagePath) async {
    final path = imagePath.trim();
    if (path.isEmpty) {
      return const Left(
        ValidationFailure(
          'Receipt image path is required.',
          code: 'missing_image',
        ),
      );
    }
    return _repository.scanReceipt(path);
  }
}
