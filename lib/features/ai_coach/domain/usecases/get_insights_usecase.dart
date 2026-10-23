import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/financial_insight_entity.dart';
import '../repositories/ai_coach_repository.dart';

/// Loads a personalized set of insights.
@lazySingleton
class GetInsightsUseCase
    implements UseCase<List<FinancialInsightEntity>, String> {
  const GetInsightsUseCase(this._repository);

  final AiCoachRepository _repository;

  @override
  ResultFuture<List<FinancialInsightEntity>> call(String context) =>
      _repository.getFinancialInsights(context);
}
