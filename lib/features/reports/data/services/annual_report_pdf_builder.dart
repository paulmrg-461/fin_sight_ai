import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/currency/app_currency.dart';
import '../../domain/entities/annual_report.dart';

/// Renders an annual report as a shareable PDF.
@lazySingleton
class AnnualReportPdfBuilder {
  AnnualReportPdfBuilder();

  Future<Uint8List> build(
    AnnualReport report, {
    required AppCurrency currency,
    required String title,
  }) async {
    final document = pw.Document();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    String money(double amount) => MoneyFormatter.format(amount, currency);

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${currency.code} · ${report.year} · '
            '${report.transactionCount} transactions',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _metric('Income', money(report.summary.totalIncome)),
              _metric('Expenses', money(report.summary.totalExpenses)),
              _metric('Balance', money(report.summary.balance)),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Monthly breakdown',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const ['Month', 'Income', 'Expenses', 'Balance'],
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
            data: [
              for (final month in report.months)
                [
                  months[month.month.month - 1],
                  money(month.income),
                  money(month.expenses),
                  money(month.balance),
                ],
            ],
          ),
          if (report.breakdown.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Text(
              'Spending by category',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: const ['Category', 'Amount', 'Share'],
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
              },
              data: [
                for (final category in report.breakdown)
                  [
                    category.category,
                    money(category.amount),
                    '${category.percentage.round()}%',
                  ],
              ],
            ),
          ],
        ],
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
      ),
    );

    return document.save();
  }

  pw.Widget _metric(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }
}
