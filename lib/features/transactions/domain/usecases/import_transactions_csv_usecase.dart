import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';
import '../services/transaction_csv_importer.dart';
import 'add_transaction_usecase.dart';

class ImportTransactionsCsvParams {
  const ImportTransactionsCsvParams({required this.csv, this.walletId});

  final String csv;
  final String? walletId;
}

class CsvImportSummary {
  const CsvImportSummary({
    required this.imported,
    required this.skipped,
    required this.failed,
    this.errors = const [],
  });

  final int imported;
  final int skipped;
  final int failed;
  final List<CsvRowError> errors;

  @override
  String toString() =>
      'CsvImportSummary(imported: $imported, skipped: $skipped, '
      'failed: $failed)';
}

/// Imports transactions from CSV, skipping rows that already exist.
@lazySingleton
class ImportTransactionsCsvUseCase
    implements UseCase<CsvImportSummary, ImportTransactionsCsvParams> {
  const ImportTransactionsCsvUseCase(this._repository, this._addTransaction);

  final TransactionRepository _repository;
  final AddTransactionUseCase _addTransaction;

  @override
  Future<Result<CsvImportSummary>> call(
    ImportTransactionsCsvParams params,
  ) async {
    final parsed = TransactionCsvImporter.parse(params.csv);
    if (parsed.isEmpty) {
      return const Left(
        ValidationFailure(
          'No valid rows were found in the CSV.',
          code: 'csv_no_rows',
        ),
      );
    }

    final existingResult = await _repository.getTransactions();
    final existingFailure = existingResult.getLeft().toNullable();
    if (existingFailure != null) {
      return Left(existingFailure);
    }
    final seen = <String>{
      for (final transaction in existingResult.getOrElse((_) => const []))
        _key(
          date: transaction.date,
          amount: transaction.amount,
          type: transaction.type,
          category: transaction.category,
          description: transaction.description,
        ),
    };

    var imported = 0;
    var skipped = 0;
    var failed = 0;
    final errors = <CsvRowError>[...parsed.errors];

    for (final row in parsed.rows) {
      final key = _key(
        date: row.date,
        amount: row.amount,
        type: row.type,
        category: row.category,
        description: row.description,
      );
      if (!seen.add(key)) {
        skipped++;
        continue;
      }
      final result = await _addTransaction(
        AddTransactionParams(
          amount: row.amount,
          type: row.type,
          category: row.category,
          description: row.description,
          date: row.date,
          walletId: row.walletId ?? params.walletId,
        ),
      );
      final failure = result.getLeft().toNullable();
      if (failure != null) {
        failed++;
        errors.add(CsvRowError(row.line, failure.message));
      } else {
        imported++;
      }
    }

    if (imported == 0 && failed == 0 && skipped == 0) {
      return const Left(
        ValidationFailure(
          'No valid rows were found in the CSV.',
          code: 'csv_no_rows',
        ),
      );
    }
    return Right(
      CsvImportSummary(
        imported: imported,
        skipped: skipped,
        failed: failed,
        errors: List<CsvRowError>.unmodifiable(errors),
      ),
    );
  }

  String _key({
    required DateTime date,
    required double amount,
    required TransactionType type,
    required String category,
    required String description,
  }) {
    final day =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '$day|${amount.toStringAsFixed(2)}|${type.name}|'
        '${category.trim().toLowerCase()}|${description.trim().toLowerCase()}';
  }
}
