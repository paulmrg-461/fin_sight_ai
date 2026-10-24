import 'package:bloc_test/bloc_test.dart';
import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/features/receivables/domain/entities/receivable_entity.dart';
import 'package:fin_sight_ai/features/receivables/domain/usecases/add_receivable_usecase.dart';
import 'package:fin_sight_ai/features/receivables/domain/usecases/delete_receivable_usecase.dart';
import 'package:fin_sight_ai/features/receivables/domain/usecases/get_receivables_usecase.dart';
import 'package:fin_sight_ai/features/receivables/domain/usecases/make_receivable_payment_usecase.dart';
import 'package:fin_sight_ai/features/receivables/domain/usecases/update_receivable_usecase.dart';
import 'package:fin_sight_ai/features/receivables/presentation/bloc/receivable_bloc.dart';
import 'package:fin_sight_ai/features/receivables/presentation/bloc/receivable_event.dart';
import 'package:fin_sight_ai/features/receivables/presentation/bloc/receivable_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetReceivables extends Mock implements GetReceivablesUseCase {}

class MockAddReceivable extends Mock implements AddReceivableUseCase {}

class MockMakeReceivablePayment extends Mock
    implements MakeReceivablePaymentUseCase {}

class MockDeleteReceivable extends Mock implements DeleteReceivableUseCase {}

class MockUpdateReceivable extends Mock implements UpdateReceivableUseCase {}

