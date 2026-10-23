import 'package:equatable/equatable.dart';

/// Base event for the AI coach.
sealed class AiCoachEvent extends Equatable {
  const AiCoachEvent();

  @override
  List<Object?> get props => const [];
}

/// Loads a fresh set of personalized insights.
final class LoadInsights extends AiCoachEvent {
  const LoadInsights();
}

/// Requests a spending analysis.
final class AnalyzeSpending extends AiCoachEvent {
  const AnalyzeSpending();
}

/// Requests savings suggestions.
final class GetSuggestions extends AiCoachEvent {
  const GetSuggestions();
}
