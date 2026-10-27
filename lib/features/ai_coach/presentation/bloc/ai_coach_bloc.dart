import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../debts/domain/entities/debt_entity.dart';
import '../../../debts/domain/usecases/get_debts_usecase.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/domain/usecases/get_transactions_usecase.dart';
import '../../domain/entities/financial_insight_entity.dart';
import '../../domain/entities/insight_history_entry.dart';
import '../../domain/repositories/insight_cache.dart';
import '../../domain/services/coach_context_builder.dart';
import '../../domain/usecases/analyze_spending_usecase.dart';
import '../../domain/usecases/get_insights_usecase.dart';
import '../../domain/usecases/get_savings_suggestions_usecase.dart';
import 'ai_coach_event.dart';
import 'ai_coach_state.dart';

/// Coordinates coaching use cases and builds context from real transactions.
@injectable
class AiCoachBloc extends Bloc<AiCoachEvent, AiCoachState> {
  AiCoachBloc(
    this._getInsights,
    this._analyzeSpending,
    this._getSuggestions,
    this._getTransactions,
    this._getDebts,
    this._cache,
  ) : super(const AiCoachInitial()) {
    on<LoadInsights>(_onLoadInsights);
    on<AnalyzeSpending>(_onAnalyzeSpending);
    on<GetSuggestions>(_onGetSuggestions);
  }

  final GetInsightsUseCase _getInsights;
  final AnalyzeSpendingUseCase _analyzeSpending;
  final GetSavingsSuggestionsUseCase _getSuggestions;
  final GetTransactionsUseCase _getTransactions;
  final GetDebtsUseCase _getDebts;
  final InsightCache _cache;

  Future<void> _onLoadInsights(
    LoadInsights event,
    Emitter<AiCoachState> emit,
  ) async {
    emit(const AiCoachLoading());
    final context = await _buildContext(event.languageCode);
    final result = await _getInsights(context);
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      final cached = await _cache.read(event.languageCode);
      if (cached != null && cached.isNotEmpty) {
        emit(
          AiCoachLoaded(
            cached,
            fromCache: true,
            history: await _history(event.languageCode),
          ),
        );
        return;
      }
      emit(AiCoachFailure(failure.message));
      return;
    }

    final insights = result.getOrElse((_) => const <FinancialInsightEntity>[]);
    if (insights.isEmpty) {
      emit(const AiCoachEmpty());
      return;
    }
    await _cache.write(
      event.languageCode,
      insights,
      kind: InsightHistoryKind.insights,
    );
    emit(AiCoachLoaded(insights, history: await _history(event.languageCode)));
  }

  Future<void> _onAnalyzeSpending(
    AnalyzeSpending event,
    Emitter<AiCoachState> emit,
  ) async {
    final previous = _currentInsights;
    emit(const AiCoachLoading());
    final context = await _buildContext(event.languageCode);
    final result = await _analyzeSpending(context);
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      if (previous.isNotEmpty) {
        emit(AiCoachLoaded(previous, fromCache: true));
        return;
      }
      emit(AiCoachFailure(failure.message));
      return;
    }
    final insight = result.toNullable();
    if (insight == null) {
      return;
    }
    final insights = [insight, ...previous];
    await _cache.write(
      event.languageCode,
      insights,
      kind: InsightHistoryKind.analysis,
    );
    emit(AiCoachLoaded(insights, history: await _history(event.languageCode)));
  }

  Future<void> _onGetSuggestions(
    GetSuggestions event,
    Emitter<AiCoachState> emit,
  ) async {
    final previous = _currentInsights;
    emit(const AiCoachLoading());
    final context = await _buildContext(event.languageCode);
    final result = await _getSuggestions(context);
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      if (previous.isNotEmpty) {
        emit(AiCoachLoaded(previous, fromCache: true));
        return;
      }
      emit(AiCoachFailure(failure.message));
      return;
    }
    final insight = result.toNullable();
    if (insight == null) {
      return;
    }
    final insights = [insight, ...previous];
    await _cache.write(
      event.languageCode,
      insights,
      kind: InsightHistoryKind.suggestions,
    );
    emit(AiCoachLoaded(insights, history: await _history(event.languageCode)));
  }

  Future<List<InsightHistoryEntry>> _history(String languageCode) =>
      _cache.readHistory(languageCode);

  List<FinancialInsightEntity> get _currentInsights {
    final current = state;
    return current is AiCoachLoaded ? current.insights : const [];
  }

  Future<String> _buildContext(String languageCode) async {
    final transactionsResult = await _getTransactions(const NoParams());
    final debtsResult = await _getDebts(const NoParams());
    return CoachContextBuilder.build(
      transactions: transactionsResult.getOrElse(
        (_) => const <TransactionEntity>[],
      ),
      debts: debtsResult.getOrElse((_) => const <DebtEntity>[]),
      languageCode: languageCode,
    );
  }
}
