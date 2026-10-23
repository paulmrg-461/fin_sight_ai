import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/financial_insight_entity.dart';
import '../repositories/ai_coach_repository.dart';

/// Produces a spending analysis.
@lazySingleton
class AnalyzeSpendingUseCase
    implements UseCase<FinancialInsightEntity, String> {
  const AnalyzeSpendingUseCase(this._repository);

  final AiCoachRepository _repository;

  @override
  ResultFuture<FinancialInsightEntity> call(String context) =>
      _repository.analyzeSpending(context);
}
