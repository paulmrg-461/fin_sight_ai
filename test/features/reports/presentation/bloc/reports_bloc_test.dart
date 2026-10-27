import 'package:bloc_test/bloc_test.dart';
import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/core/usecase/usecase.dart';
import 'package:fin_sight_ai/features/reports/domain/repositories/report_exporter.dart';
import 'package:fin_sight_ai/features/reports/presentation/bloc/reports_bloc.dart';
import 'package:fin_sight_ai/features/reports/presentation/bloc/reports_event.dart';
import 'package:fin_sight_ai/features/reports/presentation/bloc/reports_state.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/get_transactions_by_date_range_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetByRange extends Mock
    implements GetTransactionsByDateRangeUseCase {}

class MockExporter extends Mock implements ReportExporter {}

void main() {
  late MockGetByRange getByRange;
  late MockExporter exporter;

  final now = DateTime.now();
  final month = DateTime(now.year, now.month);
  final transaction = TransactionEntity(
    id: 'tx-1',
    amount: 100,
    type: TransactionType.expense,
    category: 'Food',
    description: 'Lunch',
    date: month.add(const Duration(days: 1)),
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      DateRangeParams(start: DateTime(2026), end: DateTime(2026, 2)),
    );
  });

  setUp(() {
    getByRange = MockGetByRange();
    exporter = MockExporter();
    when(() => getByRange(any())).thenAnswer((_) async => Right([transaction]));
    when(
      () => exporter.shareCsv(
        fileName: any(named: 'fileName'),
        csv: any(named: 'csv'),
        subject: any(named: 'subject'),
      ),
    ).thenAnswer((_) async => const Right('/tmp/report.csv'));
  });

  ReportsBloc buildBloc() => ReportsBloc(getByRange, exporter);

  group('ReportsBloc', () {
    test('initial state is ReportsInitial', () {
      expect(buildBloc().state, const ReportsInitial());
    });

    blocTest<ReportsBloc, ReportsState>(
      'loads the current month report',
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadReports()),
      expect: () => [
        const ReportsLoading(),
        isA<ReportsLoaded>()
            .having((state) => state.report.month, 'month', month)
            .having(
              (state) => state.report.summary.totalExpenses,
              'expenses',
              100,
            ),
      ],
    );

    blocTest<ReportsBloc, ReportsState>(
      'emits empty when the month has no transactions',
      setUp: () {
        when(() => getByRange(any())).thenAnswer((_) async => const Right([]));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadReports()),
      expect: () => [const ReportsLoading(), ReportsEmpty(month)],
    );

    blocTest<ReportsBloc, ReportsState>(
      'changes month and reloads',
      build: buildBloc,
      act: (bloc) => bloc.add(ChangeReportMonth(DateTime(2026, 1, 20))),
      expect: () => [
        const ReportsLoading(),
        isA<ReportsLoaded>().having(
          (state) => state.report.month,
          'month',
          DateTime(2026),
        ),
      ],
      verify: (_) {
        verify(
          () => getByRange(
            DateRangeParams(
              start: DateTime(2026),
              end: DateTime(2026, 2, 0, 23, 59, 59, 999),
            ),
          ),
        ).called(1);
      },
    );

    blocTest<ReportsBloc, ReportsState>(
      'shares the CSV of the loaded month',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const LoadReports());
        await pumpEventQueue();
        bloc.add(const ShareCurrentReport());
      },
      expect: () => [
        const ReportsLoading(),
        isA<ReportsLoaded>(),
        isA<ReportsLoaded>().having((state) => state.sharing, 'sharing', true),
        isA<ReportsLoaded>().having(
          (state) => state.shareStatus,
          'shareStatus',
          ReportShareStatus.success,
        ),
      ],
      verify: (_) {
        final captured = verify(
          () => exporter.shareCsv(
            fileName: captureAny(named: 'fileName'),
            csv: captureAny(named: 'csv'),
            subject: any(named: 'subject'),
          ),
        ).captured;
        expect(captured[0], endsWith('.csv'));
        expect(captured[1], contains('Lunch'));
      },
    );

    blocTest<ReportsBloc, ReportsState>(
      'reports share failures',
      setUp: () {
        when(
          () => exporter.shareCsv(
            fileName: any(named: 'fileName'),
            csv: any(named: 'csv'),
            subject: any(named: 'subject'),
          ),
        ).thenAnswer(
          (_) async => const Left(
            CacheFailure(
              'Unable to share the report.',
              code: 'report_share_failed',
            ),
          ),
        );
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const LoadReports());
        await pumpEventQueue();
        bloc.add(const ShareCurrentReport());
      },
      expect: () => [
        const ReportsLoading(),
        isA<ReportsLoaded>(),
        isA<ReportsLoaded>().having((state) => state.sharing, 'sharing', true),
        isA<ReportsLoaded>()
            .having(
              (state) => state.shareStatus,
              'shareStatus',
              ReportShareStatus.failure,
            )
            .having(
              (state) => state.shareError,
              'shareError',
              'Unable to share the report.',
            ),
      ],
    );

    blocTest<ReportsBloc, ReportsState>(
      'dismisses the share message',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const LoadReports());
        await pumpEventQueue();
        bloc.add(const ShareCurrentReport());
        await pumpEventQueue();
        bloc.add(const DismissReportShare());
      },
      verify: (bloc) {
        final state = bloc.state;
        expect(state, isA<ReportsLoaded>());
        expect((state as ReportsLoaded).shareStatus, ReportShareStatus.none);
      },
    );
  });
}
