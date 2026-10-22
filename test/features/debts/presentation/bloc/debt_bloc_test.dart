import 'package:bloc_test/bloc_test.dart';
import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/features/debts/domain/entities/debt_entity.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/add_debt_usecase.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/calculate_payoff_usecase.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/delete_debt_usecase.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/get_debts_usecase.dart';
import 'package:fin_sight_ai/features/debts/domain/usecases/make_payment_usecase.dart';
import 'package:fin_sight_ai/features/debts/presentation/bloc/debt_bloc.dart';
import 'package:fin_sight_ai/features/debts/presentation/bloc/debt_event.dart';
import 'package:fin_sight_ai/features/debts/presentation/bloc/debt_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetDebts extends Mock implements GetDebtsUseCase {}

class MockAddDebt extends Mock implements AddDebtUseCase {}

class MockMakePayment extends Mock implements MakePaymentUseCase {}

class MockDeleteDebt extends Mock implements DeleteDebtUseCase {}

class MockCalculatePayoff extends Mock implements CalculatePayoffUseCase {}

void main() {
  late MockGetDebts getDebts;
  late MockAddDebt addDebt;
  late MockMakePayment makePayment;
  late MockDeleteDebt deleteDebt;
  late MockCalculatePayoff calculatePayoff;

  final dueDate = DateTime.utc(2026, 12, 1);
  final debt = DebtEntity(
    id: 'debt-1',
    creditorName: 'Bank',
    totalAmount: 1000,
    remainingAmount: 600,
    interestRate: 12,
    minimumPayment: 100,
    dueDate: dueDate,
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      AddDebtParams(
        creditorName: 'fallback',
        totalAmount: 1,
        remainingAmount: 1,
        interestRate: 0,
        minimumPayment: 1,
        dueDate: DateTime.utc(2026),
      ),
    );
    registerFallbackValue(const MakePaymentParams(debtId: 'debt-1', amount: 1));
    registerFallbackValue(CalculatePayoffParams(debt: debt));
  });

  setUp(() {
    getDebts = MockGetDebts();
    addDebt = MockAddDebt();
    makePayment = MockMakePayment();
    deleteDebt = MockDeleteDebt();
    calculatePayoff = MockCalculatePayoff();
  });

  DebtBloc buildBloc() =>
      DebtBloc(getDebts, addDebt, makePayment, deleteDebt, calculatePayoff);

  group('DebtBloc', () {
    test('initial state is DebtInitial', () {
      expect(buildBloc().state, const DebtInitial());
    });

    blocTest<DebtBloc, DebtState>(
      'loads debts successfully',
      setUp: () {
        when(() => getDebts(any())).thenAnswer((_) async => Right([debt]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadDebts()),
      expect: () => [
        const DebtLoading(),
        DebtLoaded(debts: [debt]),
      ],
    );

    blocTest<DebtBloc, DebtState>(
      'emits empty when there are no debts',
      setUp: () {
        when(() => getDebts(any())).thenAnswer((_) async => const Right([]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadDebts()),
      expect: () => [const DebtLoading(), const DebtEmpty()],
    );

    blocTest<DebtBloc, DebtState>(
      'emits failure when loading fails',
      setUp: () {
        when(() => getDebts(any()))
            .thenAnswer((_) async => const Left(CacheFailure('Store down.')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadDebts()),
      expect: () => [const DebtLoading(), const DebtFailure('Store down.')],
    );

    blocTest<DebtBloc, DebtState>(
      'adds a debt and reloads',
      setUp: () {
        when(() => addDebt(any())).thenAnswer((_) async => Right(debt));
        when(() => getDebts(any())).thenAnswer((_) async => Right([debt]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        AddDebt(
          creditorName: 'Bank',
          totalAmount: 1000,
          remainingAmount: 1000,
          interestRate: 12,
          minimumPayment: 100,
          dueDate: dueDate,
        ),
      ),
      expect: () => [
        const DebtLoading(),
        DebtLoaded(debts: [debt]),
      ],
      verify: (_) {
        verify(() => addDebt(any())).called(1);
      },
    );

    blocTest<DebtBloc, DebtState>(
      'emits failure when adding is rejected',
      setUp: () {
        when(() => addDebt(any())).thenAnswer(
          (_) async =>
              const Left(ValidationFailure('Creditor name is required.')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        AddDebt(
          creditorName: '',
          totalAmount: 1000,
          interestRate: 12,
          minimumPayment: 100,
          dueDate: dueDate,
        ),
      ),
      expect: () => [
        const DebtLoading(),
        const DebtFailure('Creditor name is required.'),
      ],
    );

    blocTest<DebtBloc, DebtState>(
      'applies a payment and reloads',
      setUp: () {
        final paid = debt.copyWith(remainingAmount: 500);
        when(() => makePayment(any())).thenAnswer((_) async => Right(paid));
        when(() => getDebts(any())).thenAnswer((_) async => Right([paid]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const MakePayment(debtId: 'debt-1', amount: 100)),
      expect: () => [
        const DebtLoading(),
        DebtLoaded(debts: [debt.copyWith(remainingAmount: 500)]),
      ],
    );

    blocTest<DebtBloc, DebtState>(
      'deletes a debt and reloads',
      setUp: () {
        when(() => deleteDebt(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => getDebts(any())).thenAnswer((_) async => const Right([]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const DeleteDebt('debt-1')),
      expect: () => [const DebtLoading(), const DebtEmpty()],
      verify: (_) {
        verify(() => deleteDebt('debt-1')).called(1);
      },
    );

    blocTest<DebtBloc, DebtState>(
      'calculates a payoff estimate for a loaded debt',
      setUp: () {
        final payoff = DateTime.utc(2027, 6, 1);
        when(() => calculatePayoff(any()))
            .thenAnswer((_) async => Right(payoff));
      },
      build: buildBloc,
      seed: () => DebtLoaded(debts: [debt]),
      act: (bloc) => bloc.add(
        const CalculatePayoff(debtId: 'debt-1', monthlyPayment: 150),
      ),
      expect: () => [
        DebtLoaded(
          debts: [debt],
          payoff: PayoffEstimate(
            debtId: 'debt-1',
            monthlyPayment: 150,
            expectedDate: DateTime.utc(2027, 6, 1),
          ),
        ),
      ],
    );

    blocTest<DebtBloc, DebtState>(
      'supports a non-payable estimate',
      setUp: () {
        when(() => calculatePayoff(any()))
            .thenAnswer((_) async => const Right(null));
      },
      build: buildBloc,
      seed: () => DebtLoaded(debts: [debt]),
      act: (bloc) =>
          bloc.add(const CalculatePayoff(debtId: 'debt-1', monthlyPayment: 1)),
      expect: () => [
        DebtLoaded(
          debts: [debt],
          payoff: const PayoffEstimate(
            debtId: 'debt-1',
            monthlyPayment: 1,
            expectedDate: null,
          ),
        ),
      ],
    );

    blocTest<DebtBloc, DebtState>(
      'ignores payoff calculations before debts are loaded',
      build: buildBloc,
      act: (bloc) => bloc.add(
        const CalculatePayoff(debtId: 'debt-1', monthlyPayment: 100),
      ),
      expect: () => const [],
    );

    blocTest<DebtBloc, DebtState>(
      'emits failure when payoff calculation fails',
      setUp: () {
        when(() => calculatePayoff(any())).thenAnswer(
          (_) async => const Left(
            ValidationFailure('Monthly payment must be greater than zero.'),
          ),
        );
      },
      build: buildBloc,
      seed: () => DebtLoaded(debts: [debt]),
      act: (bloc) =>
          bloc.add(const CalculatePayoff(debtId: 'debt-1', monthlyPayment: 0)),
      expect: () => [
        const DebtFailure('Monthly payment must be greater than zero.'),
      ],
    );
  });
}
