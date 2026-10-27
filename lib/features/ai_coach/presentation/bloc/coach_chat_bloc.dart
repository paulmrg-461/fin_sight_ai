import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../debts/domain/entities/debt_entity.dart';
import '../../../debts/domain/usecases/get_debts_usecase.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../savings/domain/entities/savings_goal_entity.dart';
import '../../../savings/domain/usecases/savings_usecases.dart';
import '../../../transactions/domain/usecases/get_transactions_usecase.dart';
import '../../domain/entities/coach_message.dart';
import '../../domain/repositories/coach_chat_store.dart';
import '../../domain/services/coach_context_builder.dart';
import '../../domain/usecases/ask_coach_usecase.dart';
import 'coach_chat_event.dart';
import 'coach_chat_state.dart';

/// Free-form coaching conversation backed by the financial context.
@injectable
class CoachChatBloc extends Bloc<CoachChatEvent, CoachChatState> {
  CoachChatBloc(
    this._askCoach,
    this._getTransactions,
    this._getDebts,
    this._getSavings,
    this._store, {
    this.uuid = const Uuid(),
  }) : super(const CoachChatInitial()) {
    on<LoadCoachChat>(_onLoad);
    on<SendCoachMessage>(_onSend);
    on<ClearCoachChat>(_onClear);
  }

  final AskCoachUseCase _askCoach;
  final GetTransactionsUseCase _getTransactions;
  final GetDebtsUseCase _getDebts;
  final GetSavingsGoalsUseCase _getSavings;
  final CoachChatStore _store;
  final Uuid uuid;

  Future<void> _onLoad(
    LoadCoachChat event,
    Emitter<CoachChatState> emit,
  ) async {
    emit(const CoachChatLoading());
    emit(CoachChatLoaded(await _store.read()));
  }

  Future<void> _onSend(
    SendCoachMessage event,
    Emitter<CoachChatState> emit,
  ) async {
    final text = event.text.trim();
    if (text.isEmpty) {
      return;
    }
    final current = state;
    final messages = current is CoachChatLoaded
        ? List<CoachMessage>.of(current.messages)
        : <CoachMessage>[];
    if (current is CoachChatLoaded && current.sending) {
      return;
    }

    final userMessage = CoachMessage(
      id: uuid.v4(),
      role: CoachRole.user,
      content: text,
      createdAt: DateTime.now(),
    );
    messages.add(userMessage);
    await _store.append(userMessage);
    emit(CoachChatLoaded(List.unmodifiable(messages), sending: true));

    final result = await _askCoach(
      AskCoachParams(
        question: text,
        context: await _buildContext(event.languageCode),
      ),
    );
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      emit(
        CoachChatLoaded(List.unmodifiable(messages), error: failure.message),
      );
      return;
    }

    final answer = result.getOrElse((_) => '').trim();
    if (answer.isEmpty) {
      emit(
        CoachChatLoaded(
          List.unmodifiable(messages),
          error: 'The AI coach returned an empty response.',
        ),
      );
      return;
    }

    final coachMessage = CoachMessage(
      id: uuid.v4(),
      role: CoachRole.coach,
      content: answer,
      createdAt: DateTime.now(),
    );
    messages.add(coachMessage);
    await _store.append(coachMessage);
    emit(CoachChatLoaded(List.unmodifiable(messages)));
  }

  Future<void> _onClear(
    ClearCoachChat event,
    Emitter<CoachChatState> emit,
  ) async {
    await _store.clear();
    emit(const CoachChatLoaded([]));
  }

  Future<String> _buildContext(String languageCode) async {
    final transactionsResult = await _getTransactions(const NoParams());
    final debtsResult = await _getDebts(const NoParams());
    final savingsResult = await _getSavings(const NoParams());
    return CoachContextBuilder.build(
      transactions: transactionsResult.getOrElse(
        (_) => const <TransactionEntity>[],
      ),
      debts: debtsResult.getOrElse((_) => const <DebtEntity>[]),
      savingsGoals: savingsResult.getOrElse((_) => const <SavingsGoalEntity>[]),
      languageCode: languageCode,
    );
  }
}
