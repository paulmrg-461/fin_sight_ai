import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../debts/domain/entities/debt_entity.dart';
import '../../../debts/domain/repositories/debt_repository.dart';
import '../entities/committed_cashflow.dart';
import '../entities/scheduled_payment_entity.dart';
import '../repositories/scheduled_payment_repository.dart';
import '../services/schedule_calculator.dart';

/// Projection window for [GetCommittedCashflowUseCase].
class CommittedCashflowParams {
  const CommittedCashflowParams({required this.from, required this.days});

  final DateTime from;
  final int days;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommittedCashflowParams &&
          other.from == from &&
          other.days == days;

  @override
  int get hashCode => Object.hash(from, days);
}

/// Projects scheduled expenses and debt minimums already committed.
@lazySingleton
class GetCommittedCashflowUseCase
    implements UseCase<CommittedCashflow, CommittedCashflowParams> {
  const GetCommittedCashflowUseCase(this._payments, this._debts);

  static const int minDays = 1;
  static const int maxDays = 365;
  static const int maxOccurrencesPerSource = 100;

  final ScheduledPaymentRepository _payments;
  final DebtRepository _debts;

  @override
  Future<Result<CommittedCashflow>> call(CommittedCashflowParams params) async {
    if (params.days < minDays || params.days > maxDays) {
      return const Left(
        ValidationFailure(
          'The projection window must be between 1 and 365 days.',
          code: 'invalid_projection_window',
        ),
      );
    }

    final start = ScheduleCalculator.dateOnly(params.from);
    final end = start.add(Duration(days: params.days));

    final paymentsResult = await _payments.getPayments();
    final failure = paymentsResult.getLeft().toNullable();
    if (failure != null) {
      return Left(failure);
    }

    final debtsResult = await _debts.getDebts();
    final debtsFailure = debtsResult.getLeft().toNullable();
    if (debtsFailure != null) {
      return Left(debtsFailure);
    }

    final committed =
        <CommittedPayment>[
          ..._fromSchedules(
            paymentsResult.getOrElse((_) => const <ScheduledPaymentEntity>[]),
            start: start,
            end: end,
          ),
          ..._fromDebts(
            debtsResult.getOrElse((_) => const <DebtEntity>[]),
            start: start,
            end: end,
          ),
        ]..sort((a, b) {
          final byDate = a.date.compareTo(b.date);
          return byDate != 0 ? byDate : a.name.compareTo(b.name);
        });

    return Right(
      CommittedCashflow(
        start: start,
        end: end,
        payments: List<CommittedPayment>.unmodifiable(committed),
      ),
    );
  }

  Iterable<CommittedPayment> _fromSchedules(
    List<ScheduledPaymentEntity> schedules, {
    required DateTime start,
    required DateTime end,
  }) sync* {
    for (final schedule in schedules) {
      // Income schedules feed expected-income summaries, not committed outflow.
      if (!schedule.isActive || !schedule.isExpense) {
        continue;
      }

      var due = ScheduleCalculator.dateOnly(schedule.nextDueDate);
      if (due.isBefore(start)) {
        due = ScheduleCalculator.advancePast(
          current: due,
          frequency: schedule.frequency,
          dayOfMonth: schedule.dayOfMonth,
          cutoff: start.subtract(const Duration(days: 1)),
        );
      }

      var occurrences = 0;
      while (!due.isAfter(end) && occurrences < maxOccurrencesPerSource) {
        yield CommittedPayment(
          date: due,
          name: schedule.name,
          amount: schedule.amount,
          category: schedule.category,
          source: CommittedSource.scheduledPayment,
        );
        due = ScheduleCalculator.advanceOnce(
          current: due,
          frequency: schedule.frequency,
          dayOfMonth: schedule.dayOfMonth,
        );
        occurrences++;
      }
    }
  }

  Iterable<CommittedPayment> _fromDebts(
    List<DebtEntity> debts, {
    required DateTime start,
    required DateTime end,
  }) sync* {
    for (final debt in debts) {
      if (debt.status != DebtStatus.active || debt.isPaid) {
        continue;
      }

      var due = ScheduleCalculator.dateOnly(debt.dueDate);
      while (due.isBefore(start)) {
        due = ScheduleCalculator.advanceOnce(
          current: due,
          frequency: PaymentFrequency.monthly,
          dayOfMonth: debt.dueDate.day,
        );
      }

      var occurrences = 0;
      while (!due.isAfter(end) && occurrences < maxOccurrencesPerSource) {
        yield CommittedPayment(
          date: due,
          name: debt.creditorName,
          amount: debt.minimumPayment,
          category: '',
          source: CommittedSource.debtMinimum,
        );
        due = ScheduleCalculator.advanceOnce(
          current: due,
          frequency: PaymentFrequency.monthly,
          dayOfMonth: debt.dueDate.day,
        );
        occurrences++;
      }
    }
  }
}
