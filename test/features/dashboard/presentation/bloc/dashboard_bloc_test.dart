import 'package:bloc_test/bloc_test.dart';
import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/features/dashboard/domain/entities/dashboard_entities.dart';
import 'package:fin_sight_ai/features/dashboard/domain/usecases/dashboard_usecases.dart';
import 'package:fin_sight_ai/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:fin_sight_ai/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:fin_sight_ai/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/get_transactions_by_date_range_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetSummary extends Mock implements GetDashboardSummaryUseCase {}

class MockGetBreakdown extends Mock implements GetCategoryBreakdownUseCase {}

class MockGetComparison extends Mock implements GetMonthlyComparisonUseCase {}

class MockGetByRange extends Mock
    implements GetTransactionsByDateRangeUseCase {}

void main() {
  late MockGetSummary getSummary;
  late MockGetBreakdown getBreakdown;
  late MockGetComparison getComparison;
  late MockGetByRange getByRange;

  const summary = DashboardSummaryEntity(
    totalIncome: 1000,
    totalExpenses: 400,
    balance: 600,
    savingsRate: 60,
    monthOverMonthChange: 10,
  );
  const breakdown = [
    CategoryBreakdown(category: 'Food', amount: 400, percentage: 100),
  ];
  const comparison = MonthlyComparisonEntity(
    currentIncome: 1000,
    currentExpenses: 400,
    previousIncome: 900,
    previousExpenses: 300,
    expenseChangePercentage: 33.33,
  );

  final transactions = [
    TransactionEntity(
      id: 'tx-1',
      amount: 1000,
      type: TransactionType.income,
      category: 'Salary',
      description: 'October',
      date: DateTime.utc(2026, 10, 1),
    ),
    TransactionEntity(
      id: 'tx-2',
      amount: 400,
      type: TransactionType.expense,
      category: 'Food',
      description: 'Groceries',
      date: DateTime.utc(2026, 10, 2),
    ),
  ];

  DateTime monthStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  DateTime monthEnd() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
  }

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      DashboardRangeParams(
        start: DateTime.utc(2026, 10, 1),
        end: DateTime.utc(2026, 10, 31),
      ),
    );
    registerFallbackValue(
      DateRangeParams(
        start: DateTime.utc(2026, 10, 1),
        end: DateTime.utc(2026, 10, 31),
      ),
    );
  });

  setUp(() {
    getSummary = MockGetSummary();
    getBreakdown = MockGetBreakdown();
    getComparison = MockGetComparison();
    getByRange = MockGetByRange();

    when(() => getSummary(any())).thenAnswer((_) async => const Right(summary));
    when(() => getBreakdown(any()))
        .thenAnswer((_) async => const Right(breakdown));
    when(() => getComparison(any()))
        .thenAnswer((_) async => const Right(comparison));
    when(() => getByRange(any())).thenAnswer((_) async => Right(transactions));
  });

  DashboardBloc buildBloc() =>
      DashboardBloc(getSummary, getBreakdown, getComparison, getByRange);

  group('DashboardBloc', () {
    test('initial state is DashboardInitial', () {
      expect(buildBloc().state, const DashboardInitial());
    });

    blocTest<DashboardBloc, DashboardState>(
      'loads the current month dashboard',
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadDashboard()),
      expect: () => [
        const DashboardLoading(),
        DashboardLoaded(
          summary: summary,
          breakdown: breakdown,
          comparison: comparison,
          recentTransactions: transactions,
          start: monthStart(),
          end: monthEnd(),
        ),
      ],
    );

    blocTest<DashboardBloc, DashboardState>(
      'emits empty when the period has no transactions',
      setUp: () {
        when(() => getByRange(any())).thenAnswer((_) async => const Right([]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadDashboard()),
      expect: () => [
        const DashboardLoading(),
        DashboardEmpty(start: monthStart(), end: monthEnd()),
      ],
    );

    blocTest<DashboardBloc, DashboardState>(
      'emits failure when the summary query fails',
      setUp: () {
        when(() => getSummary(any()))
            .thenAnswer((_) async => const Left(CacheFailure('Store down.')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadDashboard()),
      expect: () => [
        const DashboardLoading(),
        const DashboardFailure('Store down.'),
      ],
    );

    blocTest<DashboardBloc, DashboardState>(
      'emits failure when the breakdown query fails',
      setUp: () {
        when(() => getBreakdown(any()))
            .thenAnswer((_) async => const Left(CacheFailure('No data.')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadDashboard()),
      expect: () => [
        const DashboardLoading(),
        const DashboardFailure('No data.'),
      ],
    );

    blocTest<DashboardBloc, DashboardState>(
      'changes the date range and reloads',
      build: buildBloc,
      act: (bloc) => bloc.add(
        ChangeDateRange(
          start: DateTime.utc(2026, 1, 1),
          end: DateTime.utc(2026, 1, 31),
        ),
      ),
      expect: () => [
        const DashboardLoading(),
        DashboardLoaded(
          summary: summary,
          breakdown: breakdown,
          comparison: comparison,
          recentTransactions: transactions,
          start: DateTime.utc(2026, 1, 1),
          end: DateTime.utc(2026, 1, 31),
        ),
      ],
      verify: (_) {
        verify(
          () => getSummary(
            DashboardRangeParams(
              start: DateTime.utc(2026, 1, 1),
              end: DateTime.utc(2026, 1, 31),
            ),
          ),
        ).called(1);
      },
    );

    blocTest<DashboardBloc, DashboardState>(
      'rejects a reversed range',
      build: buildBloc,
      act: (bloc) => bloc.add(
        ChangeDateRange(
          start: DateTime.utc(2026, 2, 1),
          end: DateTime.utc(2026, 1, 1),
        ),
      ),
      expect: () => [
        const DashboardFailure('The start date must be before the end date.'),
      ],
      verify: (_) {
        verifyNever(() => getSummary(any()));
      },
    );

    blocTest<DashboardBloc, DashboardState>(
      'refreshes the current period',
      build: buildBloc,
      act: (bloc) => bloc.add(const RefreshData()),
      expect: () => [
        const DashboardLoading(),
        DashboardLoaded(
          summary: summary,
          breakdown: breakdown,
          comparison: comparison,
          recentTransactions: transactions,
          start: monthStart(),
          end: monthEnd(),
        ),
      ],
    );

    blocTest<DashboardBloc, DashboardState>(
      'limits recent activity to five transactions',
      setUp: () {
        final many = List.generate(
          6,
          (index) => TransactionEntity(
            id: 'tx-$index',
            amount: 10,
            type: TransactionType.expense,
            category: 'Food',
            description: '',
            date: DateTime.utc(2026, 10, index + 1),
          ),
        );
        when(() => getByRange(any())).thenAnswer((_) async => Right(many));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadDashboard()),
      verify: (bloc) {
        final state = bloc.state;
        expect(state, isA<DashboardLoaded>());
        expect((state as DashboardLoaded).recentTransactions, hasLength(5));
      },
    );
  });
}
