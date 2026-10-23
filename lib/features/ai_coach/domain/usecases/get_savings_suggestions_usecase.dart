import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../entities/financial_insight_entity.dart';
import '../repositories/ai_coach_repository.dart';

/// Produces tailored savings suggestions.
@lazySingleton
class GetSavingsSuggestionsUseCase
    implements UseCase<FinancialInsightEntity, String> {
  const GetSavingsSuggestionsUseCase(this._repository);

  final AiCoachRepository _repository;

  @override
  ResultFuture<FinancialInsightEntity> call(String context) =>
      _repository.getSavingsSuggestions(context);
}
