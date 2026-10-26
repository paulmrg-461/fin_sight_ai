import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/usecases/add_transaction_usecase.dart';
import '../../domain/usecases/delete_transaction_usecase.dart';
import '../../domain/usecases/get_transactions_by_date_range_usecase.dart';
import '../../domain/usecases/get_transactions_usecase.dart';
import '../../domain/usecases/update_transaction_usecase.dart';
import 'transaction_event.dart';
import 'transaction_state.dart';

/// Coordinates transaction use cases and exposes a single UI state.
@injectable
class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  TransactionBloc(
    this._getTransactions,
    this._addTransaction,
    this._deleteTransaction,
    this._getTransactionsByDateRange,
    this._updateTransaction,
  ) : super(const TransactionInitial()) {
    on<LoadTransactions>(_onLoad);
    on<AddTransaction>(_onAdd);
    on<UpdateTransaction>(_onUpdate);
    on<DeleteTransaction>(_onDelete);
    on<FilterByDateRange>(_onFilter);
    on<SearchTransactions>(_onSearch);
  }

  final GetTransactionsUseCase _getTransactions;
  final AddTransactionUseCase _addTransaction;
  final DeleteTransactionUseCase _deleteTransaction;
  final GetTransactionsByDateRangeUseCase _getTransactionsByDateRange;
  final UpdateTransactionUseCase _updateTransaction;

  DateTime? _start;
  DateTime? _end;
  String _query = '';

  /// Unfiltered rows for the active period, used for in-memory search.
  List<TransactionEntity> _periodTransactions = const [];

  Future<void> _onLoad(
    LoadTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    _start = null;
    _end = null;
    _query = '';
    await _reload(emit);
  }

  Future<void> _onAdd(
    AddTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionLoading());
    final result = await _addTransaction(
      AddTransactionParams(
        amount: event.amount,
        type: event.type,
        category: event.category,
        description: event.description,
        date: event.date,
        receiptImagePath: event.receiptImagePath,
        walletId: event.walletId,
        id: event.id,
      ),
    );

    final failure = result.getLeft().toNullable();
    if (failure != null) {
      emit(TransactionFailure(failure.message));
      return;
    }
    await _reload(emit);
  }

  Future<void> _onUpdate(
    UpdateTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionLoading());
    final result = await _updateTransaction(
      UpdateTransactionParams(
        id: event.id,
        amount: event.amount,
        type: event.type,
        category: event.category,
        description: event.description,
        date: event.date,
        receiptImagePath: event.receiptImagePath,
        walletId: event.walletId,
      ),
    );
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      emit(TransactionFailure(failure.message));
      return;
    }
    await _reload(emit);
  }

  Future<void> _onSearch(
    SearchTransactions event,
    Emitter<TransactionState> emit,
  ) async {
    _query = event.query.trim();
    if (_periodTransactions.isEmpty && state is! TransactionLoaded) {
      await _reload(emit);
      return;
    }

    final filtered = _applyQuery(_periodTransactions);
    if (filtered.isEmpty) {
      emit(TransactionEmpty(start: _start, end: _end, query: _query));
      return;
    }
    emit(
      TransactionLoaded(
        transactions: filtered,
        start: _start,
        end: _end,
        query: _query,
      ),
    );
  }

  Future<void> _onDelete(
    DeleteTransaction event,
    Emitter<TransactionState> emit,
  ) async {
    emit(const TransactionLoading());
    final result = await _deleteTransaction(event.id);
    final failure = result.getLeft().toNullable();
    if (failure != null) {
      emit(TransactionFailure(failure.message));
      return;
    }
    await _reload(emit);
  }

  Future<void> _onFilter(
    FilterByDateRange event,
    Emitter<TransactionState> emit,
  ) async {
    if (event.start.isAfter(event.end)) {
      emit(
        const TransactionFailure('The start date must be before the end date.'),
      );
      return;
    }
    _start = event.start;
    _end = event.end;
    await _reload(emit);
  }

  List<TransactionEntity> _applyQuery(List<TransactionEntity> transactions) {
    final query = _query.toLowerCase();
    if (query.isEmpty) {
      return List<TransactionEntity>.unmodifiable(transactions);
    }
    return List<TransactionEntity>.unmodifiable(
      transactions.where((transaction) {
        return transaction.description.toLowerCase().contains(query) ||
            transaction.category.toLowerCase().contains(query) ||
            transaction.amount.toStringAsFixed(2).contains(query);
      }),
    );
  }

  Future<void> _reload(Emitter<TransactionState> emit) async {
    emit(const TransactionLoading());

    final result = _start == null || _end == null
        ? await _getTransactions(const NoParams())
        : await _getTransactionsByDateRange(
            DateRangeParams(start: _start!, end: _end!),
          );

    final failure = result.getLeft().toNullable();
    if (failure != null) {
      emit(TransactionFailure(failure.message));
      return;
    }

    _periodTransactions = result.getOrElse((_) => const <TransactionEntity>[]);
    final transactions = _applyQuery(_periodTransactions);
    if (transactions.isEmpty) {
      emit(TransactionEmpty(start: _start, end: _end, query: _query));
      return;
    }
    emit(
      TransactionLoaded(
        transactions: transactions,
        start: _start,
        end: _end,
        query: _query,
      ),
    );
  }
}
