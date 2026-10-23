import 'package:injectable/injectable.dart';

import '../../../core/services/app_boxes.dart';
import 'datasources/category_local_data_source.dart';
import 'datasources/hive_category_local_data_source.dart';
import '../domain/repositories/category_repository.dart';
import 'repositories/category_repository_impl.dart';

@module
abstract class CategoriesModule {
  @lazySingleton
  CategoryLocalDataSource provideCategoryLocalDataSource(AppBoxes boxes) =>
      HiveCategoryLocalDataSource(boxes.categories);

  @lazySingleton
  CategoryRepository provideCategoryRepository(
    CategoryLocalDataSource dataSource,
  ) => CategoryRepositoryImpl(dataSource);
}
