import '../../domain/entities/receivable_entity.dart';

/// Data-transfer representation of [ReceivableEntity].
class ReceivableModel extends ReceivableEntity {
  const ReceivableModel({
    required super.id,
    required super.debtorName,
    required super.totalAmount,
    required super.remainingAmount,
    required super.dateLent,
    required super.createdAt,
    required super.updatedAt,
    super.dueDate,
    super.notes,
    super.status,
    super.paymentHistory,
    super.isSynced,
    super.deletedAt,
  });

  factory ReceivableModel.fromEntity(ReceivableEntity receivable) {
    return ReceivableModel(
      id: receivable.id,
      debtorName: receivable.debtorName,
      totalAmount: receivable.totalAmount,
      remainingAmount: receivable.remainingAmount,
      dateLent: receivable.dateLent,
      dueDate: receivable.dueDate,
      notes: receivable.notes,
      status: receivable.status,
      paymentHistory: receivable.paymentHistory,
      createdAt: receivable.createdAt,
      updatedAt: receivable.updatedAt,
      isSynced: receivable.isSynced,
      deletedAt: receivable.deletedAt,
    );
  }

  factory ReceivableModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final debtorName = json['debtorName'];
    final totalAmount = json['totalAmount'];
    final remainingAmount = json['remainingAmount'];
    final dateLent = json['dateLent'];
    final dueDate = json['dueDate'];
    final notes = json['notes'];
    final status = json['status'];
    final history = json['paymentHistory'];
    final createdAt = json['createdAt'];
    final updatedAt = json['updatedAt'];
    final isSynced = json['isSynced'];
    final deletedAt = json['deletedAt'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('Receivable id is missing or invalid.');
    }
    if (debtorName is! String || debtorName.trim().isEmpty) {
      throw const FormatException('Receivable debtor name is invalid.');
    }
    if (totalAmount is! num || remainingAmount is! num) {
      throw const FormatException('Receivable amounts are missing or invalid.');
    }
    if (dateLent is! String) {
      throw const FormatException(
        'Receivable date lent is missing or invalid.',
      );
    }

    final parsedDateLent = DateTime.tryParse(dateLent);
    if (parsedDateLent == null) {
      throw const FormatException(
        'Receivable date lent is missing or invalid.',
      );
    }

    DateTime? parsedDueDate;
    if (dueDate is String && dueDate.isNotEmpty) {
      parsedDueDate = DateTime.tryParse(dueDate);
      if (parsedDueDate == null) {
        throw const FormatException('Receivable due date is invalid.');
      }
    } else if (dueDate != null && dueDate is! String) {
      throw const FormatException('Receivable due date is invalid.');
    }

    final parsedStatus = status is String
        ? ReceivableStatus.values.asNameMap()[status]
        : null;
    if (status != null && parsedStatus == null) {
      throw const FormatException('Receivable status is invalid.');
    }

    final paymentHistory = <ReceivablePayment>[];
    if (history is List) {
      for (final entry in history) {
        if (entry is! Map) {
          throw const FormatException('Invalid receivable payment entry.');
        }
        paymentHistory.add(_paymentFromJson(Map<String, dynamic>.from(entry)));
      }
    } else if (history != null) {
      throw const FormatException('Receivable payment history must be a list.');
    }

    final parsedCreatedAt = createdAt is String
        ? DateTime.tryParse(createdAt)
        : null;
    final parsedUpdatedAt = updatedAt is String
        ? DateTime.tryParse(updatedAt)
        : null;

    return ReceivableModel(
      id: id,
      debtorName: debtorName.trim(),
      totalAmount: totalAmount.toDouble(),
      remainingAmount: remainingAmount.toDouble(),
      dateLent: parsedDateLent,
      dueDate: parsedDueDate,
      notes: notes is String ? notes : '',
      status:
          parsedStatus ??
          (remainingAmount <= 0
              ? ReceivableStatus.paid
              : ReceivableStatus.active),
      paymentHistory: List<ReceivablePayment>.unmodifiable(paymentHistory),
      createdAt: parsedCreatedAt ?? parsedDateLent,
      updatedAt: parsedUpdatedAt ?? parsedCreatedAt ?? parsedDateLent,
      isSynced: isSynced is bool ? isSynced : false,
      deletedAt: deletedAt is String ? DateTime.tryParse(deletedAt) : null,
    );
  }

  static ReceivablePayment _paymentFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final amount = json['amount'];
    final paidAt = json['paidAt'];
    final note = json['note'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('Receivable payment id is invalid.');
    }
    if (amount is! num) {
      throw const FormatException('Receivable payment amount is invalid.');
    }
    if (paidAt is! String) {
      throw const FormatException('Receivable payment date is invalid.');
    }

    final parsedPaidAt = DateTime.tryParse(paidAt);
    if (parsedPaidAt == null) {
      throw const FormatException('Receivable payment date is invalid.');
    }

    return ReceivablePayment(
      id: id,
      amount: amount.toDouble(),
      paidAt: parsedPaidAt,
      note: note is String ? note : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'debtorName': debtorName,
      'totalAmount': totalAmount,
      'remainingAmount': remainingAmount,
      'dateLent': dateLent.toUtc().toIso8601String(),
      'dueDate': dueDate?.toUtc().toIso8601String(),
      'notes': notes,
      'status': status.name,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'isSynced': isSynced,
      'deletedAt': deletedAt?.toUtc().toIso8601String(),
      'paymentHistory': paymentHistory
          .map(
            (payment) => <String, dynamic>{
              'id': payment.id,
              'amount': payment.amount,
              'paidAt': payment.paidAt.toUtc().toIso8601String(),
              'note': payment.note,
            },
          )
          .toList(),
    };
  }

  ReceivableEntity toEntity() {
    return ReceivableEntity(
      id: id,
      debtorName: debtorName,
      totalAmount: totalAmount,
      remainingAmount: remainingAmount,
      dateLent: dateLent,
      dueDate: dueDate,
      notes: notes,
      status: status,
      paymentHistory: paymentHistory,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isSynced: isSynced,
      deletedAt: deletedAt,
    );
  }
}
