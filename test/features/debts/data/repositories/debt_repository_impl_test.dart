import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/error/exceptions.dart';
import 'package:fin_sight_ai/features/debts/data/datasources/debt_local_data_source.dart';
import 'package:fin_sight_ai/features/debts/data/models/debt_model.dart';
import 'package:fin_sight_ai/features/debts/data/repositories/debt_repository_impl.dart';
import 'package:fin_sight_ai/features/debts/domain/entities/debt_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDebtLocalDataSource extends Mock implements DebtLocalDataSource {}

DebtModel buildModel({
  String id = 'debt-1',
  double remaining = 600,
  DateTime? dueDate,
}) {
  return DebtModel(
    id: id,
    creditorName: 'Bank',
    totalAmount: 1000,
    remainingAmount: remaining,
    interestRate: 12,
    minimumPayment: 100,
    dueDate: dueDate ?? DateTime.utc(2026, 12, 1),
  );
}

DebtEntity buildEntity() {
  return DebtEntity(
    id: 'debt-1',
    creditorName: 'Bank',
    totalAmount: 1000,
    remainingAmount: 600,
    interestRate: 12,
    minimumPayment: 100,
    dueDate: DateTime.utc(2026, 12, 1),
  );
}

void main() {
  late MockDebtLocalDataSource localDataSource;
  late DebtRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(buildModel());
  });

  setUp(() {
    localDataSource = MockDebtLocalDataSource();
    repository = DebtRepositoryImpl(localDataSource);
  });

  group('DebtRepositoryImpl', () {
    test('adds a debt and returns the stored entity', () async {
      when(() => localDataSource.saveDebt(any())).thenAnswer((_) async {});

      final result = await repository.addDebt(buildEntity());

      expect(result.getOrElse((_) => fail('Expected a debt')).id, 'debt-1');
      verify(() => localDataSource.saveDebt(any())).called(1);
    });

    test('updates a debt and returns the stored entity', () async {
      when(() => localDataSource.saveDebt(any())).thenAnswer((_) async {});

      final result = await repository.updateDebt(
        buildEntity().copyWith(remainingAmount: 500),
      );

      expect(
        result.getOrElse((_) => fail('Expected a debt')).remainingAmount,
        500,
      );
    });

    test('maps write failures to CacheFailure', () async {
      when(() => localDataSource.saveDebt(any())).thenThrow(
        const CacheException('Disk full.', code: 'cache_write_failed'),
      );

      final result = await repository.addDebt(buildEntity());

      expect(result.getLeft().toNullable()?.code, 'cache_write_failed');
    });

    test('maps unexpected write errors to a generic CacheFailure', () async {
      when(() => localDataSource.saveDebt(any())).thenThrow(StateError('boom'));

      final result = await repository.addDebt(buildEntity());

      expect(result.getLeft().toNullable(), isA<CacheFailure>());
    });

    test('reads and maps debts', () async {
      when(() => localDataSource.getDebts())
          .thenAnswer((_) async => [buildModel()]);

      final result = await repository.getDebts();

      expect(
        result.getOrElse((_) => fail('Expected debts')).single.id,
        'debt-1',
      );
    });

    test('maps read failures to CacheFailure', () async {
      when(
        () => localDataSource.getDebts(),
      ).thenThrow(const CacheException('Corrupt.', code: 'cache_read_failed'));

      final result = await repository.getDebts();

      expect(result.getLeft().toNullable()?.code, 'cache_read_failed');
    });

    test('deletes a debt', () async {
      when(() => localDataSource.deleteDebt('debt-1')).thenAnswer((_) async {});

      final result = await repository.deleteDebt('debt-1');

      expect(result.isRight(), isTrue);
    });

    test('maps delete failures to CacheFailure', () async {
      when(() => localDataSource.deleteDebt(any())).thenThrow(
        const CacheException('Missing.', code: 'cache_delete_failed'),
      );

      final result = await repository.deleteDebt('debt-1');

      expect(result.getLeft().toNullable()?.code, 'cache_delete_failed');
    });

    test('calculates a payoff date using the minimum payment', () async {
      final result = await repository.calculatePayoffDate(buildEntity());

      final date = result.getOrElse((_) => null);
      expect(date, isNotNull);
      expect(date!.isAfter(DateTime.now()), isTrue);
    });

    test('accepts an explicit monthly payment', () async {
      final slow = await repository.calculatePayoffDate(
        buildEntity(),
        monthlyPayment: 100,
      );
      final fast = await repository.calculatePayoffDate(
        buildEntity(),
        monthlyPayment: 500,
      );

      expect(slow.getOrElse((_) => null), isNotNull);
      expect(fast.getOrElse((_) => null), isNotNull);
      expect(
        fast.getOrElse((_) => null)!.isBefore(slow.getOrElse((_) => null)!),
        isTrue,
      );
    });

    test('returns null for a non-payable debt', () async {
      final result = await repository.calculatePayoffDate(
        buildEntity(),
        monthlyPayment: 1,
      );

      expect(result.getOrElse((_) => DateTime(2000)), isNull);
    });
  });
}
