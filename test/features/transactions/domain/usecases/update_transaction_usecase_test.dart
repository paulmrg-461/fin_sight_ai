import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fin_sight_ai/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/update_transaction_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late MockTransactionRepository repository;
  late UpdateTransactionUseCase useCase;

  setUpAll(() {
    registerFallbackValue(
      TransactionEntity(
        id: 'fallback',
        amount: 1,
        type: TransactionType.expense,
        category: 'Other',
        description: '',
        date: DateTime.utc(2026),
      ),
    );
  });

  setUp(() {
    repository = MockTransactionRepository();
    useCase = UpdateTransactionUseCase(repository);
    when(() => repository.updateTransaction(any())).thenAnswer((
      invocation,
    ) async {
      return Right(invocation.positionalArguments.first as TransactionEntity);
    });
  });

  UpdateTransactionParams params({
    String id = 'tx-1',
    double amount = 20,
    String category = 'Food',
    String description = 'Lunch',
    String? walletId = 'wallet-bank',
    String? receipt = '/tmp/receipt.jpg',
  }) {
    return UpdateTransactionParams(
      id: id,
      amount: amount,
      type: TransactionType.expense,
      category: category,
      description: description,
      date: DateTime(2026, 10, 20, 22, 30),
      walletId: walletId,
      receiptImagePath: receipt,
    );
  }

  test('updates without changing the id and normalizes the date', () async {
    final result = await useCase(params());

    final updated = result.getOrElse((_) => fail('Expected update'));
    expect(updated.id, 'tx-1');
    expect(updated.amount, 20);
    expect(updated.description, 'Lunch');
    expect(updated.walletId, 'wallet-bank');
    expect(updated.receiptImagePath, '/tmp/receipt.jpg');
    expect(updated.date, DateTime.utc(2026, 10, 20, 12));
    verify(() => repository.updateTransaction(any())).called(1);
  });

  test('rejects a missing id', () async {
    final result = await useCase(params(id: '  '));

    expect(result.fold((failure) => failure.code, (_) => null), 'missing_id');
  });

  test('rejects a non-positive amount', () async {
    final result = await useCase(params(amount: 0));

    expect(
      result.fold((failure) => failure.code, (_) => null),
      'invalid_amount',
    );
  });

  test('rejects an empty category', () async {
    final result = await useCase(params(category: ' '));

    expect(
      result.fold((failure) => failure.code, (_) => null),
      'missing_category',
    );
  });

  test('rejects an overlong description', () async {
    final result = await useCase(params(description: 'x' * 501));

    expect(
      result.fold((failure) => failure.code, (_) => null),
      'description_too_long',
    );
  });

  test('propagates repository failures', () async {
    when(() => repository.updateTransaction(any())).thenAnswer(
      (_) async => const Left(
        ValidationFailure(
          'Transaction not found.',
          code: 'transaction_not_found',
        ),
      ),
    );

    final result = await useCase(params());

    expect(
      result.fold((failure) => failure.code, (_) => null),
      'transaction_not_found',
    );
  });
}
