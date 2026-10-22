import 'package:fin_sight_ai/features/transactions/domain/entities/transaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final date = DateTime.utc(2026, 10, 20, 14, 30);

  Transaction buildTransaction({bool isSynced = false}) {
    return Transaction(
      id: 'tx-1',
      amount: 1250.75,
      date: date,
      category: 'Groceries',
      type: TransactionType.expense,
      note: 'Weekly shopping',
      isSynced: isSynced,
    );
  }

  group('Transaction', () {
    test('exposes direction helpers derived from its type', () {
      // Arrange
      final expense = buildTransaction();
      final income = expense.copyWith(type: TransactionType.income);

      // Act & Assert
      expect(expense.isExpense, isTrue);
      expect(expense.isIncome, isFalse);
      expect(income.isIncome, isTrue);
      expect(income.isExpense, isFalse);
    });

    test('signs the amount by direction', () {
      // Arrange
      final expense = buildTransaction();
      final income = expense.copyWith(type: TransactionType.income);

      // Act & Assert
      expect(expense.signedAmount, -1250.75);
      expect(income.signedAmount, 1250.75);
    });

    test('copyWith replaces only the provided fields', () {
      // Arrange
      final original = buildTransaction();

      // Act
      final updated = original.copyWith(isSynced: true, note: 'Updated');

      // Assert
      expect(updated.id, original.id);
      expect(updated.amount, original.amount);
      expect(updated.date, original.date);
      expect(updated.category, original.category);
      expect(updated.note, 'Updated');
      expect(updated.isSynced, isTrue);
      expect(original.isSynced, isFalse);
      expect(original.note, 'Weekly shopping');
    });

    test('uses value equality across all fields', () {
      // Arrange
      final first = buildTransaction();
      final second = buildTransaction();
      final differentSync = buildTransaction(isSynced: true);
      final differentType = first.copyWith(type: TransactionType.income);

      // Act & Assert
      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, isNot(differentSync));
      expect(first, isNot(differentType));
    });

    test('toString includes the identifier and type for debugging', () {
      // Arrange
      final transaction = buildTransaction();

      // Act
      final description = transaction.toString();

      // Assert
      expect(description, contains('tx-1'));
      expect(description, contains('expense'));
      expect(description, contains('Groceries'));
    });
  });
}
