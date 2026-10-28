import 'dart:io';

import 'package:fin_sight_ai/features/reports/data/repositories/share_report_exporter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late List<ShareParams> shares;
  late bool failShare;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('finsight_report_');
    shares = [];
    failShare = false;
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  ShareReportExporter exporter() =>
      ShareReportExporter.withOverrides(() async => directory, (params) async {
        if (failShare) {
          throw StateError('share down');
        }
        shares.add(params);
      });

  test('writes the CSV and opens the share sheet', () async {
    final result = await exporter().shareCsv(
      fileName: 'report.csv',
      csv: 'date,type\n2026-10-01,expense',
      subject: 'FinSight',
    );

    final path = result.getOrElse((_) => fail('Expected path'));
    expect(path, '${directory.path}/report.csv');
    expect(await File(path).readAsString(), contains('expense'));
    expect(shares.single.subject, 'FinSight');
    expect(shares.single.files?.single.path, path);
  });

  test('writes a PDF and shares it with the pdf mime type', () async {
    final bytes = Uint8List.fromList([37, 80, 68, 70]);

    final result = await exporter().sharePdf(
      fileName: 'annual.pdf',
      bytes: bytes,
      subject: 'FinSight annual',
    );

    final path = result.getOrElse((_) => fail('Expected path'));
    expect(await File(path).readAsBytes(), bytes);
    expect(shares.single.files?.single.mimeType, 'application/pdf');
    expect(shares.single.subject, 'FinSight annual');
  });

  test('uses the platform share sheet by default', () async {
    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
    const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      pathChannel,
      (call) async => directory.path,
    );
    messenger.setMockMethodCallHandler(
      shareChannel,
      (call) async => 'dev.fluttercommunity.plus/share/success',
    );
    addTearDown(() {
      messenger.setMockMethodCallHandler(pathChannel, null);
      messenger.setMockMethodCallHandler(shareChannel, null);
    });

    final result = await ShareReportExporter().shareCsv(
      fileName: 'default.csv',
      csv: 'data',
      subject: 'FinSight',
    );

    expect(result.isRight(), isTrue);
    expect(await File('${directory.path}/default.csv').exists(), isTrue);
  });

  test('maps share failures', () async {
    failShare = true;

    final result = await exporter().shareCsv(
      fileName: 'report.csv',
      csv: 'data',
      subject: 'FinSight',
    );

    expect(result.getLeft().toNullable()?.code, 'report_share_failed');
  });
}
