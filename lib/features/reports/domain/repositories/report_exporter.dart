import '../../../../core/usecase/usecase.dart';

/// Shares an exported report file with the platform share sheet.
abstract interface class ReportExporter {
  ResultFuture<String> shareCsv({
    required String fileName,
    required String csv,
    required String subject,
  });
}
