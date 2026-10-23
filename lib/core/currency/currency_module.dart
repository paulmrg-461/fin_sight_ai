import 'package:injectable/injectable.dart';

import '../services/app_boxes.dart';
import 'currency_repository.dart';
import 'hive_currency_repository.dart';

@module
abstract class CurrencyModule {
  @lazySingleton
  CurrencyRepository provideCurrencyRepository(AppBoxes boxes) =>
      HiveCurrencyRepository(boxes.settings);
}
