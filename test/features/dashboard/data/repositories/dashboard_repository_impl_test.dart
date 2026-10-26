import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fin_sight_ai/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

TransactionEntity tx({
  required double amount,
  required TransactionType type,
  String category = 'General',
  DateTime? date,
}) {
  return TransactionEntity(
    id: 'tx-${amount}_${type.name}_$category',
    amount: amount,
    type: type,
    category: category,
    description: '',
    date: date ?? DateTime.utc(2026, 10, 1),
  );
}

void main() {
  late MockTransactionRepository transactions;
  late DashboardRepositoryImpl repository;

  final start = DateTime.utc(2026, 10, 1);
  final end = DateTime.utc(2026, 10, 31, 23, 59, 59, 999);
  final previousStart = DateTime.utc(2026, 9, 1);
  final previousEnd = DateTime.utc(2026, 9, 30, 23, 59, 59, 999);

  setUp(() {
    transactions = MockTransactionRepository();
    repository = DashboardRepositoryImpl(transactions);
  });

  void stubRange(
    DateTime rangeStart,
    DateTime rangeEnd,
    List<TransactionEntity> result,
  ) {
    when(
      () => transactions.getTransactionsByDateRange(
        start: rangeStart,
        end: rangeEnd,
      ),
    ).thenAnswer((_) async => Right(result));
  }

  group('DashboardRepositoryImpl', () {
    test('builds every section from exactly two range reads', () async {
      stubRange(start, end, [
        tx(amount: 1000, type: TransactionType.income),
        tx(amount: 300, type: TransactionType.expense, category: 'Food'),
        tx(amount: 100, type: TransactionType.expense, category: 'Travel'),
        tx(
          amount: 50,
          type: TransactionType.expense,
          category: 'Food',
          date: DateTime.utc(2026, 10, 2),
        ),
      ]);
      stubRange(previousStart, previousEnd, [
        tx(amount: 200, type: TransactionType.expense),
      ]);

      final result = await repository.getDashboardData(start: start, end: end);

      final data = result.getOrElse((_) => fail('Expected dashboard data'));
      expect(data.summary.totalIncome, 1000);
      expect(data.summary.totalExpenses, 450);
      expect(data.summary.balance, 550);
      expect(data.summary.monthOverMonthChange, 125);
      expect(data.breakdown.first.category, 'Food');
      expect(data.breakdown.first.amount, 350);
      expect(data.comparison.previousExpenses, 200);
      expect(data.comparison.expenseChangePercentage, 125);
      expect(data.recentTransactions, hasLength(4));
      expect(data.start, start);
      expect(data.end, end);
      verify(
        () => transactions.getTransactionsByDateRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).called(2);
    });

    test('caps recent activity at five newest transactions', () async {
      final current = [
        for (var day = 20; day >= 10; day--)
          tx(
            amount: day.toDouble(),
            type: TransactionType.expense,
            date: DateTime.utc(2026, 10, day),
          ),
      ];
      stubRange(start, end, current);
      stubRange(previousStart, previousEnd, []);

      final result = await repository.getDashboardData(start: start, end: end);

      final data = result.getOrElse((_) => fail('Expected dashboard data'));
      expect(data.recentTransactions, hasLength(5));
      expect(data.recentTransactions.first.amount, 20);
      expect(data.recentTransactions.last.amount, 16);
    });

    test('returns zero totals for an empty period', () async {
      stubRange(start, end, []);
      stubRange(previousStart, previousEnd, []);

      final result = await repository.getDashboardData(start: start, end: end);

      final data = result.getOrElse((_) => fail('Expected dashboard data'));
      expect(data.summary.totalIncome, 0);
      expect(data.summary.totalExpenses, 0);
      expect(data.breakdown, isEmpty);
      expect(data.recentTransactions, isEmpty);
    });

    test('propagates a current read failure without reading the previous '
        'month', () async {
      const failure = CacheFailure('Store down.', code: 'cache_read_failed');
      when(
        () => transactions.getTransactionsByDateRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      final result = await repository.getDashboardData(start: start, end: end);

      expect(result.getLeft().toNullable(), failure);
      verifyNever(
        () => transactions.getTransactionsByDateRange(
          start: previousStart,
          end: previousEnd,
        ),
      );
    });

    test('propagates a previous-month failure', () async {
      stubRange(start, end, []);
      const failure = CacheFailure('Previous failed.');
      when(
        () => transactions.getTransactionsByDateRange(
          start: previousStart,
          end: previousEnd,
        ),
      ).thenAnswer((_) async => const Left(failure));

      final result = await repository.getDashboardData(start: start, end: end);

      expect(result.getLeft().toNullable(), failure);
    });

    test('derives the previous range from local dates', () async {
      final localStart = DateTime(2026, 10, 1);
      final localEnd = DateTime(2026, 10, 31, 23, 59, 59, 999);
      stubRange(localStart, localEnd, []);
      stubRange(
        DateTime(2026, 9, 1),
        DateTime(2026, 9, 30, 23, 59, 59, 999),
        [],
      );

      final result = await repository.getDashboardData(
        start: localStart,
        end: localEnd,
      );

      expect(result.isRight(), isTrue);
    });
  });
}
