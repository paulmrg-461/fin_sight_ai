import 'package:go_router/go_router.dart';

import '../../features/ai_coach/presentation/screens/ai_coach_screen.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/debts/presentation/screens/debt_list_screen.dart';
import '../../features/ocr/presentation/screens/ocr_screen.dart';
import '../../features/transactions/presentation/screens/transaction_screen.dart';
import '../services/receipt_image_picker.dart';
import '../theme/theme_controller.dart';
import 'app_routes.dart';

/// Builds the app router. Kept as a pure function so routing can be tested
/// without the service locator.
GoRouter buildRouter({
  required ThemeController themeController,
  required ReceiptImagePicker receiptImagePicker,
}) {
  return GoRouter(
    initialLocation: AppRoutes.dashboardPath,
    routes: [
      GoRoute(
        path: AppRoutes.dashboardPath,
        name: AppRoutes.dashboardName,
        builder: (context, state) =>
            DashboardPage(themeController: themeController),
      ),
      GoRoute(
        path: AppRoutes.transactionsPath,
        name: AppRoutes.transactionsName,
        builder: (context, state) => const TransactionScreen(),
      ),
      GoRoute(
        path: AppRoutes.debtsPath,
        name: AppRoutes.debtsName,
        builder: (context, state) => const DebtListScreen(),
      ),
      GoRoute(
        path: AppRoutes.ocrPath,
        name: AppRoutes.ocrName,
        builder: (context, state) => OcrScreen(imagePicker: receiptImagePicker),
      ),
      GoRoute(
        path: AppRoutes.aiCoachPath,
        name: AppRoutes.aiCoachName,
        builder: (context, state) => const AiCoachScreen(),
      ),
    ],
  );
}
