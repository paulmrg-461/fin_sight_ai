import 'package:fin_sight_ai/features/ai_coach/data/parsers/insight_parser.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/entities/financial_insight_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = InsightParser();

  group('InsightParser', () {
    test('parses a JSON array of insights', () {
      final insights = parser.parse('''
[
  {"type": "suggestion", "content": "Cut subscriptions.", "relatedTransactionId": null},
  {"type": "alert", "content": "Dining is up 30%.", "relatedTransactionId": "tx-1"}
]
''');

      expect(insights, hasLength(2));
      expect(insights.first.type, InsightType.suggestion);
      expect(insights.first.content, 'Cut subscriptions.');
      expect(insights.first.relatedTransactionId, isNull);
      expect(insights.last.type, InsightType.alert);
      expect(insights.last.relatedTransactionId, 'tx-1');
    });

    test('parses a single JSON object', () {
      final insights = parser.parse(
        '{"type":"analysis","content":"Spending is stable."}',
      );

      expect(insights.single.type, InsightType.analysis);
      expect(insights.single.content, 'Spending is stable.');
    });

    test('strips markdown code fences', () {
      final insights = parser.parse(
        '```json\n{"type":"suggestion","content":"Save more."}\n```',
      );

      expect(insights.single.content, 'Save more.');
    });

    test('parses arrays of plain strings', () {
      final insights = parser.parse('["First tip", "Second tip"]');

      expect(insights, hasLength(2));
      expect(insights.first.content, 'First tip');
      expect(insights.last.type, InsightType.analysis);
    });

    test('falls back to plain text as an analysis', () {
      final insights = parser.parse('You are spending too much on coffee.');

      expect(insights.single.type, InsightType.analysis);
      expect(insights.single.content, 'You are spending too much on coffee.');
    });

    test('maps unknown types to analysis', () {
      final insights = parser.parse(
        '{"type":"promotion","content":"Consider a budget."}',
      );

      expect(insights.single.type, InsightType.analysis);
    });

    test('accepts insight and message aliases for content', () {
      final alias = parser.parse('{"insight":"Use cash for groceries."}');
      final message = parser.parse('{"message":"Automate savings."}');

      expect(alias.single.content, 'Use cash for groceries.');
      expect(message.single.content, 'Automate savings.');
    });

    test('skips entries without content and falls back when all are empty', () {
      final insights = parser.parse('[{"type":"suggestion"}]');

      expect(insights.single.content, contains('suggestion'));
    });

    test('returns an empty list for blank input', () {
      expect(parser.parse('   '), isEmpty);
    });
  });
}
