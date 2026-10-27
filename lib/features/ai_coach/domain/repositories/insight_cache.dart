import '../entities/financial_insight_entity.dart';
import '../entities/insight_history_entry.dart';

/// Persists the last generated insights so the coach works offline.
abstract interface class InsightCache {
  /// Cached insights for [languageCode], or `null` when none exist.
  Future<List<FinancialInsightEntity>?> read(String languageCode);

  /// Saves the latest batch and appends it to the history (capped).
  Future<void> write(
    String languageCode,
    List<FinancialInsightEntity> insights, {
    InsightHistoryKind kind = InsightHistoryKind.insights,
    DateTime? createdAt,
  });

  /// Newest-first history for [languageCode].
  Future<List<InsightHistoryEntry>> readHistory(String languageCode);

  Future<void> clear();
}
