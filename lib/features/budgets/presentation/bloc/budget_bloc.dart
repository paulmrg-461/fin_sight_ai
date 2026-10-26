import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/budget_usecases.dart';
import 'budget_event.dart';
import 'budget_state.dart';

/// Coordinates monthly budgets and category aggregation.
@injectable
class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  BudgetBloc(
    this._addBudget,
    this._updateBudget,
    this._deleteBudget,
    this._getProgress,
    this._getCategories,
  ) : super(const BudgetInitial()) {
    on<LoadBudgets>(_onLoad);
    on<ChangeBudgetMonth>(_onChangeMonth);
    on<AddBudget>(_onAdd);
    on<UpdateBudget>(_onUpdate);
    on<DeleteBudget>(_onDelete);
  }

  final AddBudgetUseCase _addBudget;
  final UpdateBudgetUseCase _updateBudget;
  final DeleteBudgetUseCase _deleteBudget;
  final GetBudgetProgressUseCase _getProgress;
  final GetCategoriesUseCase _getCategories;

  late DateTime _selectedMonth = _currentMonth;

  DateTime get _month => _selectedMonth;

  DateTime get _currentMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  Future<void> _onChangeMonth(
    ChangeBudgetMonth event,
    Emitter<BudgetState> emit,
  ) async {
    _selectedMonth = DateTime(event.month.year, event.month.month);
    await _reload(emit);
  }

  Future<void> _onLoad(LoadBudgets event, Emitter<BudgetState> emit) =>
      _reload(emit);

  Future<void> _onAdd(AddBudget event, Emitter<BudgetState> emit) async {
    emit(const BudgetLoading());
    final result = await _addBudget(
      AddBudgetParams(
        category: event.category,
        monthlyLimit: event.monthlyLimit,
        month: _month,
      ),
    );
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      emit(BudgetFailure(failure.message));
      return;
    }
    await _reload(emit);
  }

  Future<void> _onUpdate(UpdateBudget event, Emitter<BudgetState> emit) async {
    emit(const BudgetLoading());
    final result = await _updateBudget(
      UpdateBudgetParams(
        id: event.id,
        category: event.category,
        monthlyLimit: event.monthlyLimit,
        month: event.month,
      ),
    );
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      emit(BudgetFailure(failure.message));
      return;
    }
    await _reload(emit);
  }

  Future<void> _onDelete(DeleteBudget event, Emitter<BudgetState> emit) async {
    emit(const BudgetLoading());
    final result = await _deleteBudget(event.id);
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      emit(BudgetFailure(failure.message));
      return;
    }
    await _reload(emit);
  }

  Future<void> _reload(Emitter<BudgetState> emit) async {
    emit(const BudgetLoading());

    final progressResult = await _getProgress(_month);
    final failure = progressResult.getLeft().toNullable();
    if (failure != null) {
      emit(BudgetFailure(failure.message));
      return;
    }

    final categoriesResult = await _getCategories(const NoParams());
    final categoriesFailure = categoriesResult.getLeft().toNullable();
    if (categoriesFailure != null) {
      emit(BudgetFailure(categoriesFailure.message));
      return;
    }

    final progress = progressResult.getOrElse((_) => const []);
    final categories = categoriesResult.getOrElse((_) => const []);
    if (progress.isEmpty) {
      emit(BudgetEmpty(categories: categories, month: _month));
    } else {
      emit(
        BudgetLoaded(progress: progress, categories: categories, month: _month),
      );
    }
  }
}
