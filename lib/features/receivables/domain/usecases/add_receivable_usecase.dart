import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../core/utils/clock.dart';
import '../entities/receivable_entity.dart';
import '../repositories/receivable_repository.dart';

/// Untrusted input for [AddReceivableUseCase].
class AddReceivableParams {
  const AddReceivableParams({
    required this.debtorName,
    required this.totalAmount,
    required this.dateLent,
    this.dueDate,
    this.notes,
    this.id,
  });

  final String debtorName;
  final double totalAmount;
  final DateTime dateLent;
  final DateTime? dueDate;
  final String? notes;
  final String? id;
}

/// Validates and records money lent to someone.
@lazySingleton
class AddReceivableUseCase
    implements UseCase<ReceivableEntity, AddReceivableParams> {
  AddReceivableUseCase(
    this._repository, {
    this.uuid = const Uuid(),
    this.clock = const Clock(),
  });

  final ReceivableRepository _repository;
  final Uuid uuid;
  final Clock clock;

  @override
  Future<Result<ReceivableEntity>> call(AddReceivableParams params) async {
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

    final now = clock.now();
    final total = double.parse(params.totalAmount.toStringAsFixed(2));

    final receivable = ReceivableEntity(
      id: params.id?.trim().isNotEmpty == true ? params.id!.trim() : uuid.v4(),
      debtorName: debtorName,
      totalAmount: total,
      remainingAmount: total,
      dateLent: dateLent,
      dueDate: dueDate,
      notes: notes,
      status: ReceivableStatus.active,
      createdAt: now,
      updatedAt: now,
    );

    return _repository.addReceivable(receivable);
  }

  DateTime _calendarDate(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
