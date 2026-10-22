import 'package:fin_sight_ai/core/domain/entity.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final date = DateTime.utc(2026, 10, 20, 14, 30);

  TransactionEntity buildTransaction() {
    return TransactionEntity(
      id: 'tx-1',
      amount: 1250.75,
      type: TransactionType.expense,
      category: 'Groceries',
      description: 'Weekly shopping',
      date: date,
      receiptImagePath: '/tmp/receipt.jpg',
    );
  }

  group('TransactionEntity', () {
    test('is a domain Entity', () {
      expect(buildTransaction(), isA<Entity>());
    });

    test('derives direction helpers and signed amount', () {
      final expense = buildTransaction();
      final income = expense.copyWith(type: TransactionType.income);

      expect(expense.isExpense, isTrue);
      expect(expense.isIncome, isFalse);
      expect(expense.signedAmount, -1250.75);
      expect(income.isIncome, isTrue);
      expect(income.signedAmount, 1250.75);
    });

    test('copyWith replaces only provided fields', () {
      final original = buildTransaction();

      final updated = original.copyWith(
        description: 'Updated',
        receiptImagePath: '/tmp/new.jpg',
      );

      expect(updated.id, original.id);
      expect(updated.amount, original.amount);
      expect(updated.description, 'Updated');
      expect(updated.receiptImagePath, '/tmp/new.jpg');
      expect(original.description, 'Weekly shopping');
    });

    test('uses value equality across all fields', () {
      final first = buildTransaction();
      final second = buildTransaction();
      final different = first.copyWith(amount: 1);

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, isNot(different));
    });

    test('toString exposes the id, amount, and type', () {
      final description = buildTransaction().toString();

      expect(description, contains('tx-1'));
      expect(description, contains('1250.75'));
      expect(description, contains('expense'));
    });
  });
}
