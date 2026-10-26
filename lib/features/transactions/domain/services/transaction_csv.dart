import '../entities/transaction_entity.dart';

/// Builds a spreadsheet-friendly CSV for the visible transactions.
///
/// The output is intentionally machine-readable: the type and date use stable
/// English/ISO values, while descriptions and categories keep their original
/// text. Amounts are positive magnitudes.
abstract final class TransactionCsv {
  static const String header = 'date,type,category,description,amount,wallet';

  static String build(List<TransactionEntity> transactions) {
    final rows = <String>[header];
    for (final transaction in transactions) {
      rows.add(
        [
          _date(transaction.date),
          transaction.type.name,
          _escape(transaction.category),
          _escape(transaction.description),
          transaction.amount.toStringAsFixed(2),
          _escape(transaction.walletId ?? ''),
        ].join(','),
      );
    }
    return rows.join('\n');
  }

  static String _date(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static String _escape(String value) {
    if (!value.contains(RegExp('[",\\n\\r]'))) {
      return value;
    }
    return '"${value.replaceAll('"', '""')}"';
  }
}
