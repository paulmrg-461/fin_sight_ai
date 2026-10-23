import 'package:equatable/equatable.dart';

import '../../domain/entities/financial_insight_entity.dart';

/// Base state for the AI coach.
sealed class AiCoachState extends Equatable {
  const AiCoachState();

  @override
  List<Object?> get props => const [];
}

final class AiCoachInitial extends AiCoachState {
  const AiCoachInitial();
}

final class AiCoachLoading extends AiCoachState {
  const AiCoachLoading();
}

final class AiCoachLoaded extends AiCoachState {
  const AiCoachLoaded(this.insights);

  final List<FinancialInsightEntity> insights;

  @override
  List<Object?> get props => [insights];
}

final class AiCoachEmpty extends AiCoachState {
  const AiCoachEmpty();
}

final class AiCoachFailure extends AiCoachState {
  const AiCoachFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
