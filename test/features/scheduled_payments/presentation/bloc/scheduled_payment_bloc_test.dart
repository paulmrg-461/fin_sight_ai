import 'package:bloc_test/bloc_test.dart';
import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/features/scheduled_payments/domain/entities/scheduled_payment_entity.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fin_sight_ai/features/scheduled_payments/domain/usecases/scheduled_payment_usecases.dart';
import 'package:fin_sight_ai/features/scheduled_payments/presentation/bloc/scheduled_payment_bloc.dart';
import 'package:fin_sight_ai/features/scheduled_payments/presentation/bloc/scheduled_payment_event.dart';
import 'package:fin_sight_ai/features/scheduled_payments/presentation/bloc/scheduled_payment_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetPayments extends Mock implements GetScheduledPaymentsUseCase {}

class MockAddPayment extends Mock implements AddScheduledPaymentUseCase {}

class MockSetActive extends Mock implements SetScheduledPaymentActiveUseCase {}

class MockDeletePayment extends Mock implements DeleteScheduledPaymentUseCase {}

class MockPayNow extends Mock implements PayScheduledPaymentUseCase {}

class MockProcessDue extends Mock
    implements ProcessDueScheduledPaymentsUseCase {}

void main() {
  late MockGetPayments getPayments;
  late MockAddPayment addPayment;
  late MockSetActive setActive;
  late MockDeletePayment deletePayment;
  late MockPayNow payNow;
  late MockProcessDue processDue;

  final payment = ScheduledPaymentEntity(
    id: 'pay-1',
    name: 'Rent',
    amount: 800,
    category: 'Rent',
    frequency: PaymentFrequency.monthly,
    nextDueDate: DateTime(2026, 10, 23),
    dayOfMonth: 23,
    createdAt: DateTime(2026, 10, 1),
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      AddScheduledPaymentParams(
        name: 'Rent',
        amount: 1,
        category: 'Rent',
        nextDueDate: DateTime(2026),
      ),
    );
    registerFallbackValue(
      const SetScheduledPaymentActiveParams(id: 'id', isActive: true),
    );
  });

  setUp(() {
    getPayments = MockGetPayments();
    addPayment = MockAddPayment();
    setActive = MockSetActive();
    deletePayment = MockDeletePayment();
    payNow = MockPayNow();
    processDue = MockProcessDue();
  });

  ScheduledPaymentBloc buildBloc() => ScheduledPaymentBloc(
    getPayments,
    addPayment,
    setActive,
    deletePayment,
    payNow,
    processDue,
  );

  ScheduledPaymentRun runWith(int created) {
    final transaction = TransactionEntity(
      id: 'tx',
      amount: 1,
      type: TransactionType.expense,
      category: 'Rent',
      description: 'Rent',
      date: DateTime(2026, 10, 23),
    );
    return ScheduledPaymentRun(
      created: List<TransactionEntity>.filled(created, transaction),
      processed: created,
    );
  }

  void stubProcess({int created = 0, Failure? failure}) {
    when(() => processDue(any())).thenAnswer(
      (_) async => failure != null ? Left(failure) : Right(runWith(created)),
    );
  }

  void stubGet(List<ScheduledPaymentEntity> payments) {
    when(() => getPayments(any())).thenAnswer((_) async => Right(payments));
  }

  blocTest<ScheduledPaymentBloc, ScheduledPaymentState>(
    'loads payments and reports auto-created expenses',
    setUp: () {
      stubProcess(created: 1);
      stubGet([payment]);
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const LoadScheduledPayments()),
    expect: () => [
      const ScheduledPaymentLoading(),
      ScheduledPaymentLoaded([payment], autoCreated: 1),
    ],
  );

  blocTest<ScheduledPaymentBloc, ScheduledPaymentState>(
    'loads an empty schedule',
    setUp: () {
      stubProcess();
      stubGet(const []);
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const LoadScheduledPayments()),
    expect: () => [
      const ScheduledPaymentLoading(),
      const ScheduledPaymentEmpty(),
    ],
  );

  blocTest<ScheduledPaymentBloc, ScheduledPaymentState>(
    'surfaces processing failures',
    setUp: () {
      when(() => processDue(any()))
          .thenAnswer((_) async => const Left(CacheFailure('Cannot process.')));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const LoadScheduledPayments()),
    expect: () => [
      const ScheduledPaymentLoading(),
      const ScheduledPaymentFailure('Cannot process.'),
    ],
  );

  blocTest<ScheduledPaymentBloc, ScheduledPaymentState>(
    'surfaces load failures',
    setUp: () {
      stubProcess();
      when(() => getPayments(any()))
          .thenAnswer((_) async => const Left(CacheFailure('Storage down.')));
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const LoadScheduledPayments()),
    expect: () => [
      const ScheduledPaymentLoading(),
      const ScheduledPaymentFailure('Storage down.'),
    ],
  );

  blocTest<ScheduledPaymentBloc, ScheduledPaymentState>(
    'adds a payment and processes it when due',
    setUp: () {
      when(() => addPayment(any())).thenAnswer((_) async => Right(payment));
      stubProcess(created: 1);
      stubGet([payment]);
    },
    build: buildBloc,
    act: (bloc) => bloc.add(
      AddScheduledPayment(
        AddScheduledPaymentParams(
          name: 'Rent',
          amount: 800,
          category: 'Rent',
          nextDueDate: DateTime(2026, 10, 23),
        ),
      ),
    ),
    expect: () => [
      ScheduledPaymentLoaded([payment], autoCreated: 1),
    ],
  );

  blocTest<ScheduledPaymentBloc, ScheduledPaymentState>(
    'keeps the list and shows add errors',
    setUp: () {
      when(() => addPayment(any())).thenAnswer(
        (_) async => const Left(
          ValidationFailure('Name required.', code: 'missing_name'),
        ),
      );
      stubGet([payment]);
    },
    build: buildBloc,
    act: (bloc) => bloc.add(
      AddScheduledPayment(
        AddScheduledPaymentParams(
          name: '',
          amount: 800,
          category: 'Rent',
          nextDueDate: DateTime(2026, 10, 23),
        ),
      ),
    ),
    expect: () => [
      ScheduledPaymentLoaded([payment], error: 'Name required.'),
    ],
  );

  blocTest<ScheduledPaymentBloc, ScheduledPaymentState>(
    'pauses a payment',
    setUp: () {
      when(() => setActive(any()))
          .thenAnswer((_) async => Right(payment.copyWith(isActive: false)));
      stubGet([payment.copyWith(isActive: false)]);
    },
    build: buildBloc,
    act: (bloc) =>
        bloc.add(const SetScheduledPaymentActive(id: 'pay-1', isActive: false)),
    expect: () => [
      ScheduledPaymentLoaded([payment.copyWith(isActive: false)]),
    ],
  );

  blocTest<ScheduledPaymentBloc, ScheduledPaymentState>(
    'deletes a payment',
    setUp: () {
      when(() => deletePayment(any()))
          .thenAnswer((_) async => const Right(null));
      stubGet(const []);
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const DeleteScheduledPayment('pay-1')),
    expect: () => [const ScheduledPaymentEmpty()],
  );

  blocTest<ScheduledPaymentBloc, ScheduledPaymentState>(
    'pays now and reports the generated expense',
    setUp: () {
      when(() => payNow(any())).thenAnswer((_) async => Right(runWith(1)));
      stubGet([payment]);
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const PayScheduledPayment('pay-1')),
    expect: () => [
      const ScheduledPaymentLoading(),
      ScheduledPaymentLoaded([payment], autoCreated: 1),
    ],
  );

  blocTest<ScheduledPaymentBloc, ScheduledPaymentState>(
    'shows pay-now errors',
    setUp: () {
      when(() => payNow(any()))
          .thenAnswer((_) async => const Left(ValidationFailure('Not found.')));
      stubGet([payment]);
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const PayScheduledPayment('missing')),
    expect: () => [
      const ScheduledPaymentLoading(),
      ScheduledPaymentLoaded([payment], error: 'Not found.'),
    ],
  );

  blocTest<ScheduledPaymentBloc, ScheduledPaymentState>(
    'processes due payments on demand',
    setUp: () {
      stubProcess(created: 1);
      stubGet([payment]);
    },
    build: buildBloc,
    act: (bloc) => bloc.add(const ProcessDuePayments()),
    expect: () => [
      const ScheduledPaymentLoading(),
      ScheduledPaymentLoaded([payment], autoCreated: 1),
    ],
  );

  test('events compare by value', () {
    expect(const LoadScheduledPayments(), const LoadScheduledPayments());
    expect(const PayScheduledPayment('a'), const PayScheduledPayment('a'));
    expect(
      const SetScheduledPaymentActive(id: 'a', isActive: false),
      const SetScheduledPaymentActive(id: 'a', isActive: false),
    );
  });
}
