import 'package:injectable/injectable.dart';

import '../../../core/services/app_boxes.dart';
import 'datasources/hive_scheduled_payment_local_data_source.dart';
import 'datasources/scheduled_payment_local_data_source.dart';

@module
abstract class ScheduledPaymentsModule {
  @lazySingleton
  ScheduledPaymentLocalDataSource provideScheduledPaymentLocalDataSource(
    AppBoxes boxes,
  ) => HiveScheduledPaymentLocalDataSource(boxes.scheduledPayments);
}
