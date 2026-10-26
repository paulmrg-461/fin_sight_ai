import '../entities/financial_insight_entity.dart';

/// Persists the last generated insights so the coach works offline.
abstract interface class InsightCache {
  /// Cached insights for [languageCode], or `null` when none exist.
  Future<List<FinancialInsightEntity>?> read(String languageCode);

  Future<void> write(
    String languageCode,
    List<FinancialInsightEntity> insights,
  );

  Future<void> clear();
}
