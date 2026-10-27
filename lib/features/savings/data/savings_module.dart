import 'package:injectable/injectable.dart';

import '../../../core/services/app_boxes.dart';
import 'datasources/hive_savings_local_data_source.dart';
import 'datasources/savings_local_data_source.dart';

@module
abstract class SavingsModule {
  @lazySingleton
  SavingsLocalDataSource provideSavingsLocalDataSource(AppBoxes boxes) =>
      HiveSavingsLocalDataSource(boxes.savingsGoals);
}
