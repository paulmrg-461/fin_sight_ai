import '../../domain/entities/transaction.dart';

/// Data-transfer representation of [Transaction].
///
/// JSON keys are stable: changing them requires a migration in the local store
/// and a coordinated change in the backend schema.
class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.amount,
    required this.date,
    required this.category,
    required this.type,
    required this.note,
    required this.isSynced,
  });

  factory TransactionModel.fromEntity(Transaction transaction) {
    return TransactionModel(
      id: transaction.id,
      amount: transaction.amount,
      date: transaction.date,
      category: transaction.category,
      type: transaction.type,
      note: transaction.note,
      isSynced: transaction.isSynced,
    );
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final amount = json['amount'];
    final date = json['date'];
    final category = json['category'];
    final type = json['type'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('Transaction id is missing or invalid.');
    }
    if (amount is! num) {
      throw const FormatException('Transaction amount is missing or invalid.');
    }
    if (date is! String) {
      throw const FormatException('Transaction date is missing or invalid.');
    }
    if (category is! String) {
      throw const FormatException(
        'Transaction category is missing or invalid.',
      );
    }
    if (type is! String) {
      throw const FormatException('Transaction type is missing or invalid.');
    }

    final parsedType = TransactionType.values.asNameMap()[type];
    if (parsedType == null) {
      throw FormatException('Unknown transaction type: $type');
    }

    final note = json['note'];
    final isSynced = json['isSynced'];

    return TransactionModel(
      id: id,
      amount: amount.toDouble(),
      date: DateTime.parse(date),
      category: category,
      type: parsedType,
      note: note is String ? note : '',
      isSynced: isSynced is bool ? isSynced : false,
    );
  }

  final String id;
  final double amount;
  final DateTime date;
  final String category;
  final TransactionType type;
  final String note;
  final bool isSynced;

  Transaction toEntity() {
    return Transaction(
      id: id,
      amount: amount,
      date: date,
      category: category,
      type: type,
      note: note,
      isSynced: isSynced,
    );
  }

  TransactionModel copyWith({
    String? id,
    double? amount,
    DateTime? date,
    String? category,
    TransactionType? type,
    String? note,
    bool? isSynced,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      type: type ?? this.type,
      note: note ?? this.note,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'amount': amount,
      'date': date.toUtc().toIso8601String(),
      'category': category,
      'type': type.name,
      'note': note,
      'isSynced': isSynced,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionModel &&
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
      'TransactionModel(id: $id, amount: $amount, type: $type, '
      'isSynced: $isSynced)';
}
