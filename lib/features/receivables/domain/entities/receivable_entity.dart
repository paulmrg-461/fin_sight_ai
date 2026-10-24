import '../../../../core/domain/entity.dart';

/// Lifecycle of money lent to someone else.
enum ReceivableStatus { active, paid }

/// A single payment received against a receivable.
class ReceivablePayment {
  const ReceivablePayment({
    required this.id,
    required this.amount,
    required this.paidAt,
    this.note,
  });

  final String id;
  final double amount;
  final DateTime paidAt;
  final String? note;

  ReceivablePayment copyWith({
    String? id,
    double? amount,
    DateTime? paidAt,
    String? note,
  }) {
    return ReceivablePayment(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      paidAt: paidAt ?? this.paidAt,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceivablePayment &&
          other.id == id &&
          other.amount == amount &&
          other.paidAt == paidAt &&
          other.note == note;

  @override
  int get hashCode => Object.hash(id, amount, paidAt, note);

  @override
  String toString() =>
      'ReceivablePayment(id: $id, amount: $amount, paidAt: $paidAt)';
}

/// Pure domain entity for money lent and its repayment progress.
class ReceivableEntity extends Entity {
  const ReceivableEntity({
    required this.id,
    required this.debtorName,
    required this.totalAmount,
    required this.remainingAmount,
    required this.dateLent,
    required this.createdAt,
    required this.updatedAt,
    this.dueDate,
    this.notes = '',
    this.status = ReceivableStatus.active,
    this.paymentHistory = const [],
    this.isSynced = false,
    this.deletedAt,
  });

  @override
  final String id;

  final String debtorName;
  final double totalAmount;
  final double remainingAmount;
  final DateTime dateLent;
  final DateTime? dueDate;
  final String notes;
  final ReceivableStatus status;
  final List<ReceivablePayment> paymentHistory;

  /// Whether the remote backend already accepted this record.
  final bool isSynced;

  /// Soft-delete tombstone. Hidden from queries but kept for synchronization.
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  DateTime get lastModified => updatedAt;

  /// Audit timestamps for local persistence and future synchronization.
  final DateTime createdAt;
  final DateTime updatedAt;

  double get paidAmount =>
      (totalAmount - remainingAmount).clamp(0, totalAmount).toDouble();

  /// Repayment progress in `[0, 1]` for progress indicators.
  double get progress =>
      totalAmount <= 0 ? 1 : (paidAmount / totalAmount).clamp(0, 1).toDouble();

  bool get isPaid => status == ReceivableStatus.paid || remainingAmount <= 0;

  ReceivableEntity copyWith({
    String? id,
    String? debtorName,
    double? totalAmount,
    double? remainingAmount,
    DateTime? dateLent,
    Object? dueDate = _unset,
    String? notes,
    ReceivableStatus? status,
    List<ReceivablePayment>? paymentHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    DateTime? deletedAt,
  }) {
    return ReceivableEntity(
      id: id ?? this.id,
      debtorName: debtorName ?? this.debtorName,
      totalAmount: totalAmount ?? this.totalAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      dateLent: dateLent ?? this.dateLent,
      dueDate: identical(dueDate, _unset) ? this.dueDate : dueDate as DateTime?,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      paymentHistory: paymentHistory ?? this.paymentHistory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  static const Object _unset = Object();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceivableEntity &&
          other.id == id &&
          other.debtorName == debtorName &&
          other.totalAmount == totalAmount &&
          other.remainingAmount == remainingAmount &&
          other.dateLent == dateLent &&
          other.dueDate == dueDate &&
          other.notes == notes &&
          other.status == status &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt &&
          other.isSynced == isSynced &&
          other.deletedAt == deletedAt &&
          _sameHistory(other.paymentHistory, paymentHistory);

  @override
  int get hashCode => Object.hash(
    id,
    debtorName,
    totalAmount,
    remainingAmount,
    dateLent,
    dueDate,
    notes,
    status,
    createdAt,
    updatedAt,
    isSynced,
    deletedAt,
    Object.hashAll(paymentHistory),
  );

  static bool _sameHistory(
    List<ReceivablePayment> a,
    List<ReceivablePayment> b,
  ) {
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
      'ReceivableEntity(id: $id, debtor: $debtorName, '
      'remaining: $remainingAmount/$totalAmount)';
}