void main() {
  final dateLent = DateTime.utc(2026, 10, 1);
  final receivable = ReceivableEntity(
    id: 'receivable-1',
    debtorName: 'Ana',
    totalAmount: 1000,
    remainingAmount: 600,
    dateLent: dateLent,
    dueDate: DateTime.utc(2026, 12, 1),
    createdAt: dateLent,
    updatedAt: dateLent,
  );

  late MockGetReceivables getReceivables;
  late MockAddReceivable addReceivable;
  late MockUpdateReceivable updateReceivable;
  late MockMakeReceivablePayment makePayment;
  late MockDeleteReceivable deleteReceivable;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      AddReceivableParams(
        debtorName: 'Ana',
        totalAmount: 10,
        dateLent: dateLent,
      ),
    );
    registerFallbackValue(
      UpdateReceivableParams(
        id: 'receivable-1',
        debtorName: 'Ana',
        totalAmount: 10,
        dateLent: dateLent,
      ),
    );
    registerFallbackValue(
      const MakeReceivablePaymentParams(
        receivableId: 'receivable-1',
        amount: 1,
      ),
    );
  });

  setUp(() {
    getReceivables = MockGetReceivables();
    addReceivable = MockAddReceivable();
    updateReceivable = MockUpdateReceivable();
    makePayment = MockMakeReceivablePayment();
    deleteReceivable = MockDeleteReceivable();
  });

  ReceivableBloc buildBloc() => ReceivableBloc(
    getReceivables,
    addReceivable,
    updateReceivable,
    makePayment,
    deleteReceivable,
  );

  group('ReceivableBloc', () {
    test('initial state is ReceivableInitial', () {
      expect(buildBloc().state, const ReceivableInitial());
    });

    blocTest<ReceivableBloc, ReceivableState>(
      'loads receivables successfully',
      setUp: () {
        when(() => getReceivables(any()))
            .thenAnswer((_) async => Right([receivable]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadReceivables()),
      expect: () => [
        const ReceivableLoading(),
        ReceivableLoaded(receivables: [receivable]),
      ],
    );

    blocTest<ReceivableBloc, ReceivableState>(
      'emits empty when there are no receivables',
      setUp: () {
        when(() => getReceivables(any()))
            .thenAnswer((_) async => const Right([]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadReceivables()),
      expect: () => [const ReceivableLoading(), const ReceivableEmpty()],
    );

    blocTest<ReceivableBloc, ReceivableState>(
      'emits failure when loading fails',
      setUp: () {
        when(() => getReceivables(any()))
            .thenAnswer((_) async => const Left(CacheFailure('Store down.')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadReceivables()),
      expect: () => [
        const ReceivableLoading(),
        const ReceivableFailure('Store down.'),
      ],
    );

    blocTest<ReceivableBloc, ReceivableState>(
      'adds a receivable and reloads',
      setUp: () {
        when(() => addReceivable(any()))
            .thenAnswer((_) async => Right(receivable));
        when(() => getReceivables(any()))
            .thenAnswer((_) async => Right([receivable]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        AddReceivable(debtorName: 'Ana', totalAmount: 1000, dateLent: dateLent),
      ),
      expect: () => [
        const ReceivableLoading(),
        ReceivableLoaded(receivables: [receivable]),
      ],
      verify: (_) {
        verify(() => addReceivable(any())).called(1);
      },
    );

    blocTest<ReceivableBloc, ReceivableState>(
      'emits failure when adding is rejected',
      setUp: () {
        when(() => addReceivable(any())).thenAnswer(
          (_) async =>
              const Left(ValidationFailure('Debtor name is required.')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        AddReceivable(debtorName: '', totalAmount: 1000, dateLent: dateLent),
      ),
      expect: () => [
        const ReceivableLoading(),
        const ReceivableFailure('Debtor name is required.'),
      ],
    );

    blocTest<ReceivableBloc, ReceivableState>(
      'updates a receivable and reloads',
      setUp: () {
        when(() => updateReceivable(any()))
            .thenAnswer((_) async => Right(receivable));
        when(() => getReceivables(any()))
            .thenAnswer((_) async => Right([receivable]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        UpdateReceivable(
          id: 'receivable-1',
          debtorName: 'Ana',
          totalAmount: 1000,
          dateLent: dateLent,
        ),
      ),
      expect: () => [
        const ReceivableLoading(),
        ReceivableLoaded(receivables: [receivable]),
      ],
      verify: (_) {
        verify(() => updateReceivable(any())).called(1);
      },
    );

    blocTest<ReceivableBloc, ReceivableState>(
      'records a payment and reloads',
      setUp: () {
        final updated = receivable.copyWith(remainingAmount: 200);
        when(() => makePayment(any())).thenAnswer((_) async => Right(updated));
        when(() => getReceivables(any()))
            .thenAnswer((_) async => Right([updated]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const RecordReceivablePayment(
          receivableId: 'receivable-1',
          amount: 400,
          note: 'Cash',
        ),
      ),
      expect: () => [
        const ReceivableLoading(),
        ReceivableLoaded(
          receivables: [receivable.copyWith(remainingAmount: 200)],
        ),
      ],
    );

    blocTest<ReceivableBloc, ReceivableState>(
      'emits failure when a payment is rejected',
      setUp: () {
        when(() => makePayment(any())).thenAnswer(
          (_) async =>
              const Left(ValidationFailure('Payment amount is invalid.')),
        );
      },
      build: buildBloc,
      act: (bloc) => bloc.add(
        const RecordReceivablePayment(receivableId: 'receivable-1', amount: 0),
      ),
      expect: () => [
        const ReceivableLoading(),
        const ReceivableFailure('Payment amount is invalid.'),
      ],
    );

    blocTest<ReceivableBloc, ReceivableState>(
      'deletes a receivable and reloads',
      setUp: () {
        when(() => deleteReceivable(any()))
            .thenAnswer((_) async => const Right(null));
        when(() => getReceivables(any()))
            .thenAnswer((_) async => const Right([]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const DeleteReceivable('receivable-1')),
      expect: () => [const ReceivableLoading(), const ReceivableEmpty()],
      verify: (_) {
        verify(() => deleteReceivable('receivable-1')).called(1);
      },
    );

    blocTest<ReceivableBloc, ReceivableState>(
      'emits failure when deletion fails',
      setUp: () {
        when(
          () => deleteReceivable(any()),
        ).thenAnswer((_) async => const Left(CacheFailure('Delete failed.')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const DeleteReceivable('receivable-1')),
      expect: () => [
        const ReceivableLoading(),
        const ReceivableFailure('Delete failed.'),
      ],
    );

    test('computes outstanding total and active count', () {
      final state = ReceivableLoaded(
        receivables: [
          receivable,
          receivable.copyWith(id: 'receivable-2', remainingAmount: 100),
          receivable.copyWith(
            id: 'receivable-3',
            remainingAmount: 0,
            status: ReceivableStatus.paid,
          ),
        ],
      );

      expect(state.totalOutstanding, 700);
      expect(state.activeCount, 2);
      expect(
        state,
        ReceivableLoaded(
          receivables: [
            receivable,
            receivable.copyWith(id: 'receivable-2', remainingAmount: 100),
            receivable.copyWith(
              id: 'receivable-3',
              remainingAmount: 0,
              status: ReceivableStatus.paid,
            ),
          ],
        ),
      );
    });
  });
}
