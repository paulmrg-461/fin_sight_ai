import 'package:fin_sight_ai/core/error/failures.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction.dart';
import 'package:fin_sight_ai/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/add_transaction_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  final date = DateTime.utc(2026, 10, 20, 9);

  late MockTransactionRepository repository;
  late AddTransactionUseCase useCase;

  setUpAll(() {
    registerFallbackValue(
      Transaction(
        id: 'fallback',
        amount: 1,
        date: DateTime.utc(2026),
        category: 'fallback',
        type: TransactionType.expense,
      ),
    );
  });

  setUp(() {
    repository = MockTransactionRepository();
    useCase = AddTransactionUseCase(repository);

    when(() => repository.addTransaction(any())).thenAnswer((invocation) async {
      final transaction = invocation.positionalArguments.first as Transaction;
      return Right(transaction);
    });
  });

  AddTransactionParams params({
    double amount = 25.5,
    String category = 'Food',
    TransactionType type = TransactionType.expense,
    String note = '',
    String? id,
  }) {
    return AddTransactionParams(
      amount: amount,
      category: category,
      type: type,
      date: date,
      note: note,
      id: id,
    );
  }

  group('AddTransactionUseCase', () {
    test('generates a UUID v4 and normalizes the input', () async {
      // Arrange
      final uuidPattern = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-'
        r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );

      // Act
      final result = await useCase(
        params(amount: 12.3459, category: '  Food  ', note: '  Lunch  '),
      );

      // Assert
      final transaction = result.getOrElse(
        (failure) => fail('Expected a transaction, got $failure'),
      );
      expect(uuidPattern.hasMatch(transaction.id), isTrue);
      expect(transaction.amount, 12.35);
      expect(transaction.category, 'Food');
      expect(transaction.note, 'Lunch');
      expect(transaction.type, TransactionType.expense);
      expect(transaction.date, date);
      expect(transaction.isSynced, isFalse);
    });

    test('keeps an explicitly provided identifier', () async {
      // Act
      final result = await useCase(params(id: 'tx-explicit'));

      // Assert
      final transaction = result.getOrElse(
        (failure) => fail('Expected a transaction, got $failure'),
      );
      expect(transaction.id, 'tx-explicit');
    });

    test('generates an identifier when the provided one is blank', () async {
      // Act
      final result = await useCase(params(id: '   '));

      // Assert
      final transaction = result.getOrElse(
        (failure) => fail('Expected a transaction, got $failure'),
      );
      expect(transaction.id.trim(), isNotEmpty);
      expect(transaction.id, isNot('   '));
      expect(Uuid.isValidUUID(fromString: transaction.id), isTrue);
    });

    test('rejects a zero amount without touching the repository', () async {
      // Act
      final result = await useCase(params(amount: 0));

      // Assert
      expect(result.isLeft(), isTrue);
      final failure = result.getLeft().toNullable();
      expect(failure, isA<ValidationFailure>());
      expect(failure?.code, 'invalid_amount');
      verifyNever(() => repository.addTransaction(any()));
    });

    test('rejects a negative amount', () async {
      // Act
      final result = await useCase(params(amount: -10));

      // Assert
      expect(result.getLeft().toNullable()?.code, 'invalid_amount');
    });

    test('rejects a non-finite amount', () async {
      // Act
      final nanResult = await useCase(params(amount: double.nan));
      final infiniteResult = await useCase(params(amount: double.infinity));

      // Assert
      expect(nanResult.getLeft().toNullable()?.code, 'invalid_amount');
      expect(infiniteResult.getLeft().toNullable()?.code, 'invalid_amount');
    });

    test('rejects a blank category', () async {
      // Act
      final result = await useCase(params(category: '   '));

      // Assert
      final failure = result.getLeft().toNullable();
      expect(failure, isA<ValidationFailure>());
      expect(failure?.code, 'missing_category');
      verifyNever(() => repository.addTransaction(any()));
    });

    test('rejects a note longer than 500 characters', () async {
      // Act
      final result = await useCase(params(note: 'a' * 501));

      // Assert
      final failure = result.getLeft().toNullable();
      expect(failure, isA<ValidationFailure>());
      expect(failure?.code, 'note_too_long');
      verifyNever(() => repository.addTransaction(any()));
    });

    test('accepts a note with exactly 500 characters', () async {
      // Act
      final result = await useCase(params(note: 'a' * 500));

      // Assert
      expect(result.isRight(), isTrue);
    });

    test('propagates a repository failure unchanged', () async {
      // Arrange
      const failure = ServerFailure('Sync rejected.', code: 'sync_rejected');
      when(() => repository.addTransaction(any()))
          .thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(params());

      // Assert
      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), failure);
    });
  });
}
