import 'package:injectable/injectable.dart';

import '../../../core/services/app_boxes.dart';
import 'datasources/hive_receipt_local_data_source.dart';
import 'datasources/receipt_local_data_source.dart';

/// OCR-related registrations that need an open Hive box.
@module
abstract class OcrModule {
  @lazySingleton
  ReceiptLocalDataSource provideReceiptLocalDataSource(AppBoxes boxes) =>
      HiveReceiptLocalDataSource(boxes.receipts);
}
