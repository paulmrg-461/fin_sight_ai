import 'package:fin_sight_ai/core/routing/app_router.dart';
import 'package:fin_sight_ai/core/routing/app_routes.dart';
import 'package:fin_sight_ai/core/theme/theme_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('buildRouter', () {
    test('generates a named location for every feature route', () {
      final router = buildRouter(themeController: ThemeController());

      expect(
        router.namedLocation(AppRoutes.dashboardName),
        AppRoutes.dashboardPath,
      );
      expect(
        router.namedLocation(AppRoutes.transactionsName),
        AppRoutes.transactionsPath,
      );
      expect(router.namedLocation(AppRoutes.debtsName), AppRoutes.debtsPath);
      expect(router.namedLocation(AppRoutes.ocrName), AppRoutes.ocrPath);
      expect(
        router.namedLocation(AppRoutes.aiCoachName),
        AppRoutes.aiCoachPath,
      );
    });

    test('starts on the dashboard route', () {
      final router = buildRouter(themeController: ThemeController());

      expect(
        router.routeInformationProvider.value.uri.path,
        AppRoutes.dashboardPath,
      );
    });

    test('builds parameterized locations without throwing', () {
      final router = buildRouter(themeController: ThemeController());

      expect(
        router.namedLocation(
          AppRoutes.transactionsName,
          queryParameters: {'filter': 'month'},
        ),
        '/transactions?filter=month',
      );
    });
  });
}
