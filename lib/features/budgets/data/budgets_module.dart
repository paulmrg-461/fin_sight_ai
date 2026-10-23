import 'package:injectable/injectable.dart';

import '../../../core/services/app_boxes.dart';
import 'datasources/budget_local_data_source.dart';
import 'datasources/hive_budget_local_data_source.dart';

@module
abstract class BudgetsModule {
  @lazySingleton
  BudgetLocalDataSource provideBudgetLocalDataSource(AppBoxes boxes) =>
      HiveBudgetLocalDataSource(boxes.budgets);
}
