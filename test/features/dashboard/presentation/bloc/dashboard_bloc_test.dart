import 'package:bloc_test/bloc_test.dart';
import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/features/dashboard/domain/entities/dashboard_entities.dart';
import 'package:fin_sight_ai/features/dashboard/domain/usecases/dashboard_usecases.dart';
import 'package:fin_sight_ai/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:fin_sight_ai/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:fin_sight_ai/features/dashboard/presentation/bloc/dashboard_state.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetDashboardData extends Mock implements GetDashboardDataUseCase {}

void main() {
  late MockGetDashboardData getDashboard;

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

  DashboardData dataFor(DateTime start, DateTime end) => DashboardData(
    summary: summary,
    breakdown: breakdown,
    comparison: comparison,
    recentTransactions: transactions,
    start: start,
    end: end,
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      DashboardRangeParams(
        start: DateTime.utc(2026, 10, 1),
        end: DateTime.utc(2026, 10, 31),
      ),
    );
  });

  setUp(() {
    getDashboard = MockGetDashboardData();

    when(() => getDashboard(any())).thenAnswer((invocation) async {
      final params =
          invocation.positionalArguments.first as DashboardRangeParams;
      return Right(dataFor(params.start, params.end));
    });
  });

  DashboardBloc buildBloc() => DashboardBloc(getDashboard);

  group('DashboardBloc', () {
    test('initial state is DashboardInitial', () {
      expect(buildBloc().state, const DashboardInitial());
    });

    blocTest<DashboardBloc, DashboardState>(
      'loads the current month dashboard in one aggregation',
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
      verify: (_) {
        verify(() => getDashboard(any())).called(1);
      },
    );

    blocTest<DashboardBloc, DashboardState>(
      'emits empty when the period has no transactions',
      setUp: () {
        when(() => getDashboard(any())).thenAnswer(
          (_) async => Right(
            DashboardData(
              summary: const DashboardSummaryEntity(
                totalIncome: 0,
                totalExpenses: 0,
                balance: 0,
                savingsRate: 0,
                monthOverMonthChange: 0,
              ),
              breakdown: const [],
              comparison: const MonthlyComparisonEntity(
                currentIncome: 0,
                currentExpenses: 0,
                previousIncome: 0,
                previousExpenses: 0,
                expenseChangePercentage: 0,
              ),
              recentTransactions: const [],
              start: monthStart(),
              end: monthEnd(),
            ),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadDashboard()),
      expect: () => [
        const DashboardLoading(),
        DashboardEmpty(start: monthStart(), end: monthEnd()),
      ],
    );

    blocTest<DashboardBloc, DashboardState>(
      'emits failure when the aggregation fails',
      setUp: () {
        when(() => getDashboard(any()))
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
          () => getDashboard(
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
        verifyNever(() => getDashboard(any()));
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
      'passes the recent activity from the bundle through untouched',
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
        when(() => getDashboard(any())).thenAnswer((invocation) async {
          final params =
              invocation.positionalArguments.first as DashboardRangeParams;
          return Right(
            DashboardData(
              summary: summary,
              breakdown: breakdown,
              comparison: comparison,
              recentTransactions: many,
              start: params.start,
              end: params.end,
            ),
          );
        });
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadDashboard()),
      verify: (bloc) {
        final state = bloc.state;
        expect(state, isA<DashboardLoaded>());
        expect((state as DashboardLoaded).recentTransactions, hasLength(6));
      },
    );
  });
}
