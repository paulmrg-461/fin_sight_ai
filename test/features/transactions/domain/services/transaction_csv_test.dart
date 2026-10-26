import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fin_sight_ai/features/transactions/domain/services/transaction_csv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TransactionEntity transaction({
    String id = 'tx-1',
    String description = 'Coffee',
    String category = 'Dining',
    double amount = 12.5,
    TransactionType type = TransactionType.expense,
    String? walletId = 'wallet-bank',
    DateTime? date,
  }) {
    return TransactionEntity(
      id: id,
      amount: amount,
      type: type,
      category: category,
      description: description,
      date: date ?? DateTime(2026, 10, 5),
      walletId: walletId,
    );
  }

  test('writes a header and one row per transaction', () {
    final csv = TransactionCsv.build([
      transaction(),
      transaction(
        id: 'tx-2',
        description: 'Salary',
        category: 'Salary',
        amount: 3000,
        type: TransactionType.income,
        walletId: null,
        date: DateTime(2026, 1, 9),
      ),
    ]);

    final lines = csv.split('\n');
    expect(lines.first, 'date,type,category,description,amount,wallet');
    expect(lines[1], '2026-10-05,expense,Dining,Coffee,12.50,wallet-bank');
    expect(lines[2], '2026-01-09,income,Salary,Salary,3000.00,');
    expect(lines, hasLength(3));
  });

  test('escapes commas, quotes, and line breaks', () {
    final csv = TransactionCsv.build([
      transaction(
        description: 'Lunch, "special"\nwith Ana',
        category: 'Dining, work',
      ),
    ]);

    expect(csv, contains('"Dining, work","Lunch, ""special""\nwith Ana"'));
  });

  test('returns only the header for an empty list', () {
    expect(TransactionCsv.build(const []), TransactionCsv.header);
  });
}
