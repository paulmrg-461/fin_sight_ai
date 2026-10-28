import 'package:bloc_test/bloc_test.dart';
import 'package:fin_sight_ai/core/domain/failure.dart';
import 'package:fin_sight_ai/features/import_data/presentation/bloc/import_csv_cubit.dart';
import 'package:fin_sight_ai/features/import_data/presentation/bloc/import_csv_state.dart';
import 'package:fin_sight_ai/features/transactions/domain/usecases/import_transactions_csv_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockImportCsv extends Mock implements ImportTransactionsCsvUseCase {}

void main() {
  late MockImportCsv importCsv;
  const summary = CsvImportSummary(imported: 2, skipped: 1, failed: 0);

  setUpAll(() {
    registerFallbackValue(const ImportTransactionsCsvParams(csv: 'csv'));
  });

  setUp(() {
    importCsv = MockImportCsv();
  });

  ImportCsvCubit buildCubit() => ImportCsvCubit(importCsv);

  blocTest<ImportCsvCubit, ImportCsvState>(
    'emits success with the summary',
    setUp: () {
      when(() => importCsv(any()))
          .thenAnswer((_) async => const Right(summary));
    },
    build: buildCubit,
    act: (cubit) => cubit.import('csv'),
    expect: () => [const ImportCsvRunning(), const ImportCsvSuccess(summary)],
  );

  blocTest<ImportCsvCubit, ImportCsvState>(
    'emits failure',
    setUp: () {
      when(() => importCsv(any())).thenAnswer(
        (_) async => const Left(
          ValidationFailure('No valid rows.', code: 'csv_no_rows'),
        ),
      );
    },
    build: buildCubit,
    act: (cubit) => cubit.import('csv'),
    expect: () => [
      const ImportCsvRunning(),
      const ImportCsvFailure('No valid rows.'),
    ],
  );
}
