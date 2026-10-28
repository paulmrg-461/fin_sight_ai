import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:fin_sight_ai/features/transactions/domain/services/transaction_csv_importer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses an English header and quoted descriptions', () {
    final parsed = TransactionCsvImporter.parse(
      'date,type,category,description,amount,wallet\n'
      '2026-10-31,expense,Dining,"Lunch, with Ana",25000,wallet-bank\n',
    );

    final row = parsed.rows.single;
    expect(row.date, DateTime(2026, 10, 31));
    expect(row.type, TransactionType.expense);
    expect(row.description, 'Lunch, with Ana');
    expect(row.amount, 25000);
    expect(row.walletId, 'wallet-bank');
    expect(parsed.errors, isEmpty);
  });

  test('parses Spanish headers, day-first dates, decimals, and income', () {
    final parsed = TransactionCsvImporter.parse(
      'fecha,tipo,categoria,descripcion,monto\n'
      '31/10/2026,ingreso,Freelance,Proyecto,"1.234,56"\n',
    );

    final row = parsed.rows.single;
    expect(row.date, DateTime(2026, 10, 31));
    expect(row.type, TransactionType.income);
    expect(row.amount, 1234.56);
    expect(row.category, 'Freelance');
  });

  test('reports invalid rows without discarding valid ones', () {
    final parsed = TransactionCsvImporter.parse(
      'date,type,category,description,amount\n'
      'not-a-date,expense,Food,Bad,10\n'
      '2026-10-31,expense,Food,Good,10\n'
      '2026-10-31,expense,Food,No amount,\n',
    );

    expect(parsed.rows, hasLength(1));
    expect(parsed.rows.single.description, 'Good');
    expect(parsed.errors, hasLength(2));
    expect(parsed.errors.first.line, 3);
  });

  test('treats parenthesized amounts as negative and defaults category', () {
    final parsed = TransactionCsvImporter.parse('2026-10-31,,,Coffee,(12000)');

    final row = parsed.rows.single;
    expect(row.amount, 12000);
    expect(row.category, 'Other');
    expect(row.type, TransactionType.expense);
  });

  test('ignores blank input', () {
    expect(TransactionCsvImporter.parse('  \n\n').isEmpty, isTrue);
    expect(TransactionCsvImporter.parse('').rows, isEmpty);
  });
}
