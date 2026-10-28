import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fin_sight_ai/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/add_transaction_usecase.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/import_transactions_csv_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockAddTransaction extends Mock implements AddTransactionUseCase {}

void main() {
  late MockTransactionRepository repository;
  late MockAddTransaction addTransaction;
  late ImportTransactionsCsvUseCase useCase;

  final existing = TransactionEntity(
    id: 'tx-1',
    amount: 25000,
    type: TransactionType.expense,
    category: 'Dining',
    description: 'Lunch',
    date: DateTime(2026, 10, 31),
  );

  setUpAll(() {
    registerFallbackValue(
      AddTransactionParams(
        amount: 1,
        type: TransactionType.expense,
        category: 'Other',
        description: '',
        date: DateTime(2026),
      ),
    );
  });

  setUp(() {
    repository = MockTransactionRepository();
    addTransaction = MockAddTransaction();
    useCase = ImportTransactionsCsvUseCase(repository, addTransaction);
    when(() => repository.getTransactions())
        .thenAnswer((_) async => Right([existing]));
    when(() => addTransaction(any())).thenAnswer((_) async => Right(existing));
  });

  test('imports new rows and skips existing duplicates', () async {
    final result = await useCase(
      const ImportTransactionsCsvParams(
        csv:
            'date,type,category,description,amount\n'
            '2026-10-31,expense,Dining,Lunch,25000\n'
            '2026-11-01,expense,Dining,Dinner,30000\n'
            '2026-11-01,expense,Dining,Dinner,30000\n',
      ),
    );

    final summary = result.getOrElse((_) => fail('Expected summary'));
    expect(summary.imported, 1);
    expect(summary.skipped, 2);
    verify(() => addTransaction(any())).called(1);
  });

  test('counts add failures and parse errors', () async {
    when(() => addTransaction(any())).thenAnswer(
      (_) async => const Left(
        ValidationFailure('Invalid amount.', code: 'invalid_amount'),
      ),
    );

    final result = await useCase(
      const ImportTransactionsCsvParams(
        csv:
            'date,type,category,description,amount\n'
            'bad-date,expense,Food,Bad,10\n'
            '2026-11-02,expense,Food,Good,10\n',
      ),
    );

    final summary = result.getOrElse((_) => fail('Expected summary'));
    expect(summary.imported, 0);
    expect(summary.failed, 1);
    expect(summary.errors, hasLength(2));
  });

  test('rejects a CSV with no valid rows', () async {
    final result = await useCase(
      const ImportTransactionsCsvParams(csv: 'date,amount\nbad,\n'),
    );

    expect(result.getLeft().toNullable()?.code, 'csv_no_rows');
  });

  test('propagates repository failures', () async {
    when(() => repository.getTransactions())
        .thenAnswer((_) async => const Left(CacheFailure('Store down.')));

    final result = await useCase(
      const ImportTransactionsCsvParams(csv: '2026-11-02,expense,Food,Good,10'),
    );

    expect(result.getLeft().toNullable()?.message, 'Store down.');
  });
}
