import '../../../../core/domain/entity.dart';

/// Lifecycle of a debt.
enum DebtStatus { active, paid }

/// A single payment applied to a debt.
class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.amount,
    required this.paidAt,
  });

  final String id;
  final double amount;
  final DateTime paidAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentRecord &&
          other.id == id &&
          other.amount == amount &&
          other.paidAt == paidAt;

  @override
  int get hashCode => Object.hash(id, amount, paidAt);

  @override
  String toString() =>
      'PaymentRecord(id: $id, amount: $amount, paidAt: $paidAt)';
}

/// Pure domain entity for a debt and its repayment progress.
class DebtEntity extends Entity {
  const DebtEntity({
    required this.id,
    required this.creditorName,
    required this.totalAmount,
    required this.remainingAmount,
    required this.interestRate,
    required this.minimumPayment,
    required this.dueDate,
    this.status = DebtStatus.active,
    this.paymentHistory = const [],
    this.updatedAt,
    this.isSynced = false,
  });

  @override
  final String id;

  final String creditorName;
  final double totalAmount;
  final double remainingAmount;

  /// Annual interest rate as a percentage (e.g. `24.5`).
  final double interestRate;

  /// Minimum monthly payment.
  final double minimumPayment;

  final DateTime dueDate;
  final DebtStatus status;
  final List<PaymentRecord> paymentHistory;

  /// Last local modification, used for last-write-wins merges.
  final DateTime? updatedAt;

  /// Whether the remote backend already accepted this record.
  final bool isSynced;

  DateTime get lastModified => updatedAt ?? dueDate;

  double get paidAmount =>
      (totalAmount - remainingAmount).clamp(0, totalAmount).toDouble();

  /// Repayment progress in `[0, 1]` for progress indicators.
  double get progress =>
      totalAmount <= 0 ? 1 : (paidAmount / totalAmount).clamp(0, 1).toDouble();

  bool get isPaid => status == DebtStatus.paid || remainingAmount <= 0;

  DebtEntity copyWith({
    String? id,
    String? creditorName,
    double? totalAmount,
    double? remainingAmount,
    double? interestRate,
    double? minimumPayment,
    DateTime? dueDate,
    DebtStatus? status,
    List<PaymentRecord>? paymentHistory,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return DebtEntity(
      id: id ?? this.id,
      creditorName: creditorName ?? this.creditorName,
      totalAmount: totalAmount ?? this.totalAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      interestRate: interestRate ?? this.interestRate,
      minimumPayment: minimumPayment ?? this.minimumPayment,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      paymentHistory: paymentHistory ?? this.paymentHistory,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DebtEntity &&
          other.id == id &&
          other.creditorName == creditorName &&
          other.totalAmount == totalAmount &&
          other.remainingAmount == remainingAmount &&
          other.interestRate == interestRate &&
          other.minimumPayment == minimumPayment &&
          other.dueDate == dueDate &&
          other.status == status &&
          other.updatedAt == updatedAt &&
          other.isSynced == isSynced &&
          _sameHistory(other.paymentHistory, paymentHistory);

  @override
  int get hashCode => Object.hash(
    id,
    creditorName,
    totalAmount,
    remainingAmount,
    interestRate,
    minimumPayment,
    dueDate,
    status,
    updatedAt,
    isSynced,
    Object.hashAll(paymentHistory),
  );

  static bool _sameHistory(List<PaymentRecord> a, List<PaymentRecord> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }

  @override
  String toString() =>
      'DebtEntity(id: $id, creditor: $creditorName, '
      'remaining: $remainingAmount/$totalAmount)';
}
