import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/repositories/report_exporter.dart';

@LazySingleton(as: ReportExporter)
class ShareReportExporter implements ReportExporter {
  ShareReportExporter()
    : _tempDirectory = getTemporaryDirectory,
      _share = _defaultShare;

  @visibleForTesting
  ShareReportExporter.withOverrides(this._tempDirectory, this._share);

  final Future<Directory> Function() _tempDirectory;
  final Future<void> Function(ShareParams) _share;

  static Future<void> _defaultShare(ShareParams params) async {
    await SharePlus.instance.share(params);
  }

  @override
  ResultFuture<String> shareCsv({
    required String fileName,
    required String csv,
    required String subject,
  }) async {
    try {
      final directory = await _tempDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csv, flush: true);
      await _share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/csv')],
          subject: subject,
        ),
      );
      return Right(file.path);
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to share the report.',
          code: 'report_share_failed',
        ),
      );
    }
  }

  @override
  ResultFuture<String> sharePdf({
    required String fileName,
    required Uint8List bytes,
    required String subject,
  }) async {
    try {
      final directory = await _tempDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      await _share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf')],
          subject: subject,
        ),
      );
      return Right(file.path);
    } catch (_) {
      return const Left(
        CacheFailure(
          'Unable to share the report.',
          code: 'report_share_failed',
        ),
      );
    }
  }
}
