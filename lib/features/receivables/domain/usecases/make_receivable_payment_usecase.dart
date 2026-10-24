import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../core/utils/clock.dart';
import '../entities/receivable_entity.dart';
import '../repositories/receivable_repository.dart';

/// Input for [MakeReceivablePaymentUseCase].
class MakeReceivablePaymentParams {
  const MakeReceivablePaymentParams({
    required this.receivableId,
    required this.amount,
    this.note,
  });

  final String receivableId;
  final double amount;
  final String? note;
}

/// Validates a received payment and records it in the receivable history.
@lazySingleton
class MakeReceivablePaymentUseCase
    implements UseCase<ReceivableEntity, MakeReceivablePaymentParams> {
  MakeReceivablePaymentUseCase(
    this._repository, {
    this.uuid = const Uuid(),
    this.clock = const Clock(),
  });

  final ReceivableRepository _repository;
  final Uuid uuid;
  final Clock clock;

  @override
  Future<Result<ReceivableEntity>> call(
    MakeReceivablePaymentParams params,
  ) async {
    if (params.receivableId.trim().isEmpty) {
      return const Left(
        ValidationFailure('Receivable id is required.', code: 'missing_id'),
      );
    }
    if (!params.amount.isFinite || params.amount <= 0) {
      return const Left(
        ValidationFailure(
          'Payment amount must be greater than zero.',
          code: 'invalid_payment',
        ),
      );
    }

    final note = params.note?.trim();
    if (note != null && note.length > AppConstants.maxNoteLength) {
      return const Left(
        ValidationFailure('Notes are too long.', code: 'notes_too_long'),
      );
    }

    final receivablesResult = await _repository.getReceivables();
    final failure = receivablesResult.getLeft().toNullable();
    if (failure != null) {
      return Left(failure);
    }

    final receivables = receivablesResult.getOrElse(
      (_) => const <ReceivableEntity>[],
    );
    ReceivableEntity? selected;
    for (final receivable in receivables) {
      if (receivable.id == params.receivableId) {
        selected = receivable;
        break;
      }
    }

    if (selected == null) {
      return const Left(
        ValidationFailure(
          'Receivable not found.',
          code: 'receivable_not_found',
        ),
      );
    }
    if (selected.isPaid) {
      return const Left(
        ValidationFailure(
          'This receivable is already paid.',
          code: 'receivable_already_paid',
        ),
      );
    }

    final payment = ReceivablePayment(
      id: uuid.v4(),
      amount: double.parse(params.amount.toStringAsFixed(2)),
      paidAt: clock.now(),
      note: note == null || note.isEmpty ? null : note,
    );

    return _repository.makePayment(params.receivableId, payment);
  }
}
