import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/features/dashboard/domain/entities/dashboard_entities.dart';
import 'package:fin_sight_ai/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:fin_sight_ai/features/dashboard/domain/usecases/dashboard_usecases.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockDashboardRepository extends Mock implements DashboardRepository {}

void main() {
  late MockDashboardRepository repository;

  final start = DateTime.utc(2026, 10, 1);
  final end = DateTime.utc(2026, 10, 31);

  const summary = DashboardSummaryEntity(
    totalIncome: 1000,
    totalExpenses: 400,
    balance: 600,
    savingsRate: 60,
    monthOverMonthChange: 10,
  );
  const comparison = MonthlyComparisonEntity(
    currentIncome: 1000,
    currentExpenses: 400,
    previousIncome: 900,
    previousExpenses: 300,
    expenseChangePercentage: 33.33,
  );
  final recent = TransactionEntity(
    id: 'tx-1',
    amount: 400,
    type: TransactionType.expense,
    category: 'Food',
    description: 'Groceries',
    date: DateTime.utc(2026, 10, 20),
  );
  final data = DashboardData(
    summary: summary,
    breakdown: const [],
    comparison: comparison,
    recentTransactions: [recent],
    start: start,
    end: end,
  );

  setUp(() {
    repository = MockDashboardRepository();
  });

  group('dashboard use cases', () {
    test('DashboardRangeParams compares by value', () {
      expect(
        DashboardRangeParams(start: start, end: end),
        DashboardRangeParams(start: start, end: end),
      );
      expect(
        DashboardRangeParams(start: start, end: end).hashCode,
        DashboardRangeParams(start: start, end: end).hashCode,
      );
      expect(
        DashboardRangeParams(start: start, end: end),
        isNot(DashboardRangeParams(start: start, end: start)),
      );
    });

    test('GetDashboardDataUseCase delegates a valid range', () async {
      when(() => repository.getDashboardData(start: start, end: end))
          .thenAnswer((_) async => Right(data));

      final result = await GetDashboardDataUseCase(repository)(
        DashboardRangeParams(start: start, end: end),
      );

      expect(result.getOrElse((_) => fail('Expected dashboard data')), data);
    });

    test('rejects a reversed range without querying the repository', () async {
      final result = await GetDashboardDataUseCase(repository)(
        DashboardRangeParams(start: end, end: start),
      );

      final failure = result.getLeft().toNullable();
      expect(failure, isA<ValidationFailure>());
      expect(failure?.code, 'invalid_date_range');
      verifyNever(
        () => repository.getDashboardData(
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      );
    });

    test('propagates repository failures', () async {
      const failure = CacheFailure('Store down.');
      when(() => repository.getDashboardData(start: start, end: end))
          .thenAnswer((_) async => const Left(failure));

      final result = await GetDashboardDataUseCase(repository)(
        DashboardRangeParams(start: start, end: end),
      );

      expect(result.getLeft().toNullable(), failure);
    });
  });
}
