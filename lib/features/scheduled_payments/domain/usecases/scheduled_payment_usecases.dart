import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/clock.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../entities/scheduled_payment_entity.dart';
import '../repositories/scheduled_payment_repository.dart';
import '../services/schedule_calculator.dart';

@lazySingleton
class GetScheduledPaymentsUseCase
    implements UseCase<List<ScheduledPaymentEntity>, NoParams> {
  const GetScheduledPaymentsUseCase(this._repository);

  final ScheduledPaymentRepository _repository;

  @override
  ResultFuture<List<ScheduledPaymentEntity>> call(NoParams params) =>
      _repository.getPayments();
}

/// Untrusted input for a new scheduled payment.
class AddScheduledPaymentParams {
  const AddScheduledPaymentParams({
    required this.name,
    required this.amount,
    required this.category,
    required this.nextDueDate,
    this.type = TransactionType.expense,
    this.frequency = PaymentFrequency.monthly,
    this.walletId,
    this.notes = '',
  });

  final String name;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime nextDueDate;
  final PaymentFrequency frequency;
  final String? walletId;
  final String notes;
}

@lazySingleton
class AddScheduledPaymentUseCase
    implements UseCase<ScheduledPaymentEntity, AddScheduledPaymentParams> {
  AddScheduledPaymentUseCase(
    this._repository, {
    this.uuid = const Uuid(),
    this.clock = const Clock(),
  });

  final ScheduledPaymentRepository _repository;
  final Uuid uuid;
  final Clock clock;

  @override
  Future<Result<ScheduledPaymentEntity>> call(
    AddScheduledPaymentParams params,
  ) async {
    final name = params.name.trim();
    if (name.isEmpty) {
      return const Left(
        ValidationFailure(
          'Payment name is required.',
          code: 'missing_payment_name',
        ),
      );
    }

    if (!params.amount.isFinite || params.amount <= 0) {
      return const Left(
        ValidationFailure(
          'Amount must be greater than zero.',
          code: 'invalid_amount',
        ),
      );
    }

    final category = params.category.trim();
    if (category.isEmpty) {
      return const Left(
        ValidationFailure('Category is required.', code: 'missing_category'),
      );
    }

    final notes = params.notes.trim();
    if (notes.length > 500) {
      return const Left(
        ValidationFailure(
          'Notes must be 500 characters or fewer.',
          code: 'notes_too_long',
        ),
      );
    }

    final dueDate = ScheduleCalculator.dateOnly(params.nextDueDate);
    final walletId = params.walletId?.trim();

    final payment = ScheduledPaymentEntity(
      id: uuid.v4(),
      name: name,
      amount: double.parse(params.amount.toStringAsFixed(2)),
      type: params.type,
      category: category,
      frequency: params.frequency,
      nextDueDate: dueDate,
      dayOfMonth: dueDate.day,
      walletId: walletId == null || walletId.isEmpty ? null : walletId,
      notes: notes,
      createdAt: clock.now(),
      updatedAt: clock.now(),
    );
    return _repository.addPayment(payment);
  }
}

class SetScheduledPaymentActiveParams {
  const SetScheduledPaymentActiveParams({
    required this.id,
    required this.isActive,
  });

  final String id;
  final bool isActive;
}

@lazySingleton
class SetScheduledPaymentActiveUseCase
    implements
        UseCase<ScheduledPaymentEntity, SetScheduledPaymentActiveParams> {
  const SetScheduledPaymentActiveUseCase(this._repository);

  final ScheduledPaymentRepository _repository;

  @override
  ResultFuture<ScheduledPaymentEntity> call(
    SetScheduledPaymentActiveParams params,
  ) {
    if (params.id.trim().isEmpty) {
      return Future.value(
        const Left(
          ValidationFailure('Payment id is required.', code: 'missing_id'),
        ),
      );
    }
    return _repository.setActive(params.id.trim(), params.isActive);
  }
}

@lazySingleton
class DeleteScheduledPaymentUseCase implements UseCase<void, String> {
  const DeleteScheduledPaymentUseCase(this._repository);

  final ScheduledPaymentRepository _repository;

  @override
  ResultFuture<void> call(String id) {
    if (id.trim().isEmpty) {
      return Future.value(
        const Left(
          ValidationFailure('Payment id is required.', code: 'missing_id'),
        ),
      );
    }
    return _repository.deletePayment(id.trim());
  }
}

@lazySingleton
class PayScheduledPaymentUseCase
    implements UseCase<ScheduledPaymentRun, String> {
  const PayScheduledPaymentUseCase(
    this._repository, {
    this.clock = const Clock(),
  });

  final ScheduledPaymentRepository _repository;
  final Clock clock;

  @override
  ResultFuture<ScheduledPaymentRun> call(String id) {
    if (id.trim().isEmpty) {
      return Future.value(
        const Left(
          ValidationFailure('Payment id is required.', code: 'missing_id'),
        ),
      );
    }
    return _repository.payNow(id.trim(), clock.now());
  }
}

@lazySingleton
class ProcessDueScheduledPaymentsUseCase
    implements UseCase<ScheduledPaymentRun, NoParams> {
  const ProcessDueScheduledPaymentsUseCase(
    this._repository, {
    this.clock = const Clock(),
  });

  final ScheduledPaymentRepository _repository;
  final Clock clock;

  @override
  ResultFuture<ScheduledPaymentRun> call(NoParams params) =>
      _repository.processDue(clock.now());
}
