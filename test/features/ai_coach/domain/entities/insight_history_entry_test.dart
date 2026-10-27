import 'package:fin_sight_ai/features/ai_coach/domain/entities/financial_insight_entity.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/entities/insight_history_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final timestamp = DateTime.utc(2026, 10, 26, 12);
  final insight = FinancialInsightEntity(
    id: 'i-1',
    type: InsightType.suggestion,
    content: 'Save more.',
    timestamp: timestamp,
  );
  final analysis = insight.copyWith(id: 'i-2', type: InsightType.analysis);

  InsightHistoryEntry entry({
    InsightHistoryKind kind = InsightHistoryKind.insights,
    List<FinancialInsightEntity>? insights,
  }) {
    return InsightHistoryEntry(
      createdAt: timestamp,
      kind: kind,
      insights: insights ?? [insight],
    );
  }

  test('compares by timestamp, kind, and insight contents', () {
    expect(entry(), entry());
    expect(entry().hashCode, entry().hashCode);
    expect(entry(), isNot(entry(kind: InsightHistoryKind.analysis)));
    expect(entry(), isNot(entry(insights: [analysis])));
    expect(entry(), isNot(entry(insights: [insight, analysis])));
    expect(entry(), isNot(Object()));
    expect(entry().toString(), contains('insights'));
  });

  test('accepts the same insight list instance', () {
    final insights = [insight];
    final first = InsightHistoryEntry(
      createdAt: timestamp,
      kind: InsightHistoryKind.suggestions,
      insights: insights,
    );
    final second = InsightHistoryEntry(
      createdAt: timestamp,
      kind: InsightHistoryKind.suggestions,
      insights: insights,
    );

    expect(first, second);
  });
}
