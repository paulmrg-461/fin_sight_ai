import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/main_shell.dart';
import '../../features/ai_coach/presentation/screens/ai_coach_screen.dart';
import '../../features/ai_coach/presentation/screens/coach_chat_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../core/currency/presentation/screens/settings_screen.dart';
import '../../features/budgets/presentation/screens/budget_screen.dart';
import '../../features/categories/presentation/screens/categories_screen.dart';
import '../../features/savings/presentation/screens/savings_goals_screen.dart';
import '../../features/search/presentation/screens/global_search_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/import_data/presentation/screens/import_csv_screen.dart';
import '../../features/developer/presentation/screens/developer_info_screen.dart';
import '../../features/scheduled_payments/presentation/screens/scheduled_payment_screen.dart';
import '../../features/wallets/presentation/screens/wallet_screen.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/debts/presentation/screens/debt_list_screen.dart';
import '../../features/receivables/presentation/screens/receivable_list_screen.dart';
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
      StatefulShellRoute(
        builder: (context, state, navigationShell) => MainShell(
          navigationShell: navigationShell,
          themeController: themeController,
        ),
        navigatorContainerBuilder: (context, navigationShell, children) =>
            _AnimatedBranchContainer(
              index: navigationShell.currentIndex,
              children: children,
            ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboardPath,
                name: AppRoutes.dashboardName,
                builder: (context, state) => const DashboardPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.transactionsPath,
                name: AppRoutes.transactionsName,
                builder: (context, state) => const TransactionScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.budgetsPath,
                name: AppRoutes.budgetsName,
                builder: (context, state) => const BudgetScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.scheduledPaymentsPath,
                name: AppRoutes.scheduledPaymentsName,
                builder: (context, state) => const ScheduledPaymentScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.moneyPath,
                name: AppRoutes.moneyName,
                builder: (context, state) => const WalletScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.debtsPath,
        name: AppRoutes.debtsName,
        builder: (context, state) => const DebtListScreen(),
      ),
      GoRoute(
        path: AppRoutes.receivablesPath,
        name: AppRoutes.receivablesName,
        builder: (context, state) => const ReceivableListScreen(),
      ),
      GoRoute(
        path: AppRoutes.ocrPath,
        name: AppRoutes.ocrName,
        builder: (context, state) => OcrScreen(imagePicker: receiptImagePicker),
      ),
      GoRoute(
        path: AppRoutes.importCsvPath,
        name: AppRoutes.importCsvName,
        builder: (context, state) => const ImportCsvScreen(),
      ),
      GoRoute(
        path: AppRoutes.developerPath,
        name: AppRoutes.developerName,
        builder: (context, state) => const DeveloperInfoScreen(),
      ),
      GoRoute(
        path: AppRoutes.reportsPath,
        name: AppRoutes.reportsName,
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.searchPath,
        name: AppRoutes.searchName,
        builder: (context, state) => const GlobalSearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.aiCoachPath,
        name: AppRoutes.aiCoachName,
        builder: (context, state) => const AiCoachScreen(),
      ),
      GoRoute(
        path: AppRoutes.coachChatPath,
        name: AppRoutes.coachChatName,
        builder: (context, state) => const CoachChatScreen(),
      ),
      GoRoute(
        path: AppRoutes.loginPath,
        name: AppRoutes.loginName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.settingsPath,
        name: AppRoutes.settingsName,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.savingsPath,
        name: AppRoutes.savingsName,
        builder: (context, state) => const SavingsGoalsScreen(),
      ),
      GoRoute(
        path: AppRoutes.categoriesPath,
        name: AppRoutes.categoriesName,
        builder: (context, state) => const CategoriesScreen(),
      ),
    ],
  );
}

/// Keeps every branch mounted (state preserved) and fades/slides the newly
/// selected one into view. Inactive branches stay offstage so finders, focus,
/// and semantics behave exactly like the default indexed stack.
class _AnimatedBranchContainer extends StatefulWidget {
  const _AnimatedBranchContainer({required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<_AnimatedBranchContainer> createState() =>
      _AnimatedBranchContainerState();
}

class _AnimatedBranchContainerState extends State<_AnimatedBranchContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1,
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _opacity = curved;
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.015),
      end: Offset.zero,
    ).animate(curved);
  }

  @override
  void didUpdateWidget(_AnimatedBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var index = 0; index < widget.children.length; index++)
          Offstage(
            offstage: index != widget.index,
            child: TickerMode(
              enabled: index == widget.index,
              child: index == widget.index
                  ? FadeTransition(
                      opacity: _opacity,
                      child: SlideTransition(
                        position: _offset,
                        child: widget.children[index],
                      ),
                    )
                  : widget.children[index],
            ),
          ),
      ],
    );
  }
}
