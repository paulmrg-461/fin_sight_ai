import 'package:bloc_test/bloc_test.dart';
import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/add_transaction_usecase.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/delete_transaction_usecase.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/get_transactions_by_date_range_usecase.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/update_transaction_usecase.dart';
import 'package:fin_sight_ai/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:fin_sight_ai/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:fin_sight_ai/features/transactions/presentation/bloc/transaction_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetTransactions extends Mock implements GetTransactionsUseCase {}

class MockAddTransaction extends Mock implements AddTransactionUseCase {}

class MockDeleteTransaction extends Mock implements DeleteTransactionUseCase {}

class MockUpdateTransaction extends Mock implements UpdateTransactionUseCase {}

class MockGetTransactionsByDateRange extends Mock
    implements GetTransactionsByDateRangeUseCase {}

void main() {
  late MockGetTransactions getTransactions;
  late MockAddTransaction addTransaction;
  late MockDeleteTransaction deleteTransaction;
  late MockGetTransactionsByDateRange getByDateRange;
  late MockUpdateTransaction updateTransaction;

  final transaction = TransactionEntity(
    id: 'tx-1',
    amount: 10,
    type: TransactionType.expense,
    category: 'Coffee',
    description: 'Morning',
    date: DateTime.utc(2026, 10, 20),
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      AddTransactionParams(
        amount: 1,
        type: TransactionType.expense,
        category: 'fallback',
        description: '',
        date: DateTime.utc(2026),
      ),
    );
    registerFallbackValue(
      UpdateTransactionParams(
        id: 'fallback',
        amount: 1,
        type: TransactionType.expense,
        category: 'fallback',
        description: '',
        date: DateTime.utc(2026),
      ),
    );
    registerFallbackValue(
      DateRangeParams(
        start: DateTime.utc(2026),
        end: DateTime.utc(2026, 12, 31),
      ),
    );
  });

  setUp(() {
    getTransactions = MockGetTransactions();
    addTransaction = MockAddTransaction();
    deleteTransaction = MockDeleteTransaction();
    getByDateRange = MockGetTransactionsByDateRange();
    updateTransaction = MockUpdateTransaction();
  });

  TransactionBloc buildBloc() => TransactionBloc(
    getTransactions,
    addTransaction,
    deleteTransaction,
    getByDateRange,
    updateTransaction,
  );

  group('TransactionBloc', () {
    test('initial state is TransactionInitial', () {
      expect(buildBloc().state, const TransactionInitial());
    });

    blocTest<TransactionBloc, TransactionState>(
      'loads transactions successfully',
      setUp: () {
        when(() => getTransactions(any()))
            .thenAnswer((_) async => Right([transaction]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadTransactions()),
      expect: () => [
        const TransactionLoading(),
        TransactionLoaded(transactions: [transaction]),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits empty when there are no transactions',
      setUp: () {
        when(() => getTransactions(any()))
            .thenAnswer((_) async => const Right([]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadTransactions()),
      expect: () => [const TransactionLoading(), const TransactionEmpty()],
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits failure when the repository fails',
      setUp: () {
        when(() => getTransactions(any()))
            .thenAnswer((_) async => const Left(CacheFailure('Store down.')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadTransactions()),
      expect: () => [
        const TransactionLoading(),
        const TransactionFailure('Store down.'),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'adds a transaction and reloads the list',
      setUp: () {
        when(() => addTransaction(any()))
            .thenAnswer((_) async => Right(transaction));
        when(() => getTransactions(any()))
            .thenAnswer((_) async => Right([transaction]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        AddTransaction(
          amount: 10,
          type: TransactionType.expense,
          category: 'Coffee',
          description: 'Morning',
          date: DateTime.utc(2026, 10, 20),
        ),
      ),
      expect: () => [
        const TransactionLoading(),
        TransactionLoaded(transactions: [transaction]),
      ],
      verify: (_) {
        verify(() => addTransaction(any())).called(1);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits failure when adding is rejected',
      setUp: () {
        when(() => addTransaction(any())).thenAnswer(
          (_) async => const Left(
            ValidationFailure('Amount must be greater than zero.'),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        AddTransaction(
          amount: 0,
          type: TransactionType.expense,
          category: 'Coffee',
          description: '',
          date: DateTime.utc(2026, 10, 20),
        ),
      ),
      expect: () => [
        const TransactionLoading(),
        const TransactionFailure('Amount must be greater than zero.'),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'updates a transaction and reloads the list',
      setUp: () {
        when(() => updateTransaction(any()))
            .thenAnswer((_) async => Right(transaction));
        when(() => getTransactions(any()))
            .thenAnswer((_) async => Right([transaction]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        UpdateTransaction(
          id: 'tx-1',
          amount: 10,
          type: TransactionType.expense,
          category: 'Coffee',
          description: 'Morning',
          date: DateTime.utc(2026, 10, 20),
        ),
      ),
      expect: () => [
        const TransactionLoading(),
        TransactionLoaded(transactions: [transaction]),
      ],
      verify: (_) {
        verify(() => updateTransaction(any())).called(1);
        verifyNever(() => addTransaction(any()));
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits failure when an update is rejected',
      setUp: () {
        when(() => updateTransaction(any())).thenAnswer(
          (_) async => const Left(
            ValidationFailure(
              'Transaction not found.',
              code: 'transaction_not_found',
            ),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        UpdateTransaction(
          id: 'missing',
          amount: 10,
          type: TransactionType.expense,
          category: 'Coffee',
          description: 'Morning',
          date: DateTime.utc(2026, 10, 20),
        ),
      ),
      expect: () => [
        const TransactionLoading(),
        const TransactionFailure('Transaction not found.'),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'deletes a transaction and reloads the list',
      setUp: () {
        when(() => deleteTransaction(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => getTransactions(any()))
            .thenAnswer((_) async => const Right([]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const DeleteTransaction('tx-1')),
      expect: () => [const TransactionLoading(), const TransactionEmpty()],
      verify: (_) {
        verify(() => deleteTransaction('tx-1')).called(1);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'filters by a valid date range',
      setUp: () {
        when(() => getByDateRange(any()))
            .thenAnswer((_) async => Right([transaction]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        FilterByDateRange(
          start: DateTime.utc(2026, 10, 1),
          end: DateTime.utc(2026, 10, 31),
        ),
      ),
      expect: () => [
        const TransactionLoading(),
        TransactionLoaded(
          transactions: [transaction],
          start: DateTime.utc(2026, 10, 1),
          end: DateTime.utc(2026, 10, 31),
        ),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'rejects a reversed date range',
      build: buildBloc,
      act: (bloc) => bloc.add(
        FilterByDateRange(
          start: DateTime.utc(2026, 11, 1),
          end: DateTime.utc(2026, 10, 1),
        ),
      ),
      expect: () => [
        const TransactionFailure('The start date must be before the end date.'),
      ],
      verify: (_) {
        verifyNever(() => getByDateRange(any()));
      },
    );
  });
}
