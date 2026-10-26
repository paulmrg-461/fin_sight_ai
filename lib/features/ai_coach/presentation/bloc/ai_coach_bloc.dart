import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/domain/usecases/get_transactions_usecase.dart';
import '../../domain/entities/financial_insight_entity.dart';
import '../../domain/repositories/insight_cache.dart';
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
        emit(AiCoachLoaded(cached, fromCache: true));
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
    await _cache.write(event.languageCode, insights);
    emit(AiCoachLoaded(insights));
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
    await _cache.write(event.languageCode, insights);
    emit(AiCoachLoaded(insights));
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
    await _cache.write(event.languageCode, insights);
    emit(AiCoachLoaded(insights));
  }

  List<FinancialInsightEntity> get _currentInsights {
    final current = state;
    return current is AiCoachLoaded ? current.insights : const [];
  }

  Future<String> _buildContext(String languageCode) async {
    final language = languageCode.toLowerCase().startsWith('es')
        ? 'Spanish'
        : 'English';
    final result = await _getTransactions(const NoParams());
    final transactions = result.getOrElse((_) => const <TransactionEntity>[]);
    if (transactions.isEmpty) {
      return 'No transactions recorded yet. Write the response in $language.';
    }

    var income = 0.0;
    var expenses = 0.0;
    final expensesByCategory = <String, double>{};

    for (final transaction in transactions) {
      if (transaction.isIncome) {
        income += transaction.amount;
      } else {
        expenses += transaction.amount;
        expensesByCategory.update(
          transaction.category,
          (value) => value + transaction.amount,
          ifAbsent: () => transaction.amount,
        );
      }
    }

    final topCategories = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final categorySummary = topCategories
        .take(3)
        .map((entry) => '${entry.key}: \$${entry.value.toStringAsFixed(2)}')
        .join(', ');

    return 'Transactions: ${transactions.length}. '
        'Income: \$${income.toStringAsFixed(2)}. '
        'Expenses: \$${expenses.toStringAsFixed(2)}. '
        'Balance: \$${(income - expenses).toStringAsFixed(2)}. '
        'Top expense categories: '
        '${categorySummary.isEmpty ? 'none' : categorySummary}. '
        'Write the response in $language.';
  }
}
