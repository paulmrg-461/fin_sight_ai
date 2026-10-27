import '../../../../core/domain/entity.dart';

/// A contribution added to a savings goal.
class SavingsContribution {
  const SavingsContribution({
    required this.id,
    required this.amount,
    required this.date,
  });

  final String id;
  final double amount;
  final DateTime date;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingsContribution &&
          other.id == id &&
          other.amount == amount &&
          other.date == date;

  @override
  int get hashCode => Object.hash(id, amount, date);

  @override
  String toString() => 'SavingsContribution($amount, $date)';
}

/// A named savings target funded by contributions.
class SavingsGoalEntity extends Entity {
  const SavingsGoalEntity({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.createdAt,
    this.targetDate,
    this.contributions = const [],
  });

  @override
  final String id;

  final String name;
  final double targetAmount;
  final DateTime createdAt;
  final DateTime? targetDate;
  final List<SavingsContribution> contributions;

  double get savedAmount =>
      contributions.fold<double>(0, (sum, item) => sum + item.amount);

  double get remainingAmount =>
      (targetAmount - savedAmount).clamp(0, targetAmount).toDouble();

  double get progress => targetAmount <= 0
      ? 1
      : (savedAmount / targetAmount).clamp(0, 1).toDouble();

  bool get isComplete => savedAmount >= targetAmount;

  SavingsGoalEntity copyWith({
    String? id,
    String? name,
    double? targetAmount,
    DateTime? createdAt,
    DateTime? targetDate,
    List<SavingsContribution>? contributions,
  }) {
    return SavingsGoalEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      createdAt: createdAt ?? this.createdAt,
      targetDate: targetDate ?? this.targetDate,
      contributions: contributions ?? this.contributions,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingsGoalEntity &&
          other.id == id &&
          other.name == name &&
          other.targetAmount == targetAmount &&
          other.createdAt == createdAt &&
          other.targetDate == targetDate &&
          _sameContributions(other.contributions, contributions);

  @override
  int get hashCode => Object.hash(
    id,
    name,
    targetAmount,
    createdAt,
    targetDate,
    Object.hashAll(contributions),
  );

  @override
  String toString() => 'SavingsGoalEntity($name, $savedAmount/$targetAmount)';

  static bool _sameContributions(
    List<SavingsContribution> a,
    List<SavingsContribution> b,
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
}
