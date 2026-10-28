import 'package:fin_sight_ai/features/reports/domain/entities/annual_report.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TransactionEntity transaction({
    required String id,
    required double amount,
    required TransactionType type,
    required DateTime date,
    String category = 'Food',
  }) {
    return TransactionEntity(
      id: id,
      amount: amount,
      type: type,
      category: category,
      description: id,
      date: date,
    );
  }

  test('groups income and expenses into twelve month buckets', () {
    final report = AnnualReport.fromTransactions(
      year: 2026,
      transactions: [
        transaction(
          id: 'jan-income',
          amount: 100,
          type: TransactionType.income,
          date: DateTime.utc(2026, 1, 10),
        ),
        transaction(
          id: 'jan-expense',
          amount: 40,
          type: TransactionType.expense,
          date: DateTime.utc(2026, 1, 20),
        ),
        transaction(
          id: 'feb-expense',
          amount: 25,
          type: TransactionType.expense,
          date: DateTime.utc(2026, 2, 3),
        ),
        transaction(
          id: 'previous-year',
          amount: 999,
          type: TransactionType.expense,
          date: DateTime.utc(2025, 12, 31),
        ),
      ],
    );

    expect(report.year, 2026);
    expect(report.months, hasLength(12));
    expect(report.months.first.income, 100);
    expect(report.months.first.expenses, 40);
    expect(report.months.first.balance, 60);
    expect(report.months[1].expenses, 25);
    expect(report.months[1].balance, -25);
    expect(report.months[2].isEmpty, isTrue);
    expect(report.summary.totalIncome, 100);
    expect(report.summary.totalExpenses, 65);
    expect(report.summary.balance, 35);
    expect(report.transactionCount, 3);
    expect(report.isEmpty, isFalse);
  });

  test('compares annual reports by their contents', () {
    final transactions = [
      transaction(
        id: 'jan-expense',
        amount: 40,
        type: TransactionType.expense,
        date: DateTime.utc(2026, 1, 20),
      ),
    ];
    final report = AnnualReport.fromTransactions(
      year: 2026,
      transactions: transactions,
    );
    final same = AnnualReport.fromTransactions(
      year: 2026,
      transactions: transactions,
    );
    final otherYear = AnnualReport.fromTransactions(
      year: 2025,
      transactions: transactions,
    );
    final moreSpending = AnnualReport.fromTransactions(
      year: 2026,
      transactions: [
        ...transactions,
        transaction(
          id: 'feb-expense',
          amount: 10,
          type: TransactionType.expense,
          date: DateTime.utc(2026, 2, 2),
        ),
      ],
    );

    expect(report, same);
    expect(report.hashCode, same.hashCode);
    expect(report, isNot(otherYear));
    expect(report, isNot(moreSpending));
    expect(report, isNot('report'));
  });

  test('month summaries compare by month and totals', () {
    final january = AnnualMonthSummary(
      month: DateTime.utc(2026, 1),
      income: 100,
      expenses: 40,
    );
    final same = AnnualMonthSummary(
      month: DateTime.utc(2026, 1),
      income: 100,
      expenses: 40,
    );
    final empty = AnnualMonthSummary(
      month: DateTime.utc(2026, 2),
      income: 0,
      expenses: 0,
    );

    expect(january, same);
    expect(january.hashCode, same.hashCode);
    expect(january, isNot(empty));
    expect(january, isNot('january'));
    expect(january.balance, 60);
    expect(january.isEmpty, isFalse);
    expect(empty.isEmpty, isTrue);
    expect(empty.balance, 0);
  });

  test('reports an empty year', () {
    final report = AnnualReport.fromTransactions(
      year: 2026,
      transactions: const [],
    );

    expect(report.isEmpty, isTrue);
    expect(report.months.every((month) => month.isEmpty), isTrue);
    expect(report.summary.totalExpenses, 0);
  });
}
