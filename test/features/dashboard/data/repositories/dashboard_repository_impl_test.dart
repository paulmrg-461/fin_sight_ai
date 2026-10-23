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
}) {
  return TransactionEntity(
    id: 'tx-${amount}_${type.name}_$category',
    amount: amount,
    type: type,
    category: category,
    description: '',
    date: DateTime.utc(2026, 10, 1),
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

  group('DashboardRepositoryImpl', () {
    test('aggregates the summary with the previous month', () async {
      when(
        () => transactions.getTransactionsByDateRange(start: start, end: end),
      ).thenAnswer(
        (_) async => Right([
          tx(amount: 1000, type: TransactionType.income),
          tx(amount: 400, type: TransactionType.expense, category: 'Food'),
        ]),
      );
      when(
        () => transactions.getTransactionsByDateRange(
          start: previousStart,
          end: previousEnd,
        ),
      ).thenAnswer(
        (_) async => Right([tx(amount: 200, type: TransactionType.expense)]),
      );

      final result = await repository.getDashboardSummary(
        start: start,
        end: end,
      );

      final summary = result.getOrElse((_) => fail('Expected summary'));
      expect(summary.totalIncome, 1000);
      expect(summary.totalExpenses, 400);
      expect(summary.balance, 600);
      expect(summary.savingsRate, 60);
      expect(summary.monthOverMonthChange, 100);
    });

    test('computes a category breakdown for the range', () async {
      when(
        () => transactions.getTransactionsByDateRange(start: start, end: end),
      ).thenAnswer(
        (_) async => Right([
          tx(amount: 300, type: TransactionType.expense, category: 'Food'),
          tx(amount: 100, type: TransactionType.expense, category: 'Travel'),
        ]),
      );

      final result = await repository.getCategoryBreakdown(
        start: start,
        end: end,
      );

      final breakdown = result.getOrElse((_) => fail('Expected breakdown'));
      expect(breakdown.first.category, 'Food');
      expect(breakdown.first.percentage, 75);
    });

    test('computes the monthly comparison', () async {
      when(
        () => transactions.getTransactionsByDateRange(start: start, end: end),
      ).thenAnswer(
        (_) async => Right([
          tx(amount: 500, type: TransactionType.expense),
          tx(amount: 1000, type: TransactionType.income),
        ]),
      );
      when(
        () => transactions.getTransactionsByDateRange(
          start: previousStart,
          end: previousEnd,
        ),
      ).thenAnswer(
        (_) async => Right([
          tx(amount: 250, type: TransactionType.expense),
          tx(amount: 900, type: TransactionType.income),
        ]),
      );

      final result = await repository.getMonthlyComparison(
        start: start,
        end: end,
      );

      final comparison = result.getOrElse((_) => fail('Expected comparison'));
      expect(comparison.currentExpenses, 500);
      expect(comparison.previousExpenses, 250);
      expect(comparison.expenseChangePercentage, 100);
    });

    test('propagates transaction read failures', () async {
      const failure = CacheFailure('Store down.', code: 'cache_read_failed');
      when(
        () => transactions.getTransactionsByDateRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      final result = await repository.getDashboardSummary(
        start: start,
        end: end,
      );

      expect(result.getLeft().toNullable(), failure);
    });

    test('propagates category breakdown failures', () async {
      when(
        () => transactions.getTransactionsByDateRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).thenAnswer((_) async => const Left(CacheFailure('No data.')));

      final result = await repository.getCategoryBreakdown(
        start: start,
        end: end,
      );

      expect(result.getLeft().toNullable()?.message, 'No data.');
    });

    test('propagates comparison failures', () async {
      when(
        () => transactions.getTransactionsByDateRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      ).thenAnswer((_) async => const Left(CacheFailure('No data.')));

      final result = await repository.getMonthlyComparison(
        start: start,
        end: end,
      );

      expect(result.getLeft().toNullable()?.message, 'No data.');
    });

    test('derives the previous range from local dates', () async {
      final localStart = DateTime(2026, 10, 1);
      final localEnd = DateTime(2026, 10, 31, 23, 59, 59, 999);
      when(
        () => transactions.getTransactionsByDateRange(
          start: localStart,
          end: localEnd,
        ),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => transactions.getTransactionsByDateRange(
          start: DateTime(2026, 9, 1),
          end: DateTime(2026, 9, 30, 23, 59, 59, 999),
        ),
      ).thenAnswer((_) async => const Right([]));

      final result = await repository.getDashboardSummary(
        start: localStart,
        end: localEnd,
      );

      expect(result.isRight(), isTrue);
    });

    test('propagates previous-month failures', () async {
      when(
        () => transactions.getTransactionsByDateRange(start: start, end: end),
      ).thenAnswer((_) async => const Right([]));
      const failure = CacheFailure('Previous failed.');
      when(
        () => transactions.getTransactionsByDateRange(
          start: previousStart,
          end: previousEnd,
        ),
      ).thenAnswer((_) async => const Left(failure));

      final result = await repository.getMonthlyComparison(
        start: start,
        end: end,
      );

      expect(result.getLeft().toNullable(), failure);
    });
  });
}
