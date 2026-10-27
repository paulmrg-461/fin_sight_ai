import 'package:equatable/equatable.dart';

import '../../domain/entities/financial_insight_entity.dart';
import '../../domain/entities/insight_history_entry.dart';

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
  const AiCoachLoaded(
    this.insights, {
    this.fromCache = false,
    this.history = const [],
  });

  final List<FinancialInsightEntity> insights;

  /// True when the network failed and these came from the local cache.
  final bool fromCache;

  /// Previous generations, newest first.
  final List<InsightHistoryEntry> history;

  @override
  List<Object?> get props => [insights, fromCache, history];
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
