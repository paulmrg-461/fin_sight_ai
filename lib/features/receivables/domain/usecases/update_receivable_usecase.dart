import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../core/utils/clock.dart';
import '../entities/receivable_entity.dart';
import '../repositories/receivable_repository.dart';

/// Input for [UpdateReceivableUseCase].
class UpdateReceivableParams {
  const UpdateReceivableParams({
    required this.id,
    required this.debtorName,
    required this.totalAmount,
    required this.dateLent,
    this.dueDate,
    this.notes,
  });

  final String id;
  final String debtorName;
  final double totalAmount;
  final DateTime dateLent;
  final DateTime? dueDate;
  final String? notes;
}

/// Updates the debtor, dates, notes, and (before any payment) the amount.
@lazySingleton
class UpdateReceivableUseCase
    implements UseCase<ReceivableEntity, UpdateReceivableParams> {
  UpdateReceivableUseCase(this._repository, {this.clock = const Clock()});

  final ReceivableRepository _repository;
  final Clock clock;

  @override
  Future<Result<ReceivableEntity>> call(UpdateReceivableParams params) async {
    if (params.id.trim().isEmpty) {
      return const Left(
        ValidationFailure('Receivable id is required.', code: 'missing_id'),
      );
    }

    final debtorName = params.debtorName.trim();
    if (debtorName.isEmpty) {
      return const Left(
        ValidationFailure('Debtor name is required.', code: 'debtor_required'),
      );
    }
    if (debtorName.length > AppConstants.maxDebtorNameLength) {
      return const Left(
        ValidationFailure('Debtor name is too long.', code: 'debtor_too_long'),
      );
    }
    if (!params.totalAmount.isFinite || params.totalAmount <= 0) {
      return const Left(
        ValidationFailure(
          'Amount lent must be greater than zero.',
          code: 'invalid_amount',
        ),
      );
    }

    final notes = params.notes?.trim() ?? '';
    if (notes.length > AppConstants.maxNoteLength) {
      return const Left(
        ValidationFailure('Notes are too long.', code: 'notes_too_long'),
      );
    }

    final dateLent = _calendarDate(params.dateLent);
    final dueDate = params.dueDate == null
        ? null
        : _calendarDate(params.dueDate!);
    if (dueDate != null && dueDate.isBefore(dateLent)) {
      return const Left(
        ValidationFailure(
          'The due date cannot be before the date lent.',
          code: 'invalid_due_date',
        ),
      );
    }

    final result = await _repository.getReceivables();
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      return Left(failure);
    }

    final receivables = result.getOrElse((_) => const <ReceivableEntity>[]);
    ReceivableEntity? existing;
    for (final receivable in receivables) {
      if (receivable.id == params.id) {
        existing = receivable;
        break;
      }
    }
    if (existing == null) {
      return const Left(
        ValidationFailure(
          'Receivable not found.',
          code: 'receivable_not_found',
        ),
      );
    }

    final total = double.parse(params.totalAmount.toStringAsFixed(2));
    final hasPayments = existing.paymentHistory.isNotEmpty;
    if (hasPayments && (total - existing.totalAmount).abs() > 0.004) {
      return const Left(
        ValidationFailure(
          'The amount cannot change after payments were received.',
          code: 'amount_locked',
        ),
      );
    }

    final remaining = hasPayments ? existing.remainingAmount : total;
    final updated = existing.copyWith(
      debtorName: debtorName,
      totalAmount: total,
      remainingAmount: remaining,
      dateLent: dateLent,
      dueDate: dueDate,
      notes: notes,
      status: remaining <= 0 ? ReceivableStatus.paid : ReceivableStatus.active,
      updatedAt: clock.now(),
    );

    return _repository.updateReceivable(updated);
  }

  DateTime _calendarDate(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
