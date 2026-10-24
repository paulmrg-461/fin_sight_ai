import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/l10n/l10n.dart';
import '../core/routing/app_routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/theme_controller.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/sync/presentation/widgets/sync_status_chip.dart';
import 'branding/app_logo.dart';

/// Route names rendered inside the navigation shell, in bottom-bar order.
const List<String> primaryRouteNames = [
  AppRoutes.dashboardName,
  AppRoutes.transactionsName,
  AppRoutes.budgetsName,
  AppRoutes.scheduledPaymentsName,
  AppRoutes.moneyName,
];

/// Exposes shell navigation to branch screens without global keys.
class ShellScope extends InheritedWidget {
  const ShellScope({
    super.key,
    required this.openDrawer,
    required this.goToPrimary,
    required super.child,
  });

  /// Opens the shell drawer.
  final VoidCallback openDrawer;

  /// Switches to a primary branch. Returns `false` for secondary routes.
  final bool Function(String routeName) goToPrimary;

  static ShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope oldWidget) =>
      openDrawer != oldWidget.openDrawer ||
      goToPrimary != oldWidget.goToPrimary;
}

/// Hamburger button for primary branch app bars.
class AppMenuButton extends StatelessWidget {
  const AppMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final openDrawer =
        ShellScope.maybeOf(context)?.openDrawer ??
        Scaffold.maybeOf(context)?.openDrawer;

    return IconButton(
      onPressed: openDrawer,
      tooltip: context.l10n.openMenu,
      icon: const Icon(Icons.menu),
    );
  }
}

/// Shell around the five primary branches: drawer plus bottom navigation bar.
class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.navigationShell,
    required this.themeController,
  });

  final StatefulNavigationShell navigationShell;
  final ThemeController themeController;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  void _selectBranch(int index) {
    HapticFeedback.selectionClick();
    _scaffoldKey.currentState?.closeDrawer();
    final navigationShell = widget.navigationShell;
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  bool _goToPrimary(String routeName) {
    final index = primaryRouteNames.indexOf(routeName);
    if (index < 0) {
      return false;
    }
    _selectBranch(index);
    return true;
  }

  void _goToSecondary(String routeName) {
    _scaffoldKey.currentState?.closeDrawer();
    context.pushNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final navigationShell = widget.navigationShell;

    return Scaffold(
      key: _scaffoldKey,
      drawer: AppDrawer(
        themeController: widget.themeController,
        currentIndex: navigationShell.currentIndex,
        onPrimarySelected: _selectBranch,
        onSecondarySelected: _goToSecondary,
      ),
      body: ShellScope(
        openDrawer: _openDrawer,
        goToPrimary: _goToPrimary,
        child: navigationShell,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _selectBranch,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: l10n.dashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: l10n.transactions,
          ),
          NavigationDestination(
            icon: const Icon(Icons.pie_chart_outline),
            selectedIcon: const Icon(Icons.pie_chart),
            label: l10n.budgets,
          ),
          NavigationDestination(
            icon: const Icon(Icons.event_repeat_outlined),
            selectedIcon: const Icon(Icons.event_repeat),
            label: l10n.scheduledTab,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet),
            label: l10n.money,
          ),
        ],
      ),
    );
  }
}

/// Global navigation drawer: primary destinations, secondary features, and
/// preferences.
class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.themeController,
    required this.currentIndex,
    required this.onPrimarySelected,
    required this.onSecondarySelected,
  });

  final ThemeController themeController;
  final int currentIndex;
  final ValueChanged<int> onPrimarySelected;
  final ValueChanged<String> onSecondarySelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final primary = [
      (icon: Icons.dashboard_outlined, label: l10n.dashboard),
      (icon: Icons.receipt_long_outlined, label: l10n.transactions),
      (icon: Icons.pie_chart_outline, label: l10n.budgets),
      (icon: Icons.event_repeat_outlined, label: l10n.scheduledPayments),
      (icon: Icons.account_balance_wallet_outlined, label: l10n.money),
    ];

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.navy, Color(0xFF0C3B38)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppLogo(
                    size: 48,
                    showWordmark: true,
                    wordmarkStyle: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final label = state is AuthAuthenticated
                          ? state.session.email
                          : l10n.signInToSync;
                      return Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _SectionLabel(text: l10n.mainMenu),
            for (final (index, destination) in primary.indexed)
              ListTile(
                leading: Icon(destination.icon),
                title: Text(destination.label),
                selected: index == currentIndex,
                onTap: () => onPrimarySelected(index),
              ),
            const Divider(),
            _SectionLabel(text: l10n.more),
            ListTile(
              leading: const Icon(Icons.account_balance_outlined),
              title: Text(l10n.debts),
              onTap: () => onSecondarySelected(AppRoutes.debtsName),
            ),
            ListTile(
              leading: const Icon(Icons.handshake_outlined),
              title: Text(l10n.owedToMe),
              onTap: () => onSecondarySelected(AppRoutes.receivablesName),
            ),
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: Text(l10n.categoriesTitle),
              onTap: () => onSecondarySelected(AppRoutes.categoriesName),
            ),
            ListTile(
              leading: const Icon(Icons.document_scanner_outlined),
              title: Text(l10n.scanReceipt),
              onTap: () => onSecondarySelected(AppRoutes.ocrName),
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: Text(l10n.aiCoach),
              onTap: () => onSecondarySelected(AppRoutes.aiCoachName),
            ),
            const Divider(),
            _SectionLabel(text: l10n.preferences),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text(l10n.settings),
              onTap: () => onSecondarySelected(AppRoutes.settingsName),
            ),
            ListenableBuilder(
              listenable: themeController,
              builder: (context, _) {
                final isDark = themeController.isDark;
                return SwitchListTile(
                  secondary: Icon(
                    isDark
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                  ),
                  title: Text(isDark ? l10n.switchToLight : l10n.switchToDark),
                  value: isDark,
                  onChanged: (_) => themeController.toggle(),
                );
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SyncStatusChip(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
