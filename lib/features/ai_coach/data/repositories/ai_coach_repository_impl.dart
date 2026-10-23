import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/clock.dart';
import '../../domain/entities/financial_insight_entity.dart';
import '../../domain/repositories/ai_coach_repository.dart';
import '../datasources/ai_coach_datasource.dart';
import '../parsers/insight_parser.dart';
import '../prompts/prompt_templates.dart';

/// Builds prompts, calls Groq, and maps responses to domain insights.
@LazySingleton(as: AiCoachRepository)
class AiCoachRepositoryImpl implements AiCoachRepository {
  const AiCoachRepositoryImpl(
    this._datasource, {
    this.uuid = const Uuid(),
    this.clock = const Clock(),
  });

  static const InsightParser _parser = InsightParser();

  final AiCoachDatasource _datasource;
  final Uuid uuid;
  final Clock clock;

  @override
  ResultFuture<List<FinancialInsightEntity>> getFinancialInsights(
    String context,
  ) async {
    final raw = await _call(PromptTemplates.insights, context);
    final failure = raw.getLeft().toNullable();
    if (failure != null) {
      return Left(failure);
    }

    final parsed = _parser.parse(raw.getOrElse((_) => ''));
    if (parsed.isEmpty) {
      return const Left(
        ServerFailure(
          'The AI coach returned an empty response.',
          code: 'groq_empty_content',
        ),
      );
    }
    return Right(
      List<FinancialInsightEntity>.unmodifiable(parsed.map(_toEntity)),
    );
  }

  @override
  ResultFuture<FinancialInsightEntity> analyzeSpending(String context) =>
      _singleInsight(PromptTemplates.spendingAnalysis, context);

  @override
  ResultFuture<FinancialInsightEntity> getSavingsSuggestions(String context) =>
      _singleInsight(PromptTemplates.savingsSuggestions, context);

  Future<Result<FinancialInsightEntity>> _singleInsight(
    String prompt,
    String context,
  ) async {
    final raw = await _call(prompt, context);
    final failure = raw.getLeft().toNullable();
    if (failure != null) {
      return Left(failure);
    }

    final parsed = _parser.parse(raw.getOrElse((_) => ''));
    if (parsed.isEmpty) {
      return const Left(
        ServerFailure(
          'The AI coach returned an empty response.',
          code: 'groq_empty_content',
        ),
      );
    }
    return Right(_toEntity(parsed.first));
  }

  Future<Result<String>> _call(String prompt, String context) async {
    try {
      return Right(await _datasource.callGroqApi(prompt, context));
    } on ServerException catch (exception) {
      return Left(
        ServerFailure(
          'Unable to reach the AI coach. Please try again.',
          code: exception.code,
        ),
      );
    } catch (_) {
      return const Left(
        ServerFailure(
          'Unable to reach the AI coach. Please try again.',
          code: 'ai_coach_failed',
        ),
      );
    }
  }

  FinancialInsightEntity _toEntity(ParsedInsight insight) {
    return FinancialInsightEntity(
      id: uuid.v4(),
      type: insight.type,
      content: insight.content,
      timestamp: clock.now(),
      relatedTransactionId: insight.relatedTransactionId,
    );
  }
}
