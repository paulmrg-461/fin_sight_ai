import 'package:injectable/injectable.dart';

import '../services/app_boxes.dart';
import 'hive_locale_repository.dart';
import 'locale_repository.dart';

@module
abstract class LocaleModule {
  @lazySingleton
  LocaleRepository provideLocaleRepository(AppBoxes boxes) =>
      HiveLocaleRepository(boxes.settings);
}
