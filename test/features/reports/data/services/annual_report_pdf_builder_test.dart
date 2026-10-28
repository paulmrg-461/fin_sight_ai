import 'package:fin_sight_ai/core/currency/app_currency.dart';
import 'package:fin_sight_ai/features/reports/data/services/annual_report_pdf_builder.dart';
import 'package:fin_sight_ai/features/reports/domain/entities/annual_report.dart';
import 'package:fin_sight_ai/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AnnualReport report() {
    return AnnualReport.fromTransactions(
      year: 2026,
      transactions: [
        TransactionEntity(
          id: 'tx-1',
          amount: 1200,
          type: TransactionType.income,
          category: 'Salary',
          description: 'Salary',
          date: DateTime.utc(2026, 1, 1),
        ),
        TransactionEntity(
          id: 'tx-2',
          amount: 300.5,
          type: TransactionType.expense,
          category: 'Food',
          description: 'Groceries',
          date: DateTime.utc(2026, 1, 15),
        ),
      ],
    );
  }

  test('renders a PDF document', () async {
    final bytes = await AnnualReportPdfBuilder().build(
      report(),
      currency: AppCurrency.cop,
      title: 'FinSight AI - 2026',
    );

    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(bytes.length, greaterThan(1000));
  });

  test('renders for USD without throwing', () async {
    final bytes = await AnnualReportPdfBuilder().build(
      report(),
      currency: AppCurrency.usd,
      title: 'Annual report',
    );

    expect(bytes, isNotEmpty);
  });
}
