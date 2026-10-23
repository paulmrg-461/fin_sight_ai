import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/entities/financial_insight_entity.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/repositories/ai_coach_repository.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/usecases/analyze_spending_usecase.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/usecases/get_insights_usecase.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/usecases/get_savings_suggestions_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAiCoachRepository extends Mock implements AiCoachRepository {}

void main() {
  late MockAiCoachRepository repository;

  final insight = FinancialInsightEntity(
    id: 'i-1',
    type: InsightType.suggestion,
    content: 'Save more.',
    timestamp: DateTime.utc(2026, 10, 22),
  );

  setUp(() {
    repository = MockAiCoachRepository();
  });

  group('GetInsightsUseCase', () {
    test('delegates the context and returns insights', () async {
      when(() => repository.getFinancialInsights('ctx'))
          .thenAnswer((_) async => Right([insight]));

      final result = await GetInsightsUseCase(repository)('ctx');

      expect(result.getOrElse((_) => const <FinancialInsightEntity>[]), [
        insight,
      ]);
    });

    test('propagates failures', () async {
      const failure = ServerFailure('Down.');
      when(() => repository.getFinancialInsights(any()))
          .thenAnswer((_) async => const Left(failure));

      final result = await GetInsightsUseCase(repository)('ctx');

      expect(result.getLeft().toNullable(), failure);
    });
  });

  group('AnalyzeSpendingUseCase', () {
    test('returns the analysis', () async {
      when(() => repository.analyzeSpending('ctx'))
          .thenAnswer((_) async => Right(insight));

      final result = await AnalyzeSpendingUseCase(repository)('ctx');

      expect(result.getOrElse((_) => fail('Expected insight')), insight);
    });

    test('propagates failures', () async {
      const failure = ServerFailure('Down.');
      when(() => repository.analyzeSpending(any()))
          .thenAnswer((_) async => const Left(failure));

      final result = await AnalyzeSpendingUseCase(repository)('ctx');

      expect(result.getLeft().toNullable(), failure);
    });
  });

  group('GetSavingsSuggestionsUseCase', () {
    test('returns the suggestion', () async {
      when(() => repository.getSavingsSuggestions('ctx'))
          .thenAnswer((_) async => Right(insight));

      final result = await GetSavingsSuggestionsUseCase(repository)('ctx');

      expect(result.getOrElse((_) => fail('Expected insight')), insight);
    });

    test('propagates failures', () async {
      const failure = ServerFailure('Down.');
      when(() => repository.getSavingsSuggestions(any()))
          .thenAnswer((_) async => const Left(failure));

      final result = await GetSavingsSuggestionsUseCase(repository)('ctx');

      expect(result.getLeft().toNullable(), failure);
    });
  });
}
