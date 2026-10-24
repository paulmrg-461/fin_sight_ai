import '../../../../core/usecase/usecase.dart';
import '../entities/receivable_entity.dart';

/// Domain contract for money lent to other people. Local-only for now.
abstract interface class ReceivableRepository {
  ResultFuture<ReceivableEntity> addReceivable(ReceivableEntity receivable);

  ResultFuture<ReceivableEntity> updateReceivable(ReceivableEntity receivable);

  /// Applies [payment] to the receivable with [receivableId].
  ///
  /// The amount is clamped to the remaining balance and a full payment marks
  /// the receivable as paid. Implementations reject unknown or settled
  /// receivables with a validation failure.
  ResultFuture<ReceivableEntity> makePayment(
    String receivableId,
    ReceivablePayment payment,
  );

  /// Returns every receivable: active first, then paid entries.
  ResultFuture<List<ReceivableEntity>> getReceivables();

  /// Deletes the receivable and its payment history. Succeeds when missing.
  ResultFuture<void> deleteReceivable(String id);
}
