import '../../../../core/domain/entity.dart';

/// Direction of the money movement.
enum TransactionType { income, expense }

/// Pure domain entity for a recorded income or expense.
class TransactionEntity extends Entity {
  const TransactionEntity({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.date,
    this.receiptImagePath,
  });

  @override
  final String id;

  /// Positive magnitude in the user's currency.
  final double amount;

  final TransactionType type;
  final String category;
  final String description;
  final DateTime date;

  /// Local path to an attached receipt image, when available.
  final String? receiptImagePath;

  bool get isIncome => type == TransactionType.income;

  bool get isExpense => type == TransactionType.expense;

  /// Amount signed by direction: positive for income, negative for expenses.
  double get signedAmount => isIncome ? amount : -amount;

  TransactionEntity copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    String? category,
    String? description,
    DateTime? date,
    String? receiptImagePath,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionEntity &&
          other.id == id &&
          other.amount == amount &&
          other.type == type &&
          other.category == category &&
          other.description == description &&
          other.date == date &&
          other.receiptImagePath == receiptImagePath;

  @override
  int get hashCode => Object.hash(
    id,
    amount,
    type,
    category,
    description,
    date,
    receiptImagePath,
  );

  @override
  String toString() =>
      'TransactionEntity(id: $id, amount: $amount, type: $type, '
      'category: $category)';
}
