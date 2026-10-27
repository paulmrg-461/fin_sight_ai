import 'financial_insight_entity.dart';

/// What generated a batch of insights.
enum InsightHistoryKind { insights, analysis, suggestions }

/// One saved generation batch shown in the coach history.
class InsightHistoryEntry {
  const InsightHistoryEntry({
    required this.createdAt,
    required this.kind,
    required this.insights,
  });

  final DateTime createdAt;
  final InsightHistoryKind kind;
  final List<FinancialInsightEntity> insights;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InsightHistoryEntry &&
          other.createdAt == createdAt &&
          other.kind == kind &&
          _sameInsights(other.insights, insights);

  @override
  int get hashCode => Object.hash(createdAt, kind, Object.hashAll(insights));

  @override
  String toString() =>
      'InsightHistoryEntry($kind, ${insights.length} insights, $createdAt)';

  static bool _sameInsights(
    List<FinancialInsightEntity> a,
    List<FinancialInsightEntity> b,
  ) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }
}
