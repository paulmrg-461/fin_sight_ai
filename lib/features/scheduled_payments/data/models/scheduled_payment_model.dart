import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../domain/entities/scheduled_payment_entity.dart';

/// Data-transfer representation of [ScheduledPaymentEntity].
class ScheduledPaymentModel extends ScheduledPaymentEntity {
  const ScheduledPaymentModel({
    required super.id,
    required super.name,
    required super.amount,
    required super.category,
    required super.frequency,
    required super.nextDueDate,
    required super.dayOfMonth,
    required super.createdAt,
    super.type,
    super.walletId,
    super.notes,
    super.isActive,
    super.updatedAt,
    super.lastPaidAt,
    super.isSynced,
    super.deletedAt,
  });

  factory ScheduledPaymentModel.fromEntity(ScheduledPaymentEntity payment) {
    return ScheduledPaymentModel(
      id: payment.id,
      name: payment.name,
      amount: payment.amount,
      type: payment.type,
      category: payment.category,
      frequency: payment.frequency,
      nextDueDate: payment.nextDueDate,
      dayOfMonth: payment.dayOfMonth,
      walletId: payment.walletId,
      notes: payment.notes,
      isActive: payment.isActive,
      createdAt: payment.createdAt,
      updatedAt: payment.updatedAt,
      lastPaidAt: payment.lastPaidAt,
      isSynced: payment.isSynced,
      deletedAt: payment.deletedAt,
    );
  }

  factory ScheduledPaymentModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final amount = json['amount'];
    final category = json['category'];
    final frequency = json['frequency'];
    final nextDueDate = json['nextDueDate'];
    final dayOfMonth = json['dayOfMonth'];
    final createdAt = json['createdAt'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('Payment id is missing or invalid.');
    }
    if (name is! String || name.trim().isEmpty) {
      throw const FormatException('Payment name is missing or invalid.');
    }
    if (amount is! num) {
      throw const FormatException('Payment amount is missing or invalid.');
    }
    if (category is! String || category.trim().isEmpty) {
      throw const FormatException('Payment category is missing or invalid.');
    }
    final parsedFrequency = frequency is String
        ? PaymentFrequency.values.asNameMap()[frequency]
        : null;
    if (parsedFrequency == null) {
      throw const FormatException('Payment frequency is missing or invalid.');
    }
    final due = nextDueDate is String ? DateTime.tryParse(nextDueDate) : null;
    if (due == null) {
      throw const FormatException('Payment due date is missing or invalid.');
    }
    final created = createdAt is String ? DateTime.tryParse(createdAt) : null;
    if (created == null) {
      throw const FormatException('Payment creation date is missing.');
    }
    // Schedules persisted before `type` existed migrate implicitly to expense.
    final parsedType = json['type'] is String
        ? TransactionType.values.asNameMap()[json['type']]
        : null;

    return ScheduledPaymentModel(
      id: id,
      name: name,
      amount: amount.toDouble(),
      type: parsedType ?? TransactionType.expense,
      category: category,
      frequency: parsedFrequency,
      nextDueDate: due,
      dayOfMonth: dayOfMonth is int ? dayOfMonth : due.day,
      walletId: json['walletId'] is String ? json['walletId'] as String : null,
      notes: json['notes'] is String ? json['notes'] as String : '',
      isActive: json['isActive'] != false,
      createdAt: created,
      updatedAt: json['updatedAt'] is String
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      lastPaidAt: json['lastPaidAt'] is String
          ? DateTime.tryParse(json['lastPaidAt'] as String)
          : null,
      isSynced: json['isSynced'] is bool ? json['isSynced'] as bool : false,
      deletedAt: json['deletedAt'] is String
          ? DateTime.tryParse(json['deletedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'amount': amount,
    'type': type.name,
    'category': category,
    'frequency': frequency.name,
    'nextDueDate': nextDueDate.toIso8601String(),
    'dayOfMonth': dayOfMonth,
    if (walletId != null) 'walletId': walletId,
    'notes': notes,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    if (lastPaidAt != null) 'lastPaidAt': lastPaidAt!.toIso8601String(),
    'isSynced': isSynced,
    if (deletedAt != null) 'deletedAt': deletedAt!.toIso8601String(),
  };

  @override
  ScheduledPaymentModel copyWith({
    String? id,
    String? name,
    double? amount,
    TransactionType? type,
    String? category,
    PaymentFrequency? frequency,
    DateTime? nextDueDate,
    int? dayOfMonth,
    String? walletId,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastPaidAt,
    bool? isSynced,
    DateTime? deletedAt,
  }) {
    return ScheduledPaymentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      walletId: walletId ?? this.walletId,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastPaidAt: lastPaidAt ?? this.lastPaidAt,
      isSynced: isSynced ?? this.isSynced,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  ScheduledPaymentEntity toEntity() => ScheduledPaymentEntity(
    id: id,
    name: name,
    amount: amount,
    type: type,
    category: category,
    frequency: frequency,
    nextDueDate: nextDueDate,
    dayOfMonth: dayOfMonth,
    walletId: walletId,
    notes: notes,
    isActive: isActive,
    createdAt: createdAt,
    updatedAt: updatedAt,
    lastPaidAt: lastPaidAt,
    isSynced: isSynced,
    deletedAt: deletedAt,
  );
}
