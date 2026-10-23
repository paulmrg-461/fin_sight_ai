import 'package:fin_sight_ai/features/scheduled_payments/domain/entities/scheduled_payment_entity.dart';
import 'package:fin_sight_ai/features/scheduled_payments/domain/repositories/scheduled_payment_repository.dart';
import 'package:fin_sight_ai/features/scheduled_payments/domain/usecases/scheduled_payment_usecases.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/core/utils/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockScheduledPaymentRepository extends Mock
    implements ScheduledPaymentRepository {}

class _FixedClock extends Clock {
  _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

void main() {
  late MockScheduledPaymentRepository repository;

  final now = DateTime(2026, 10, 23, 9);

  final payment = ScheduledPaymentEntity(
    id: 'pay-1',
    name: 'Rent',
    amount: 800,
    category: 'Rent',
    frequency: PaymentFrequency.monthly,
    nextDueDate: DateTime(2026, 10, 23),
    dayOfMonth: 23,
    walletId: 'wallet-bank',
    createdAt: now,
  );

  setUpAll(() {
    registerFallbackValue(payment);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    repository = MockScheduledPaymentRepository();
  });

  group('GetScheduledPaymentsUseCase', () {
    test('delegates to the repository', () async {
      when(() => repository.getPayments())
          .thenAnswer((_) async => Right([payment]));

      final result = await GetScheduledPaymentsUseCase(repository)(
        const NoParams(),
      );

      expect(result.fold((_) => null, (value) => value), [payment]);
    });
  });

  group('AddScheduledPaymentUseCase', () {
    AddScheduledPaymentUseCase useCase() => AddScheduledPaymentUseCase(
      repository,
      clock: _FixedClock(DateTime(2026, 10, 20)),
    );

    test('rejects an empty name', () async {
      final result = await useCase()(
        AddScheduledPaymentParams(
          name: ' ',
          amount: 10,
          category: 'Rent',
          nextDueDate: now,
        ),
      );

      expect(result.fold((f) => f.code, (_) => null), 'missing_payment_name');
    });

    test('rejects non-positive amounts', () async {
      final result = await useCase()(
        AddScheduledPaymentParams(
          name: 'Rent',
          amount: 0,
          category: 'Rent',
          nextDueDate: now,
        ),
      );

      expect(result.fold((f) => f.code, (_) => null), 'invalid_amount');
    });

    test('rejects an empty category', () async {
      final result = await useCase()(
        AddScheduledPaymentParams(
          name: 'Rent',
          amount: 10,
          category: ' ',
          nextDueDate: now,
        ),
      );

      expect(result.fold((f) => f.code, (_) => null), 'missing_category');
    });

    test('rejects overlong notes', () async {
      final result = await useCase()(
        AddScheduledPaymentParams(
          name: 'Rent',
          amount: 10,
          category: 'Rent',
          nextDueDate: now,
          notes: 'x' * 501,
        ),
      );

      expect(result.fold((f) => f.code, (_) => null), 'notes_too_long');
    });

    test('normalizes and persists the schedule', () async {
      when(() => repository.addPayment(any())).thenAnswer((invocation) async {
        return Right(
          invocation.positionalArguments.first as ScheduledPaymentEntity,
        );
      });

      final result = await useCase()(
        AddScheduledPaymentParams(
          name: '  Rent  ',
          amount: 800.006,
          category: ' Rent ',
          nextDueDate: DateTime(2026, 10, 23, 18),
          walletId: ' wallet-bank ',
          notes: '  Monthly  ',
        ),
      );

      final saved = result.fold((_) => null, (value) => value)!;
      expect(saved.name, 'Rent');
      expect(saved.amount, 800.01);
      expect(saved.category, 'Rent');
      expect(saved.nextDueDate, DateTime(2026, 10, 23));
      expect(saved.dayOfMonth, 23);
      expect(saved.walletId, 'wallet-bank');
      expect(saved.notes, 'Monthly');
      expect(saved.createdAt, DateTime(2026, 10, 20));
    });

    test('clears an empty wallet id', () async {
      when(() => repository.addPayment(any())).thenAnswer((invocation) async {
        return Right(
          invocation.positionalArguments.first as ScheduledPaymentEntity,
        );
      });

      final result = await useCase()(
        AddScheduledPaymentParams(
          name: 'Rent',
          amount: 10,
          category: 'Rent',
          nextDueDate: now,
          walletId: '  ',
        ),
      );

      expect(result.fold((_) => null, (value) => value.walletId), isNull);
    });
  });

  group('SetScheduledPaymentActiveUseCase', () {
    test('requires an id', () async {
      final result = await SetScheduledPaymentActiveUseCase(repository)(
        const SetScheduledPaymentActiveParams(id: '', isActive: true),
      );

      expect(result.fold((f) => f.code, (_) => null), 'missing_id');
    });

    test('delegates pause changes', () async {
      when(() => repository.setActive('pay-1', false))
          .thenAnswer((_) async => Right(payment.copyWith(isActive: false)));

      final result = await SetScheduledPaymentActiveUseCase(repository)(
        const SetScheduledPaymentActiveParams(id: ' pay-1 ', isActive: false),
      );

      expect(result.isRight(), isTrue);
      verify(() => repository.setActive('pay-1', false)).called(1);
    });
  });

  group('DeleteScheduledPaymentUseCase', () {
    test('requires an id', () async {
      final result = await DeleteScheduledPaymentUseCase(repository)(' ');

      expect(result.fold((f) => f.code, (_) => null), 'missing_id');
    });

    test('delegates deletion', () async {
      when(() => repository.deletePayment('pay-1'))
          .thenAnswer((_) async => const Right(null));

      final result = await DeleteScheduledPaymentUseCase(repository)(' pay-1 ');

      expect(result.isRight(), isTrue);
      verify(() => repository.deletePayment('pay-1')).called(1);
    });
  });

  group('PayScheduledPaymentUseCase', () {
    test('requires an id', () async {
      final result = await PayScheduledPaymentUseCase(repository)('');

      expect(result.fold((f) => f.code, (_) => null), 'missing_id');
    });

    test('delegates with the clock date', () async {
      when(
        () => repository.payNow('pay-1', now),
      ).thenAnswer((_) async => const Right(ScheduledPaymentRun(processed: 1)));

      final result = await PayScheduledPaymentUseCase(
        repository,
        clock: _FixedClock(now),
      )(' pay-1 ');

      expect(result.isRight(), isTrue);
      verify(() => repository.payNow('pay-1', now)).called(1);
    });
  });

  group('ProcessDueScheduledPaymentsUseCase', () {
    test('processes with the clock date', () async {
      when(
        () => repository.processDue(now),
      ).thenAnswer((_) async => const Right(ScheduledPaymentRun(processed: 2)));

      final result = await ProcessDueScheduledPaymentsUseCase(
        repository,
        clock: _FixedClock(now),
      )(const NoParams());

      expect(result.fold((_) => null, (value) => value.processed), 2);
    });
  });
}
