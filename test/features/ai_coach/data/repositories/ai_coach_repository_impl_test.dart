import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/core/utils/clock.dart';
import 'package:fin_sight_ai/features/ai_coach/data/datasources/ai_coach_datasource.dart';
import 'package:fin_sight_ai/features/ai_coach/data/prompts/prompt_templates.dart';
import 'package:fin_sight_ai/features/ai_coach/data/repositories/ai_coach_repository_impl.dart';
import 'package:fin_sight_ai/features/ai_coach/domain/entities/financial_insight_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAiCoachDatasource extends Mock implements AiCoachDatasource {}

class FixedClock extends Clock {
  const FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

void main() {
  final now = DateTime.utc(2026, 10, 22, 12);

  late MockAiCoachDatasource datasource;
  late AiCoachRepositoryImpl repository;

  setUp(() {
    datasource = MockAiCoachDatasource();
    repository = AiCoachRepositoryImpl(datasource, clock: FixedClock(now));
  });

  group('AiCoachRepositoryImpl', () {
    test('parses a list of insights', () async {
      when(() => datasource.callGroqApi(any(), any())).thenAnswer(
        (_) async =>
            '[{"type":"suggestion","content":"Save more."},'
            '{"type":"alert","content":"Overspending.","relatedTransactionId":"tx-1"}]',
      );

      final result = await repository.getFinancialInsights('context');

      final insights = result.getOrElse((_) => fail('Expected insights'));
      expect(insights, hasLength(2));
      expect(insights.first.type, InsightType.suggestion);
      expect(insights.first.id.trim(), isNotEmpty);
      expect(insights.first.timestamp, now);
      expect(insights.last.relatedTransactionId, 'tx-1');
    });

    test('parses a single object for spending analysis', () async {
      when(() => datasource.callGroqApi(any(), any())).thenAnswer(
        (_) async => '{"type":"analysis","content":"Dining dominates."}',
      );

      final result = await repository.analyzeSpending('context');

      final insight = result.getOrElse((_) => fail('Expected insight'));
      expect(insight.type, InsightType.analysis);
      expect(insight.content, 'Dining dominates.');
      verify(
        () =>
            datasource.callGroqApi(PromptTemplates.spendingAnalysis, 'context'),
      ).called(1);
    });

    test('parses savings suggestions', () async {
      when(() => datasource.callGroqApi(any(), any()))
          .thenAnswer((_) async => '{"content":"Automate 10% of income."}');

      final result = await repository.getSavingsSuggestions('context');

      final insight = result.getOrElse((_) => fail('Expected insight'));
      expect(insight.content, 'Automate 10% of income.');
      verify(
        () => datasource.callGroqApi(
          PromptTemplates.savingsSuggestions,
          'context',
        ),
      ).called(1);
    });

    test('falls back to plain text responses', () async {
      when(() => datasource.callGroqApi(any(), any()))
          .thenAnswer((_) async => 'Your balance is healthy.');

      final result = await repository.analyzeSpending('context');

      expect(
        result.getOrElse((_) => fail('Expected insight')).type,
        InsightType.analysis,
      );
    });

    test('rejects empty model content', () async {
      when(() => datasource.callGroqApi(any(), any()))
          .thenAnswer((_) async => '   ');

      final result = await repository.getFinancialInsights('context');

      expect(result.getLeft().toNullable(), isA<ServerFailure>());
      expect(result.getLeft().toNullable()?.code, 'groq_empty_content');
    });

    test('maps ServerException to a safe failure', () async {
      when(() => datasource.callGroqApi(any(), any()))
          .thenThrow(const ServerException('Timeout.', code: 'groq_timeout'));

      final result = await repository.getFinancialInsights('context');

      final failure = result.getLeft().toNullable();
      expect(failure, isA<ServerFailure>());
      expect(failure?.code, 'groq_timeout');
      expect(failure?.message, isNot(contains('Timeout')));
    });

    test('maps unexpected errors to ai_coach_failed', () async {
      when(() => datasource.callGroqApi(any(), any()))
          .thenThrow(StateError('boom'));

      final result = await repository.analyzeSpending('context');

      expect(result.getLeft().toNullable()?.code, 'ai_coach_failed');
    });
  });
}
