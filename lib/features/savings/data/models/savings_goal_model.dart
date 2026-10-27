import '../../domain/entities/savings_goal_entity.dart';

class SavingsGoalModel extends SavingsGoalEntity {
  const SavingsGoalModel({
    required super.id,
    required super.name,
    required super.targetAmount,
    required super.createdAt,
    super.targetDate,
    super.contributions,
  });

  factory SavingsGoalModel.fromEntity(SavingsGoalEntity goal) {
    return SavingsGoalModel(
      id: goal.id,
      name: goal.name,
      targetAmount: goal.targetAmount,
      createdAt: goal.createdAt,
      targetDate: goal.targetDate,
      contributions: goal.contributions,
    );
  }

  factory SavingsGoalModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final targetAmount = json['targetAmount'];
    final createdAt = json['createdAt'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Goal id is missing.');
    }
    if (name is! String || name.trim().isEmpty) {
      throw const FormatException('Goal name is missing.');
    }
    if (targetAmount is! num) {
      throw const FormatException('Goal target is missing.');
    }
    final created = createdAt is String ? DateTime.tryParse(createdAt) : null;
    if (created == null) {
      throw const FormatException('Goal creation date is missing.');
    }
    final rows = json['contributions'];
    final contributions = <SavingsContribution>[];
    if (rows is List) {
      for (final row in rows) {
        final contribution = _contribution(row);
        if (contribution != null) {
          contributions.add(contribution);
        }
      }
    }
    return SavingsGoalModel(
      id: id,
      name: name,
      targetAmount: targetAmount.toDouble(),
      createdAt: created,
      targetDate: json['targetDate'] is String
          ? DateTime.tryParse(json['targetDate'] as String)
          : null,
      contributions: List<SavingsContribution>.unmodifiable(contributions),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'targetAmount': targetAmount,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'targetDate': targetDate?.toUtc().toIso8601String(),
    'contributions': [
      for (final contribution in contributions)
        {
          'id': contribution.id,
          'amount': contribution.amount,
          'date': contribution.date.toUtc().toIso8601String(),
        },
    ],
  };

  SavingsGoalEntity toEntity() => SavingsGoalEntity(
    id: id,
    name: name,
    targetAmount: targetAmount,
    createdAt: createdAt,
    targetDate: targetDate,
    contributions: contributions,
  );

  static SavingsContribution? _contribution(Object? value) {
    if (value is! Map) {
      return null;
    }
    final id = value['id'];
    final amount = value['amount'];
    final date = value['date'];
    if (id is! String || amount is! num || date is! String) {
      return null;
    }
    final parsed = DateTime.tryParse(date);
    if (parsed == null) {
      return null;
    }
    return SavingsContribution(id: id, amount: amount.toDouble(), date: parsed);
  }
}
