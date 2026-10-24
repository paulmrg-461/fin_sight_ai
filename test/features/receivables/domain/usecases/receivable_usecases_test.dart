import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/core/utils/clock.dart';
import 'package:fin_sight_ai/features/receivables/domain/entities/receivable_entity.dart';
import 'package:fin_sight_ai/features/receivables/domain/repositories/receivable_repository.dart';
import 'package:fin_sight_ai/features/receivables/domain/usecases/add_receivable_usecase.dart';
import 'package:fin_sight_ai/features/receivables/domain/usecases/delete_receivable_usecase.dart';
import 'package:fin_sight_ai/features/receivables/domain/usecases/get_receivables_usecase.dart';
import 'package:fin_sight_ai/features/receivables/domain/usecases/make_receivable_payment_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class MockReceivableRepository extends Mock implements ReceivableRepository {}

class MockUuid extends Mock implements Uuid {}

class FixedClock extends Clock {
  const FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

void main() {
  final now = DateTime.utc(2026, 10, 22, 15);
  final dateLent = DateTime.utc(2026, 10, 1);

  ReceivableEntity buildReceivable({
    double remaining = 600,
    ReceivableStatus status = ReceivableStatus.active,
  }) {
    return ReceivableEntity(
      id: 'receivable-1',
      debtorName: 'Ana',
      totalAmount: 1000,
      remainingAmount: remaining,
      dateLent: dateLent,
      dueDate: DateTime.utc(2026, 12, 1),
      notes: 'Lunch loan',
      status: status,
      createdAt: dateLent,
      updatedAt: dateLent,
    );
  }

  late MockReceivableRepository repository;
  late MockUuid uuid;

  setUpAll(() {
    registerFallbackValue(buildReceivable());
    registerFallbackValue(
      ReceivablePayment(id: 'fallback', amount: 1, paidAt: now),
    );
    registerFallbackValue('');
  });

  setUp(() {
    repository = MockReceivableRepository();
    uuid = MockUuid();
    when(() => uuid.v4()).thenReturn('generated-id');
  });

  group('AddReceivableUseCase', () {
    late AddReceivableUseCase useCase;

    setUp(() {
      useCase = AddReceivableUseCase(
        repository,
        uuid: uuid,
        clock: FixedClock(now),
      );
      when(() => repository.addReceivable(any())).thenAnswer((
        invocation,
      ) async {
        return Right(invocation.positionalArguments.first as ReceivableEntity);
      });
    });

    test('validates and records money lent', () async {
      final result = await useCase(
        AddReceivableParams(
          debtorName: '  Ana  ',
          totalAmount: 1000.456,
          dateLent: DateTime.utc(2026, 10, 1, 18, 30),
          dueDate: DateTime.utc(2026, 12, 1, 9),
          notes: '  Lunch loan  ',
        ),
      );

      final receivable = result.getOrElse((_) => fail('Expected a receivable'));
      expect(receivable.id, 'generated-id');
      expect(receivable.debtorName, 'Ana');
      expect(receivable.totalAmount, 1000.46);
      expect(receivable.remainingAmount, 1000.46);
      expect(receivable.dateLent, DateTime(2026, 10, 1));
      expect(receivable.dueDate, DateTime(2026, 12, 1));
      expect(receivable.notes, 'Lunch loan');
      expect(receivable.status, ReceivableStatus.active);
      expect(receivable.paymentHistory, isEmpty);
      expect(receivable.createdAt, now);
    });

    test('keeps a caller-provided id', () async {
      final result = await useCase(
        AddReceivableParams(
          debtorName: 'Ana',
          totalAmount: 10,
          dateLent: dateLent,
          id: '  custom-id  ',
        ),
      );

      expect(
        result.getOrElse((_) => fail('Expected a receivable')).id,
        'custom-id',
      );
    });

    test('rejects a blank debtor name', () async {
      final result = await useCase(
        AddReceivableParams(
          debtorName: '   ',
          totalAmount: 10,
          dateLent: dateLent,
        ),
      );

      expect(result.getLeft().toNullable()?.code, 'debtor_required');
      verifyNever(() => repository.addReceivable(any()));
    });

    test('rejects a debtor name longer than the limit', () async {
      final result = await useCase(
        AddReceivableParams(
          debtorName: 'a' * 121,
          totalAmount: 10,
          dateLent: dateLent,
        ),
      );

      expect(result.getLeft().toNullable()?.code, 'debtor_too_long');
    });

    test('rejects non-positive and non-finite amounts', () async {
      final zero = await useCase(
        AddReceivableParams(
          debtorName: 'Ana',
          totalAmount: 0,
          dateLent: dateLent,
        ),
      );
      final negative = await useCase(
        AddReceivableParams(
          debtorName: 'Ana',
          totalAmount: -10,
          dateLent: dateLent,
        ),
      );
      final infinite = await useCase(
        AddReceivableParams(
          debtorName: 'Ana',
          totalAmount: double.infinity,
          dateLent: dateLent,
        ),
      );

      expect(zero.getLeft().toNullable()?.code, 'invalid_amount');
      expect(negative.getLeft().toNullable()?.code, 'invalid_amount');
      expect(infinite.getLeft().toNullable()?.code, 'invalid_amount');
    });

    test('rejects notes longer than the limit', () async {
      final result = await useCase(
        AddReceivableParams(
          debtorName: 'Ana',
          totalAmount: 10,
          dateLent: dateLent,
          notes: 'a' * 501,
        ),
      );

      expect(result.getLeft().toNullable()?.code, 'notes_too_long');
    });

    test('rejects a due date before the date lent', () async {
      final result = await useCase(
        AddReceivableParams(
          debtorName: 'Ana',
          totalAmount: 10,
          dateLent: dateLent,
          dueDate: DateTime.utc(2026, 9, 30),
        ),
      );

      expect(result.getLeft().toNullable()?.code, 'invalid_due_date');
    });

    test('propagates repository failures', () async {
      const failure = CacheFailure('Store down.', code: 'cache_write_failed');
      when(() => repository.addReceivable(any()))
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase(
        AddReceivableParams(
          debtorName: 'Ana',
          totalAmount: 10,
          dateLent: dateLent,
        ),
      );

      expect(result.getLeft().toNullable(), failure);
    });
  });

  group('GetReceivablesUseCase', () {
    test('delegates to the repository', () async {
      when(() => repository.getReceivables())
          .thenAnswer((_) async => Right([buildReceivable()]));
      final useCase = GetReceivablesUseCase(repository);

      final result = await useCase(const NoParams());

      expect(
        result.getOrElse((_) => fail('Expected receivables')),
        hasLength(1),
      );
    });

    test('propagates repository failures', () async {
      const failure = CacheFailure('Store down.', code: 'cache_read_failed');
      when(() => repository.getReceivables())
          .thenAnswer((_) async => const Left(failure));
      final useCase = GetReceivablesUseCase(repository);

      final result = await useCase(const NoParams());

      expect(result.getLeft().toNullable(), failure);
    });
  });

  group('MakeReceivablePaymentUseCase', () {
    late MakeReceivablePaymentUseCase useCase;

    setUp(() {
      useCase = MakeReceivablePaymentUseCase(
        repository,
        uuid: uuid,
        clock: FixedClock(now),
      );
      when(() => repository.getReceivables())
          .thenAnswer((_) async => Right([buildReceivable()]));
      when(() => repository.makePayment(any(), any())).thenAnswer((
        invocation,
      ) async {
        final payment = invocation.positionalArguments[1] as ReceivablePayment;
        return Right(
          buildReceivable(remaining: 600 - payment.amount)
              .copyWith(paymentHistory: [payment]),
        );
      });
    });

    test('records a partial payment with history metadata', () async {
      final result = await useCase(
        const MakeReceivablePaymentParams(
          receivableId: 'receivable-1',
          amount: 400,
          note: '  Cash  ',
        ),
      );

      final updated = result.getOrElse((_) => fail('Expected a payment'));
      final payment = updated.paymentHistory.single;
      expect(payment.id, 'generated-id');
      expect(payment.amount, 400);
      expect(payment.paidAt, now);
      expect(payment.note, 'Cash');
      expect(updated.remainingAmount, 200);
      verify(() => repository.makePayment('receivable-1', payment)).called(1);
    });

    test('omits an empty note', () async {
      await useCase(
        const MakeReceivablePaymentParams(
          receivableId: 'receivable-1',
          amount: 100,
          note: '   ',
        ),
      );

      final captured =
          verify(() => repository.makePayment('receivable-1', captureAny()))
                  .captured
                  .single
              as ReceivablePayment;
      expect(captured.note, isNull);
    });

    test('rejects a missing receivable id', () async {
      final result = await useCase(
        const MakeReceivablePaymentParams(receivableId: ' ', amount: 10),
      );

      expect(result.getLeft().toNullable()?.code, 'missing_id');
      verifyNever(() => repository.getReceivables());
    });

    test('rejects non-positive and non-finite payments', () async {
      final zero = await useCase(
        const MakeReceivablePaymentParams(
          receivableId: 'receivable-1',
          amount: 0,
        ),
      );
      final negative = await useCase(
        const MakeReceivablePaymentParams(
          receivableId: 'receivable-1',
          amount: -1,
        ),
      );
      final infinite = await useCase(
        MakeReceivablePaymentParams(
          receivableId: 'receivable-1',
          amount: double.infinity,
        ),
      );

      expect(zero.getLeft().toNullable()?.code, 'invalid_payment');
      expect(negative.getLeft().toNullable()?.code, 'invalid_payment');
      expect(infinite.getLeft().toNullable()?.code, 'invalid_payment');
    });

    test('rejects notes longer than the limit', () async {
      final result = await useCase(
        MakeReceivablePaymentParams(
          receivableId: 'receivable-1',
          amount: 10,
          note: 'a' * 501,
        ),
      );

      expect(result.getLeft().toNullable()?.code, 'notes_too_long');
    });

    test('rejects an unknown receivable', () async {
      final result = await useCase(
        const MakeReceivablePaymentParams(receivableId: 'missing', amount: 10),
      );

      expect(result.getLeft().toNullable()?.code, 'receivable_not_found');
    });

    test('rejects a settled receivable', () async {
      when(() => repository.getReceivables()).thenAnswer(
        (_) async => Right([
          buildReceivable(remaining: 0, status: ReceivableStatus.paid),
        ]),
      );

      final result = await useCase(
        const MakeReceivablePaymentParams(
          receivableId: 'receivable-1',
          amount: 10,
        ),
      );

      expect(result.getLeft().toNullable()?.code, 'receivable_already_paid');
    });

    test('propagates failures while loading receivables', () async {
      const failure = CacheFailure('Store down.');
      when(() => repository.getReceivables())
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase(
        const MakeReceivablePaymentParams(
          receivableId: 'receivable-1',
          amount: 10,
        ),
      );

      expect(result.getLeft().toNullable(), failure);
    });

    test('propagates failures while writing the payment', () async {
      const failure = CacheFailure('Write failed.');
      when(() => repository.makePayment(any(), any()))
          .thenAnswer((_) async => const Left(failure));

      final result = await useCase(
        const MakeReceivablePaymentParams(
          receivableId: 'receivable-1',
          amount: 10,
        ),
      );

      expect(result.getLeft().toNullable(), failure);
    });
  });

  group('DeleteReceivableUseCase', () {
    test('rejects an empty id', () async {
      final useCase = DeleteReceivableUseCase(repository);

      final result = await useCase('  ');

      expect(result.getLeft().toNullable()?.code, 'missing_id');
      verifyNever(() => repository.deleteReceivable(any()));
    });

    test('delegates deletion', () async {
      when(() => repository.deleteReceivable(any()))
          .thenAnswer((_) async => const Right(null));
      final useCase = DeleteReceivableUseCase(repository);

      final result = await useCase('receivable-1');

      expect(result.isRight(), isTrue);
      verify(() => repository.deleteReceivable('receivable-1')).called(1);
    });

    test('propagates deletion failures', () async {
      const failure = CacheFailure('Delete failed.');
      when(() => repository.deleteReceivable(any()))
          .thenAnswer((_) async => const Left(failure));
      final useCase = DeleteReceivableUseCase(repository);

      final result = await useCase('receivable-1');

      expect(result.getLeft().toNullable(), failure);
    });
  });
}
