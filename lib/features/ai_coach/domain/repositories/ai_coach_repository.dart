import '../../../../core/usecase/usecase.dart';
import '../entities/financial_insight_entity.dart';

/// Domain contract for Groq-backed financial coaching.
abstract interface class AiCoachRepository {
  /// Returns a list of suggestions, alerts, and analyses for [context].
  ResultFuture<List<FinancialInsightEntity>> getFinancialInsights(
    String context,
  );

  /// Analyzes the user's spending for [context].
  ResultFuture<FinancialInsightEntity> analyzeSpending(String context);

  /// Returns savings suggestions for [context].
  ResultFuture<FinancialInsightEntity> getSavingsSuggestions(String context);
}
