import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fin_sight_ai/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/get_transactions_by_date_range_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late MockTransactionRepository repository;
  late GetTransactionsByDateRangeUseCase useCase;

  final start = DateTime.utc(2026, 10, 1);
  final end = DateTime.utc(2026, 10, 31);
  final transaction = TransactionEntity(
    id: 'tx-1',
    amount: 10,
    type: TransactionType.expense,
    category: 'Coffee',
    description: '',
    date: DateTime.utc(2026, 10, 20),
  );

  setUp(() {
    repository = MockTransactionRepository();
    useCase = GetTransactionsByDateRangeUseCase(repository);
  });

  group('GetTransactionsByDateRangeUseCase', () {
    test('DateRangeParams compares by value', () {
      expect(
        DateRangeParams(start: start, end: end),
        DateRangeParams(start: start, end: end),
      );
      expect(
        DateRangeParams(start: start, end: end).hashCode,
        DateRangeParams(start: start, end: end).hashCode,
      );
      expect(
        DateRangeParams(start: start, end: end),
        isNot(DateRangeParams(start: start, end: start)),
      );
    });

    test('queries the repository with the provided range', () async {
      when(() => repository.getTransactionsByDateRange(start: start, end: end))
          .thenAnswer((_) async => Right([transaction]));

      final result = await useCase(DateRangeParams(start: start, end: end));

      expect(result.getOrElse((_) => const <TransactionEntity>[]), [
        transaction,
      ]);
    });

    test('rejects a reversed range without querying', () async {
      final result = await useCase(DateRangeParams(start: end, end: start));

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      expect(result.getLeft().toNullable()?.code, 'invalid_date_range');
      verifyNever(
        () => repository.getTransactionsByDateRange(
          start: any(named: 'start'),
          end: any(named: 'end'),
        ),
      );
    });

    test('propagates repository failures', () async {
      const failure = CacheFailure('Store down.');
      when(() => repository.getTransactionsByDateRange(start: start, end: end))
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase(DateRangeParams(start: start, end: end));

      expect(result.getLeft().toNullable(), failure);
    });
  });
}
