import '../../domain/entities/debt_entity.dart';

/// Data-transfer representation of [DebtEntity].
class DebtModel extends DebtEntity {
  const DebtModel({
    required super.id,
    required super.creditorName,
    required super.totalAmount,
    required super.remainingAmount,
    required super.interestRate,
    required super.minimumPayment,
    required super.dueDate,
    super.status,
    super.paymentHistory,
    super.updatedAt,
    super.isSynced,
  });

  factory DebtModel.fromEntity(DebtEntity debt) {
    return DebtModel(
      id: debt.id,
      creditorName: debt.creditorName,
      totalAmount: debt.totalAmount,
      remainingAmount: debt.remainingAmount,
      interestRate: debt.interestRate,
      minimumPayment: debt.minimumPayment,
      dueDate: debt.dueDate,
      status: debt.status,
      paymentHistory: debt.paymentHistory,
      updatedAt: debt.updatedAt,
      isSynced: debt.isSynced,
    );
  }

  factory DebtModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final creditorName = json['creditorName'];
    final totalAmount = json['totalAmount'];
    final remainingAmount = json['remainingAmount'];
    final interestRate = json['interestRate'];
    final minimumPayment = json['minimumPayment'];
    final dueDate = json['dueDate'];
    final status = json['status'];
    final history = json['paymentHistory'];
    final updatedAt = json['updatedAt'];
    final isSynced = json['isSynced'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('Debt id is missing or invalid.');
    }
    if (creditorName is! String) {
      throw const FormatException('Debt creditor name is missing or invalid.');
    }
    if (totalAmount is! num || remainingAmount is! num) {
      throw const FormatException('Debt amounts are missing or invalid.');
    }
    if (interestRate is! num || minimumPayment is! num) {
      throw const FormatException('Debt payment terms are missing or invalid.');
    }
    if (dueDate is! String) {
      throw const FormatException('Debt due date is missing or invalid.');
    }

    final parsedStatus = status is String
        ? DebtStatus.values.asNameMap()[status]
        : null;
    if (parsedStatus == null) {
      throw const FormatException('Debt status is missing or invalid.');
    }

    final paymentHistory = <PaymentRecord>[];
    if (history is List) {
      for (final entry in history) {
        if (entry is! Map) {
          throw const FormatException('Invalid payment entry.');
        }
        paymentHistory.add(_paymentFromJson(Map<String, dynamic>.from(entry)));
      }
    } else if (history != null) {
      throw const FormatException('Payment history must be a list.');
    }

    return DebtModel(
      id: id,
      creditorName: creditorName,
      totalAmount: totalAmount.toDouble(),
      remainingAmount: remainingAmount.toDouble(),
      interestRate: interestRate.toDouble(),
      minimumPayment: minimumPayment.toDouble(),
      dueDate: DateTime.parse(dueDate),
      status: parsedStatus,
      paymentHistory: List<PaymentRecord>.unmodifiable(paymentHistory),
      updatedAt: updatedAt is String ? DateTime.tryParse(updatedAt) : null,
      isSynced: isSynced is bool ? isSynced : false,
    );
  }

  static PaymentRecord _paymentFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final amount = json['amount'];
    final paidAt = json['paidAt'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('Payment id is missing or invalid.');
    }
    if (amount is! num) {
      throw const FormatException('Payment amount is missing or invalid.');
    }
    if (paidAt is! String) {
      throw const FormatException('Payment date is missing or invalid.');
    }

    return PaymentRecord(
      id: id,
      amount: amount.toDouble(),
      paidAt: DateTime.parse(paidAt),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'creditorName': creditorName,
      'totalAmount': totalAmount,
      'remainingAmount': remainingAmount,
      'interestRate': interestRate,
      'minimumPayment': minimumPayment,
      'dueDate': dueDate.toUtc().toIso8601String(),
      'status': status.name,
      'updatedAt': updatedAt?.toUtc().toIso8601String(),
      'isSynced': isSynced,
      'paymentHistory': paymentHistory
          .map(
            (payment) => <String, dynamic>{
              'id': payment.id,
              'amount': payment.amount,
              'paidAt': payment.paidAt.toUtc().toIso8601String(),
            },
          )
          .toList(),
    };
  }

  DebtEntity toEntity() {
    return DebtEntity(
      id: id,
      creditorName: creditorName,
      totalAmount: totalAmount,
      remainingAmount: remainingAmount,
      interestRate: interestRate,
      minimumPayment: minimumPayment,
      dueDate: dueDate,
      status: status,
      paymentHistory: paymentHistory,
      updatedAt: updatedAt,
      isSynced: isSynced,
    );
  }
}
