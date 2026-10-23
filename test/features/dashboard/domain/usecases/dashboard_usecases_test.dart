import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/features/dashboard/domain/entities/dashboard_entities.dart';
import 'package:fin_sight_ai/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:fin_sight_ai/features/dashboard/domain/usecases/dashboard_usecases.dart';
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

    test('GetDashboardSummaryUseCase delegates a valid range', () async {
      when(() => repository.getDashboardSummary(start: start, end: end))
          .thenAnswer((_) async => const Right(summary));

      final result = await GetDashboardSummaryUseCase(repository)(
        DashboardRangeParams(start: start, end: end),
      );

      expect(result.getOrElse((_) => fail('Expected summary')), summary);
    });

    test('GetCategoryBreakdownUseCase returns breakdown data', () async {
      const breakdown = [
        CategoryBreakdown(category: 'Food', amount: 100, percentage: 100),
      ];
      when(() => repository.getCategoryBreakdown(start: start, end: end))
          .thenAnswer((_) async => const Right(breakdown));

      final result = await GetCategoryBreakdownUseCase(repository)(
        DashboardRangeParams(start: start, end: end),
      );

      expect(result.getOrElse((_) => const <CategoryBreakdown>[]), breakdown);
    });

    test('GetMonthlyComparisonUseCase returns comparison data', () async {
      when(() => repository.getMonthlyComparison(start: start, end: end))
          .thenAnswer((_) async => const Right(comparison));

      final result = await GetMonthlyComparisonUseCase(repository)(
        DashboardRangeParams(start: start, end: end),
      );

      expect(result.getOrElse((_) => fail('Expected comparison')), comparison);
    });

    test('rejects a reversed range without querying the repository', () async {
      final params = DashboardRangeParams(start: end, end: start);

      final summaryResult = await GetDashboardSummaryUseCase(repository)(
        params,
      );
      final breakdownResult = await GetCategoryBreakdownUseCase(repository)(
        params,
      );
      final comparisonResult = await GetMonthlyComparisonUseCase(repository)(
        params,
      );

      for (final failure in [
        summaryResult.getLeft().toNullable(),
        breakdownResult.getLeft().toNullable(),
        comparisonResult.getLeft().toNullable(),
      ]) {
        expect(failure, isA<ValidationFailure>());
        expect(failure?.code, 'invalid_date_range');
      }
      verifyNever(
        () => repository.getDashboardSummary(
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      );
    });

    test('propagates repository failures', () async {
      const failure = CacheFailure('Store down.');
      when(() => repository.getDashboardSummary(start: start, end: end))
          .thenAnswer((_) async => const Left(failure));

      final result = await GetDashboardSummaryUseCase(repository)(
        DashboardRangeParams(start: start, end: end),
      );

      expect(result.getLeft().toNullable(), failure);
    });
  });
}
