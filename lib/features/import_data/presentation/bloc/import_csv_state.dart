import 'package:equatable/equatable.dart';

import '../../../transactions/domain/usecases/import_transactions_csv_usecase.dart';

sealed class ImportCsvState extends Equatable {
  const ImportCsvState();

  @override
  List<Object?> get props => const [];
}

final class ImportCsvIdle extends ImportCsvState {
  const ImportCsvIdle();
}

final class ImportCsvRunning extends ImportCsvState {
  const ImportCsvRunning();
}

final class ImportCsvSuccess extends ImportCsvState {
  const ImportCsvSuccess(this.summary);

  final CsvImportSummary summary;

  @override
  List<Object?> get props => [summary];
}

final class ImportCsvFailure extends ImportCsvState {
  const ImportCsvFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
