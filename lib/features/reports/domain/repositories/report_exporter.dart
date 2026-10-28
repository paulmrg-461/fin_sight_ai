import 'dart:typed_data';

import '../../../../core/usecase/usecase.dart';

/// Shares an exported report file with the platform share sheet.
abstract interface class ReportExporter {
  ResultFuture<String> shareCsv({
    required String fileName,
    required String csv,
    required String subject,
  });

  ResultFuture<String> sharePdf({
    required String fileName,
    required Uint8List bytes,
    required String subject,
  });
}
