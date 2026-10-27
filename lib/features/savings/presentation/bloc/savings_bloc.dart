import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/savings_usecases.dart';
import 'savings_event.dart';
import 'savings_state.dart';

@injectable
class SavingsBloc extends Bloc<SavingsEvent, SavingsState> {
  SavingsBloc(
    this._getGoals,
    this._createGoal,
    this._updateGoal,
    this._addContribution,
    this._deleteGoal,
  ) : super(const SavingsInitial()) {
    on<LoadSavingsGoals>(_onLoad);
    on<CreateSavingsGoalEvent>(_onCreate);
    on<UpdateSavingsGoalEvent>(_onUpdate);
    on<AddSavingsContributionEvent>(_onContribute);
    on<DeleteSavingsGoalEvent>(_onDelete);
  }

  final GetSavingsGoalsUseCase _getGoals;
  final CreateSavingsGoalUseCase _createGoal;
  final UpdateSavingsGoalUseCase _updateGoal;
  final AddSavingsContributionUseCase _addContribution;
  final DeleteSavingsGoalUseCase _deleteGoal;

  Future<void> _onLoad(LoadSavingsGoals event, Emitter<SavingsState> emit) =>
      _reload(emit);

  Future<void> _onCreate(
    CreateSavingsGoalEvent event,
    Emitter<SavingsState> emit,
  ) async {
    emit(const SavingsLoading());
    final result = await _createGoal(event.params);
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      emit(SavingsFailure(failure.message));
      return;
    }
    await _reload(emit);
  }

  Future<void> _onUpdate(
    UpdateSavingsGoalEvent event,
    Emitter<SavingsState> emit,
  ) async {
    emit(const SavingsLoading());
    final result = await _updateGoal(event.params);
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      emit(SavingsFailure(failure.message));
      return;
    }
    await _reload(emit);
  }

  Future<void> _onContribute(
    AddSavingsContributionEvent event,
    Emitter<SavingsState> emit,
  ) async {
    emit(const SavingsLoading());
    final result = await _addContribution(event.params);
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      emit(SavingsFailure(failure.message));
      return;
    }
    await _reload(emit);
  }

  Future<void> _onDelete(
    DeleteSavingsGoalEvent event,
    Emitter<SavingsState> emit,
  ) async {
    emit(const SavingsLoading());
    final result = await _deleteGoal(event.id);
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      emit(SavingsFailure(failure.message));
      return;
    }
    await _reload(emit);
  }

  Future<void> _reload(Emitter<SavingsState> emit) async {
    emit(const SavingsLoading());
    final result = await _getGoals(const NoParams());
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      emit(SavingsFailure(failure.message));
      return;
    }
    final goals = result.getOrElse((_) => const []);
    emit(goals.isEmpty ? const SavingsEmpty() : SavingsLoaded(goals));
  }
}
