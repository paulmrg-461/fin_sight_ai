import '../../domain/entities/transaction_entity.dart';

/// Data-transfer representation of [TransactionEntity].
///
/// The JSON contract is shared by the local Hive store and any future backend.
class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.amount,
    required super.type,
    required super.category,
    required super.description,
    required super.date,
    super.receiptImagePath,
    super.updatedAt,
    super.isSynced,
    super.deletedAt,
  });

  factory TransactionModel.fromEntity(TransactionEntity transaction) {
    return TransactionModel(
      id: transaction.id,
      amount: transaction.amount,
      type: transaction.type,
      category: transaction.category,
      description: transaction.description,
      date: transaction.date,
      receiptImagePath: transaction.receiptImagePath,
      updatedAt: transaction.updatedAt,
      isSynced: transaction.isSynced,
      deletedAt: transaction.deletedAt,
    );
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final amount = json['amount'];
    final type = json['type'];
    final category = json['category'];
    final description = json['description'];
    final date = json['date'];
    final receiptImagePath = json['receiptImagePath'];
    final updatedAt = json['updatedAt'];
    final isSynced = json['isSynced'];
    final deletedAt = json['deletedAt'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('Transaction id is missing or invalid.');
    }
    if (amount is! num) {
      throw const FormatException('Transaction amount is missing or invalid.');
    }
    if (type is! String) {
      throw const FormatException('Transaction type is missing or invalid.');
    }
    final parsedType = TransactionType.values.asNameMap()[type];
    if (parsedType == null) {
      throw FormatException('Unknown transaction type: $type');
    }
    if (category is! String) {
      throw const FormatException(
        'Transaction category is missing or invalid.',
      );
    }
    if (description is! String) {
      throw const FormatException(
        'Transaction description is missing or invalid.',
      );
    }
    if (date is! String) {
      throw const FormatException('Transaction date is missing or invalid.');
    }

    return TransactionModel(
      id: id,
      amount: amount.toDouble(),
      type: parsedType,
      category: category,
      description: description,
      date: DateTime.parse(date),
      receiptImagePath: receiptImagePath is String ? receiptImagePath : null,
      updatedAt: updatedAt is String ? DateTime.tryParse(updatedAt) : null,
      isSynced: isSynced is bool ? isSynced : false,
      deletedAt: deletedAt is String ? DateTime.tryParse(deletedAt) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'amount': amount,
      'type': type.name,
      'category': category,
      'description': description,
      'date': date.toUtc().toIso8601String(),
      'receiptImagePath': receiptImagePath,
      'updatedAt': updatedAt?.toUtc().toIso8601String(),
      'isSynced': isSynced,
      'deletedAt': deletedAt?.toUtc().toIso8601String(),
    };
  }

  TransactionEntity toEntity() {
    return TransactionEntity(
      id: id,
      amount: amount,
      type: type,
      category: category,
      description: description,
      date: date,
      receiptImagePath: receiptImagePath,
      updatedAt: updatedAt,
      isSynced: isSynced,
      deletedAt: deletedAt,
    );
  }
}
