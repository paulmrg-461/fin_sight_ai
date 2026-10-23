import 'package:fin_sight_ai/features/ai_coach/domain/entities/financial_insight_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final timestamp = DateTime.utc(2026, 10, 22, 12);

  FinancialInsightEntity buildInsight() {
    return FinancialInsightEntity(
      id: 'i-1',
      type: InsightType.suggestion,
      content: 'Save more.',
      timestamp: timestamp,
      relatedTransactionId: 'tx-1',
    );
  }

  group('FinancialInsightEntity', () {
    test('copyWith replaces only provided fields', () {
      final original = buildInsight();

      final updated = original.copyWith(
        type: InsightType.alert,
        content: 'Overspending.',
      );

      expect(updated.type, InsightType.alert);
      expect(updated.content, 'Overspending.');
      expect(updated.id, original.id);
      expect(updated.relatedTransactionId, original.relatedTransactionId);
    });

    test('uses value equality across all fields', () {
      final first = buildInsight();
      final second = buildInsight();

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, isNot(second.copyWith(type: InsightType.analysis)));
      expect(first, isNot(second.copyWith(content: 'Other')));
      expect(first, isNot(second.copyWith(timestamp: DateTime.utc(2027))));
      expect(first, isNot(second.copyWith(relatedTransactionId: 'tx-2')));
    });

    test('toString exposes the type and content', () {
      final description = buildInsight().toString();

      expect(description, contains('suggestion'));
      expect(description, contains('Save more.'));
    });
  });
}
