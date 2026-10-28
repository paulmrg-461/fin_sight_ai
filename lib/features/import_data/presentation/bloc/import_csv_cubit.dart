import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../transactions/domain/usecases/import_transactions_csv_usecase.dart';
import 'import_csv_state.dart';

@injectable
class ImportCsvCubit extends Cubit<ImportCsvState> {
  ImportCsvCubit(this._importCsv) : super(const ImportCsvIdle());

  final ImportTransactionsCsvUseCase _importCsv;

  Future<void> import(String csv, {String? walletId}) async {
    emit(const ImportCsvRunning());
    final result = await _importCsv(
      ImportTransactionsCsvParams(csv: csv, walletId: walletId),
    );
    result.fold(
      (failure) => emit(ImportCsvFailure(failure.message)),
      (summary) => emit(ImportCsvSuccess(summary)),
    );
  }

  void reset() => emit(const ImportCsvIdle());
}
