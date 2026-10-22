/// Direction of a monetary movement.
enum TransactionType { income, expense }

/// Pure domain representation of a recorded money movement.
///
/// The entity is intentionally free of Flutter, database, and serialization
/// concerns. Persistence formats live in the data layer.
class Transaction {
  const Transaction({
    required this.id,
    required this.amount,
    required this.date,
    required this.category,
    required this.type,
    this.note = '',
    this.isSynced = false,
  });

  /// Stable UUID assigned when the transaction is created.
  final String id;

  /// Positive magnitude of the movement. Sign is derived from [type].
  final double amount;

  /// When the movement happened (UTC recommended).
  final DateTime date;

  /// User-defined category, already trimmed.
  final String category;

  /// Income or expense.
  final TransactionType type;

  /// Optional free-form note, already trimmed.
  final String note;

  /// Whether the record has been accepted by the remote backend.
  final bool isSynced;

  bool get isIncome => type == TransactionType.income;

  bool get isExpense => type == TransactionType.expense;

  /// Amount signed by direction: positive for income, negative for expenses.
  double get signedAmount => isIncome ? amount : -amount;

  Transaction copyWith({
    String? id,
    double? amount,
    DateTime? date,
    String? category,
    TransactionType? type,
    String? note,
    bool? isSynced,
  }) {
    return Transaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      type: type ?? this.type,
      note: note ?? this.note,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction &&
          other.id == id &&
          other.amount == amount &&
          other.date == date &&
          other.category == category &&
          other.type == type &&
          other.note == note &&
          other.isSynced == isSynced;

  @override
  int get hashCode =>
      Object.hash(id, amount, date, category, type, note, isSynced);

  @override
  String toString() =>
      'Transaction(id: $id, amount: $amount, type: $type, '
      'category: $category, date: $date, isSynced: $isSynced)';
}
