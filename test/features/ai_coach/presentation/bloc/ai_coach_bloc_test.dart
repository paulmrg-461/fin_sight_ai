import 'package:bloc_test/bloc_test.dart';
import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/entities/financial_insight_entity.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/usecases/analyze_spending_usecase.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/usecases/get_insights_usecase.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/entities/insight_history_entry.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/repositories/insight_cache.dart';
import 'package:fin_sight_ai/features/debts/domain/entities/debt_entity.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/get_debts_usecase.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/usecases/get_savings_suggestions_usecase.dart';
import 'package:fin_sight_ai/features/ai_coach/presentation/bloc/ai_coach_bloc.dart';
import 'package:fin_sight_ai/features/ai_coach/presentation/bloc/ai_coach_event.dart';
import 'package:fin_sight_ai/features/ai_coach/presentation/bloc/ai_coach_state.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetInsights extends Mock implements GetInsightsUseCase {}

class MockAnalyzeSpending extends Mock implements AnalyzeSpendingUseCase {}

class MockGetSavings extends Mock implements GetSavingsSuggestionsUseCase {}

class MockGetTransactions extends Mock implements GetTransactionsUseCase {}

class MockInsightCache extends Mock implements InsightCache {}

class MockGetDebts extends Mock implements GetDebtsUseCase {}

