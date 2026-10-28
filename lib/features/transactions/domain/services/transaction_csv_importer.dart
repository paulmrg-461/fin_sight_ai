import '../entities/transaction_entity.dart';

/// One valid row parsed from an imported CSV.
class ImportedTransactionRow {
  const ImportedTransactionRow({
    required this.line,
    required this.date,
    required this.type,
    required this.category,
    required this.description,
    required this.amount,
    this.walletId,
  });

  final int line;
  final DateTime date;
  final TransactionType type;
  final String category;
  final String description;
  final double amount;
  final String? walletId;
}

class CsvRowError {
  const CsvRowError(this.line, this.message);

  final int line;
  final String message;
}

class ParsedTransactionCsv {
  const ParsedTransactionCsv({required this.rows, required this.errors});

  final List<ImportedTransactionRow> rows;
  final List<CsvRowError> errors;

  bool get isEmpty => rows.isEmpty;
}

/// Tolerant CSV importer for bank-style transaction exports.
abstract final class TransactionCsvImporter {
  static ParsedTransactionCsv parse(String csv) {
    final rows = <ImportedTransactionRow>[];
    final errors = <CsvRowError>[];
    final records = _records(csv);
    if (records.isEmpty) {
      return const ParsedTransactionCsv(rows: [], errors: []);
    }

    var start = 0;
    Map<String, int>? columns;
    final first = records.first.fields.map(
      (field) => field.toLowerCase().trim(),
    );
    if (first.contains('date') || first.contains('fecha')) {
      columns = _columns(records.first.fields);
      start = 1;
    }

    for (var index = start; index < records.length; index++) {
      final record = records[index];
      final line = record.line;
      final fields = record.fields;
      if (fields.every((field) => field.trim().isEmpty)) {
        continue;
      }
      try {
        final dateIndex = columns?['date'] ?? 0;
        final typeIndex = columns?['type'] ?? 1;
        final categoryIndex = columns?['category'] ?? 2;
        final descriptionIndex = columns?['description'] ?? 3;
        final amountIndex = columns?['amount'] ?? 4;
        final walletIndex = columns?['wallet'] ?? 5;

        String field(int position) =>
            position >= 0 && position < fields.length ? fields[position] : '';

        final parsedDate = _parseDate(field(dateIndex));
        if (parsedDate == null) {
          throw const FormatException('Invalid date.');
        }
        final amount = _parseAmount(field(amountIndex));
        if (amount == null || amount == 0) {
          throw const FormatException('Invalid amount.');
        }
        final type = _parseType(field(typeIndex), amount);
        final category = field(categoryIndex).trim();
        final description = field(descriptionIndex).trim();
        final wallet = field(walletIndex).trim();

        rows.add(
          ImportedTransactionRow(
            line: line,
            date: parsedDate,
            type: type,
            category: category.isEmpty ? 'Other' : category,
            description: description,
            amount: amount.abs(),
            walletId: wallet.isEmpty ? null : wallet,
          ),
        );
      } on FormatException catch (error) {
        errors.add(CsvRowError(line, error.message));
      }
    }
    return ParsedTransactionCsv(
      rows: List<ImportedTransactionRow>.unmodifiable(rows),
      errors: List<CsvRowError>.unmodifiable(errors),
    );
  }

  static Map<String, int> _columns(List<String> header) {
    final normalized = header
        .map((field) => field.trim().toLowerCase())
        .toList(growable: false);
    int find(Set<String> names, int fallback) {
      final index = normalized.indexWhere(names.contains);
      return index < 0 ? fallback : index;
    }

    return {
      'date': find({'date', 'fecha'}, 0),
      'type': find({'type', 'tipo'}, 1),
      'category': find({'category', 'categoria', 'categoría'}, 2),
      'description': find({
        'description',
        'descripcion',
        'descripción',
        'concepto',
      }, 3),
      'amount': find({'amount', 'monto', 'valor'}, 4),
      'wallet': find({'wallet', 'billetera', 'cuenta'}, 5),
    };
  }

  static DateTime? _parseDate(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final iso = DateTime.tryParse(trimmed);
    if (iso != null) {
      return DateTime(iso.year, iso.month, iso.day);
    }
    final parts = trimmed.split(RegExp(r'[/-]'));
    if (parts.length != 3) {
      return null;
    }
    final first = int.tryParse(parts[0]);
    final second = int.tryParse(parts[1]);
    var year = int.tryParse(parts[2]);
    if (first == null || second == null || year == null) {
      return null;
    }
    // Prefer ISO year-first when the first part looks like a year.
    if (parts[0].length == 4) {
      year = first;
      return _validDate(year, second, int.parse(parts[2]));
    }
    if (year < 100) {
      year += 2000;
    }
    // Day-first is the common format in Colombia/LatAm.
    return _validDate(year, second, first);
  }

  static DateTime? _validDate(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  static double? _parseAmount(String value) {
    var cleaned = value.trim().replaceAll(RegExp(r'[\s$]'), '');
    if (cleaned.isEmpty) {
      return null;
    }
    final negative = cleaned.startsWith('(') && cleaned.endsWith(')');
    if (negative) {
      cleaned = '-${cleaned.substring(1, cleaned.length - 1)}';
    }
    // Detect decimal separator style: 1.234,56 (LatAm) vs 1,234.56.
    final lastComma = cleaned.lastIndexOf(',');
    final lastDot = cleaned.lastIndexOf('.');
    if (lastComma > lastDot) {
      cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
    } else {
      cleaned = cleaned.replaceAll(',', '');
    }
    final amount = double.tryParse(cleaned);
    if (amount == null || !amount.isFinite) {
      return null;
    }
    return amount;
  }

  static TransactionType _parseType(String value, double amount) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'income' ||
        normalized == 'ingreso' ||
        normalized == 'credit' ||
        normalized == 'crédito' ||
        normalized == 'credito') {
      return TransactionType.income;
    }
    if (normalized == 'expense' ||
        normalized == 'gasto' ||
        normalized == 'debit' ||
        normalized == 'débito' ||
        normalized == 'debito') {
      return TransactionType.expense;
    }
    return amount < 0 ? TransactionType.expense : TransactionType.expense;
  }

  static List<_CsvRecord> _records(String input) {
    final records = <_CsvRecord>[];
    var fields = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;
    var line = 1;
    var recordLine = 1;

    void endField() {
      fields.add(buffer.toString());
      buffer.clear();
    }

    void endRecord() {
      endField();
      if (fields.any((field) => field.isNotEmpty)) {
        records.add(_CsvRecord(recordLine, List<String>.from(fields)));
      }
      fields = <String>[];
      recordLine = line + 1;
    }

    for (var index = 0; index < input.length; index++) {
      final char = input[index];
      if (inQuotes) {
        if (char == '"') {
          if (index + 1 < input.length && input[index + 1] == '"') {
            buffer.write('"');
            index++;
          } else {
            inQuotes = false;
          }
        } else {
          if (char == '\n') {
            line++;
          }
          buffer.write(char);
        }
        continue;
      }
      switch (char) {
        case '"':
          inQuotes = true;
        case ',':
          endField();
        case '\r':
          break;
        case '\n':
          line++;
          endRecord();
        default:
          buffer.write(char);
      }
    }
    if (buffer.isNotEmpty || fields.isNotEmpty) {
      endRecord();
    }
    return records;
  }
}

class _CsvRecord {
  const _CsvRecord(this.line, this.fields);

  final int line;
  final List<String> fields;
}
