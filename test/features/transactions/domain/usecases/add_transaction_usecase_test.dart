import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fin_sight_ai/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/add_transaction_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  final date = DateTime(2026, 10, 20, 20, 30);
  final calendarDay = DateTime.utc(2026, 10, 20, 12);

  late MockTransactionRepository repository;
  late AddTransactionUseCase useCase;

  setUpAll(() {
    registerFallbackValue(
      TransactionEntity(
        id: 'fallback',
        amount: 1,
        type: TransactionType.expense,
        category: 'fallback',
        description: '',
        date: DateTime.utc(2026),
      ),
    );
  });

  setUp(() {
    repository = MockTransactionRepository();
    useCase = AddTransactionUseCase(repository);
    when(() => repository.addTransaction(any())).thenAnswer((invocation) async {
      final transaction =
          invocation.positionalArguments.first as TransactionEntity;
      return Right(transaction);
    });
  });

  AddTransactionParams params({
    double amount = 25.5,
    String category = 'Food',
    String description = '',
    TransactionType type = TransactionType.expense,
    String? receiptImagePath,
    String? walletId,
    String? id,
  }) {
    return AddTransactionParams(
      amount: amount,
      type: type,
      category: category,
      description: description,
      date: date,
      receiptImagePath: receiptImagePath,
      walletId: walletId,
      id: id,
    );
  }

  group('AddTransactionUseCase', () {
    test('preserves the selected wallet', () async {
      final result = await useCase(params(walletId: ' wallet-bank '));

      expect(
        result.fold((_) => null, (transaction) => transaction.walletId),
        'wallet-bank',
      );
    });

    test('normalizes input and generates a UUID v4', () async {
      final result = await useCase(
        params(
          amount: 12.3459,
          category: '  Food  ',
          description: '  Lunch  ',
          receiptImagePath: '  /tmp/r.jpg  ',
        ),
      );

      final transaction = result.getOrElse(
        (failure) => fail('Expected a transaction, got $failure'),
      );
      expect(Uuid.isValidUUID(fromString: transaction.id), isTrue);
      expect(transaction.amount, 12.35);
      expect(transaction.category, 'Food');
      expect(transaction.description, 'Lunch');
      expect(transaction.receiptImagePath, '/tmp/r.jpg');
      expect(transaction.type, TransactionType.expense);
      expect(transaction.date, calendarDay);
    });

    test('stores the selected calendar day as UTC noon', () async {
      final result = await useCase(params());

      final transaction = result.getOrElse(
        (failure) => fail('Expected a transaction, got $failure'),
      );
      expect(transaction.date, DateTime.utc(2026, 10, 20, 12));
      expect(transaction.date.isUtc, isTrue);
      expect(transaction.date.hour, 12);
      expect(transaction.date.minute, 0);
      expect(transaction.date.year, 2026);
      expect(transaction.date.month, 10);
      expect(transaction.date.day, 20);
    });

    test('keeps an explicit identifier', () async {
      final result = await useCase(params(id: 'tx-explicit'));

      expect(
        result.getOrElse((failure) => fail('Expected a transaction')),
        isA<TransactionEntity>().having((t) => t.id, 'id', 'tx-explicit'),
      );
    });

    test('generates an id when the provided one is blank', () async {
      final result = await useCase(params(id: '   '));

      final transaction = result.getOrElse(
        (failure) => fail('Expected a transaction'),
      );
      expect(transaction.id.trim(), isNotEmpty);
      expect(Uuid.isValidUUID(fromString: transaction.id), isTrue);
    });

    test('maps a blank receipt path to null', () async {
      final result = await useCase(params(receiptImagePath: '   '));

      expect(
        result
            .getOrElse((failure) => fail('Expected a transaction'))
            .receiptImagePath,
        isNull,
      );
    });

    test('rejects zero and negative amounts', () async {
      final zero = await useCase(params(amount: 0));
      final negative = await useCase(params(amount: -5));

      expect(zero.getLeft().toNullable()?.code, 'invalid_amount');
      expect(negative.getLeft().toNullable()?.code, 'invalid_amount');
      verifyNever(() => repository.addTransaction(any()));
    });

    test('rejects non-finite amounts', () async {
      final nan = await useCase(params(amount: double.nan));
      final infinite = await useCase(params(amount: double.infinity));

      expect(nan.getLeft().toNullable()?.code, 'invalid_amount');
      expect(infinite.getLeft().toNullable()?.code, 'invalid_amount');
    });

    test('rejects a blank category', () async {
      final result = await useCase(params(category: '  '));

      expect(result.getLeft().toNullable()?.code, 'missing_category');
      verifyNever(() => repository.addTransaction(any()));
    });

    test('rejects descriptions over 500 characters', () async {
      final result = await useCase(params(description: 'a' * 501));

      expect(result.getLeft().toNullable()?.code, 'description_too_long');
    });

    test('accepts a 500-character description', () async {
      final result = await useCase(params(description: 'a' * 500));

      expect(result.isRight(), isTrue);
    });

    test('propagates repository failures unchanged', () async {
      const failure = CacheFailure('Store down.', code: 'cache_down');
      when(() => repository.addTransaction(any()))
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase(params());

      expect(result.getLeft().toNullable(), failure);
    });
  });
}