void main() {
  late MockGetInsights getInsights;
  late MockAnalyzeSpending analyzeSpending;
  late MockGetSavings getSavings;
  late MockGetTransactions getTransactions;
  late MockInsightCache cache;
  late MockGetDebts getDebts;

  final suggestion = FinancialInsightEntity(
    id: 'i-1',
    type: InsightType.suggestion,
    content: 'Save more.',
    timestamp: DateTime.utc(2026, 10, 22),
  );
  final analysis = FinancialInsightEntity(
    id: 'i-2',
    type: InsightType.analysis,
    content: 'Dining dominates.',
    timestamp: DateTime.utc(2026, 10, 22),
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
      amount: 200,
      type: TransactionType.expense,
      category: 'Food',
      description: 'Groceries',
      date: DateTime.utc(2026, 10, 5),
    ),
  ];

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(InsightHistoryKind.insights);
    registerFallbackValue(DateTime.utc(2026));
  });

  setUp(() {
    getInsights = MockGetInsights();
    analyzeSpending = MockAnalyzeSpending();
    getSavings = MockGetSavings();
    getTransactions = MockGetTransactions();
    getDebts = MockGetDebts();
    cache = MockInsightCache();
    when(() => getDebts(any())).thenAnswer((_) async => const Right([]));
    when(() => cache.read(any())).thenAnswer((_) async => null);
    when(() => cache.readHistory(any())).thenAnswer((_) async => const []);
    when(
      () => cache.write(
        any(),
        any(),
        kind: any(named: 'kind'),
        createdAt: any(named: 'createdAt'),
      ),
    ).thenAnswer((_) async {});
    when(() => getTransactions(any()))
        .thenAnswer((_) async => Right(transactions));
  });

  AiCoachBloc buildBloc() => AiCoachBloc(
    getInsights,
    analyzeSpending,
    getSavings,
    getTransactions,
    getDebts,
    cache,
  );

  group('AiCoachBloc', () {
    test('initial state is AiCoachInitial', () {
      expect(buildBloc().state, const AiCoachInitial());
    });

    blocTest<AiCoachBloc, AiCoachState>(
      'loads insights using a transaction-derived context',
      setUp: () {
        when(() => getInsights(any()))
            .thenAnswer((_) async => Right([suggestion]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadInsights()),
      expect: () => [
        const AiCoachLoading(),
        AiCoachLoaded([suggestion]),
      ],
      verify: (_) {
        final context =
            verify(() => getInsights(captureAny())).captured.single as String;
        expect(context, contains('Income: \$1000.00'));
        expect(context, contains('Expenses: \$200.00'));
        expect(context, contains('Food: \$200.00'));
      },
    );

    blocTest<AiCoachBloc, AiCoachState>(
      'asks the model to answer in the active language',
      setUp: () {
        when(() => getInsights(any()))
            .thenAnswer((_) async => Right([suggestion]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadInsights(languageCode: 'es')),
      expect: () => [
        const AiCoachLoading(),
        AiCoachLoaded([suggestion]),
      ],
      verify: (_) {
        final context =
            verify(() => getInsights(captureAny())).captured.single as String;
        expect(context, contains('Write the response in Spanish.'));
      },
    );

    blocTest<AiCoachBloc, AiCoachState>(
      'falls back to cached insights when the network fails',
      setUp: () {
        when(() => getInsights(any()))
            .thenAnswer((_) async => const Left(ServerFailure('Offline.')));
        when(() => cache.read('es')).thenAnswer((_) async => [suggestion]);
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadInsights(languageCode: 'es')),
      expect: () => [
        const AiCoachLoading(),
        AiCoachLoaded([suggestion], fromCache: true),
      ],
      verify: (_) {
        verifyNever(() => cache.write(any(), any()));
      },
    );

    blocTest<AiCoachBloc, AiCoachState>(
      'caches fresh insights for the active language',
      setUp: () {
        when(() => getInsights(any()))
            .thenAnswer((_) async => Right([suggestion]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadInsights(languageCode: 'es')),
      expect: () => [
        const AiCoachLoading(),
        AiCoachLoaded([suggestion]),
      ],
      verify: (_) {
        verify(
          () => cache.write(
            'es',
            [suggestion],
            kind: InsightHistoryKind.insights,
            createdAt: any(named: 'createdAt'),
          ),
        ).called(1);
      },
    );

    blocTest<AiCoachBloc, AiCoachState>(
      'includes active debts in the financial context',
      setUp: () {
        when(() => getInsights(any()))
            .thenAnswer((_) async => Right([suggestion]));
        when(() => getDebts(any())).thenAnswer(
          (_) async => Right([
            DebtEntity(
              id: 'debt-1',
              creditorName: 'Bank',
              totalAmount: 1000,
              remainingAmount: 600,
              interestRate: 24,
              minimumPayment: 120,
              dueDate: DateTime.utc(2026, 11, 5),
            ),
          ]),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadInsights()),
      expect: () => [
        const AiCoachLoading(),
        AiCoachLoaded([suggestion]),
      ],
      verify: (_) {
        final context =
            verify(() => getInsights(captureAny())).captured.single as String;
        expect(context, contains('Debts: 1'));
        expect(context, contains('Total remaining: \$600.00'));
        expect(context, contains('Highest rate: 24.00%'));
      },
    );

    blocTest<AiCoachBloc, AiCoachState>(
      'exposes cached history alongside fresh insights',
      setUp: () {
        when(() => getInsights(any()))
            .thenAnswer((_) async => Right([suggestion]));
        when(() => cache.readHistory('en')).thenAnswer(
          (_) async => [
            InsightHistoryEntry(
              createdAt: DateTime.utc(2026, 10, 25),
              kind: InsightHistoryKind.analysis,
              insights: [analysis],
            ),
          ],
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadInsights()),
      expect: () => [
        const AiCoachLoading(),
        isA<AiCoachLoaded>().having(
          (state) => state.history,
          'history',
          hasLength(1),
        ),
      ],
    );

    blocTest<AiCoachBloc, AiCoachState>(
      'handles an empty transaction history',
      setUp: () {
        when(() => getTransactions(any()))
            .thenAnswer((_) async => const Right([]));
        when(() => getInsights(any())).thenAnswer((_) async => const Right([]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadInsights()),
      expect: () => [const AiCoachLoading(), const AiCoachEmpty()],
      verify: (_) {
        final context =
            verify(() => getInsights(captureAny())).captured.single as String;
        expect(context, contains('No transactions recorded yet.'));
      },
    );

    blocTest<AiCoachBloc, AiCoachState>(
      'emits failure when loading insights fails',
      setUp: () {
        when(() => getInsights(any()))
            .thenAnswer((_) async => const Left(ServerFailure('Offline.')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadInsights()),
      expect: () => [const AiCoachLoading(), const AiCoachFailure('Offline.')],
    );

    blocTest<AiCoachBloc, AiCoachState>(
      'prepends a spending analysis to existing insights',
      setUp: () {
        when(() => analyzeSpending(any()))
            .thenAnswer((_) async => Right(analysis));
      },
      build: buildBloc,
      seed: () => AiCoachLoaded([suggestion]),
      act: (bloc) => bloc.add(const AnalyzeSpending()),
      expect: () => [
        const AiCoachLoading(),
        AiCoachLoaded([analysis, suggestion]),
      ],
    );

    blocTest<AiCoachBloc, AiCoachState>(
      'prepends savings suggestions to existing insights',
      setUp: () {
        when(() => getSavings(any()))
            .thenAnswer((_) async => Right(suggestion));
      },
      build: buildBloc,
      seed: () => AiCoachLoaded([analysis]),
      act: (bloc) => bloc.add(const GetSuggestions()),
      expect: () => [
        const AiCoachLoading(),
        AiCoachLoaded([suggestion, analysis]),
      ],
    );

    blocTest<AiCoachBloc, AiCoachState>(
      'emits failure when an analysis fails',
      setUp: () {
        when(() => analyzeSpending(any()))
            .thenAnswer((_) async => const Left(ServerFailure('Timeout.')));
      },
      build: buildBloc,
      seed: () => AiCoachLoaded([suggestion]),
      act: (bloc) => bloc.add(const AnalyzeSpending()),
      expect: () => [
        const AiCoachLoading(),
        AiCoachLoaded([suggestion], fromCache: true),
      ],
    );
  });
}
